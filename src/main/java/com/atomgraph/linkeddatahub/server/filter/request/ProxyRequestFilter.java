/**
 *  Copyright 2025 Martynas Jusevičius <martynas@atomgraph.com>
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */
package com.atomgraph.linkeddatahub.server.filter.request;

import com.atomgraph.client.MediaTypes;
import com.atomgraph.client.util.HTMLMediaTypePredicate;
import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.core.exception.BadGatewayException;
import com.atomgraph.core.util.ModelUtils;
import com.atomgraph.core.util.ResultSetUtils;
import com.atomgraph.linkeddatahub.apps.model.Dataset;
import com.atomgraph.linkeddatahub.client.GraphStoreClient;
import com.atomgraph.linkeddatahub.client.filter.auth.IDTokenDelegationFilter;
import com.atomgraph.linkeddatahub.client.filter.auth.WebIDDelegationFilter;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.atomgraph.linkeddatahub.server.security.IDTokenSecurityContext;
import com.atomgraph.linkeddatahub.server.security.WebIDSecurityContext;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import jakarta.annotation.Priority;
import jakarta.inject.Inject;
import jakarta.ws.rs.HttpMethod;
import jakarta.ws.rs.NotAcceptableException;
import jakarta.ws.rs.NotAllowedException;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.ProcessingException;
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.client.WebTarget;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.container.PreMatching;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.EntityTag;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.Variant;
import org.apache.jena.query.ResultSet;
import org.apache.jena.query.ResultSetRewindable;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFLanguages;
import org.apache.jena.riot.resultset.ResultSetReaderRegistry;
import org.glassfish.jersey.message.internal.MessageBodyProviderNotFoundException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS request filter that intercepts proxy requests and short-circuits the pipeline
 * via {@link ContainerRequestContext#abortWith(Response)} before {@link AuthorizationFilter} runs.
 * <p>
 * Two proxy modes are supported, resolved in order by {@link #resolveTargetURI}:
 * <ol>
 *   <li>Explicit {@code ?uri=} query parameter pointing to an external URI (not relative to the
 *       current application base). Requests relative to the app base are ignored here because
 *       {@link ApplicationFilter} already rewrote the request URI for those.</li>
 *   <li>{@code lapp:Dataset} proxy: the request URI matched a URL-path pattern defined in the
 *       system dataset configuration, and the dataset provides a proxied target URI.</li>
 * </ol>
 * ACL is not checked for proxy requests: the proxy is a global transport function, not a document
 * operation. Access control is enforced by the target endpoint.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@PreMatching
@Priority(Priorities.USER + 50) // after auth filters (Priorities.USER = 4000), before AuthorizationFilter (Priorities.USER + 100)
public class ProxyRequestFilter implements ContainerRequestFilter
{

    private static final Logger log = LoggerFactory.getLogger(ProxyRequestFilter.class);

    @Inject com.atomgraph.linkeddatahub.Application system;
    @Inject MediaTypes mediaTypes;
    @Context Request request;

    @Override
    public void filter(ContainerRequestContext requestContext) throws IOException
    {
        Optional<URI> targetOpt = resolveTargetURI(requestContext);
        if (targetOpt.isEmpty()) return; // not a proxy request

        URI targetURI = targetOpt.get();

        // strip #fragment (servers do not receive fragment identifiers)
        if (targetURI.getFragment() != null)
        {
            try
            {
                targetURI = new URI(targetURI.getScheme(), targetURI.getAuthority(), targetURI.getPath(), targetURI.getQuery(), null);
            }
            catch (URISyntaxException ex)
            {
                // should not happen when only removing the fragment
            }
        }

        // serve mapped URIs (e.g. system ontologies) directly from the DataManager cache
        if (getSystem().getDataManager().isMapped(targetURI.toString()))
        {
            if (log.isDebugEnabled()) log.debug("Serving mapped URI from DataManager cache: {}", targetURI);
            Model model = getSystem().getDataManager().loadModel(targetURI.toString());
            requestContext.abortWith(getResponse(model, Response.Status.OK));
            return;
        }

        if (!getSystem().isEnableLinkedDataProxy()) throw new NotAllowedException("Linked Data proxy not enabled");
        // LNK-009: validate that the target URI is not an internal/private address (SSRF protection)
        getSystem().getURLValidator().validate(targetURI);

        WebTarget target = getSystem().getExternalClient().target(targetURI);

        // forward agent identity to the target endpoint
        AgentContext agentContext = (AgentContext) requestContext.getProperty(AgentContext.class.getCanonicalName());
        if (agentContext != null)
        {
            if (agentContext instanceof WebIDSecurityContext)
                target.register(new WebIDDelegationFilter(agentContext.getAgent()));
            else if (agentContext instanceof IDTokenSecurityContext idTokenSecurityContext)
                target.register(new IDTokenDelegationFilter(agentContext.getAgent(),
                    idTokenSecurityContext.getJWTToken(), requestContext.getUriInfo().getBaseUri().getPath(), null));
        }

        List<MediaType> readableMediaTypesList = new ArrayList<>();
        readableMediaTypesList.addAll(mediaTypes.getReadable(Model.class));
        readableMediaTypesList.addAll(mediaTypes.getReadable(ResultSet.class));
        MediaType[] readableMediaTypesArray = readableMediaTypesList.toArray(MediaType[]::new);

        if (log.isDebugEnabled()) log.debug("Proxying {} {} → {}", requestContext.getMethod(), requestContext.getUriInfo().getRequestUri(), targetURI);

        try
        {
            Response clientResponse = switch (requestContext.getMethod())
            {
                case HttpMethod.GET ->
                    target.request(readableMediaTypesArray)
                        .header(HttpHeaders.USER_AGENT, GraphStoreClient.USER_AGENT)
                        .get();
                case HttpMethod.POST ->
                    target.request()
                        .accept(readableMediaTypesArray)
                        .header(HttpHeaders.USER_AGENT, GraphStoreClient.USER_AGENT)
                        .post(Entity.entity(requestContext.getEntityStream(), requestContext.getMediaType()));
                case "PATCH" ->
                    target.request()
                        .accept(readableMediaTypesArray)
                        .header(HttpHeaders.USER_AGENT, GraphStoreClient.USER_AGENT)
                        .method("PATCH", Entity.entity(requestContext.getEntityStream(), requestContext.getMediaType()));
                case HttpMethod.PUT ->
                    target.request()
                        .accept(readableMediaTypesArray)
                        .header(HttpHeaders.USER_AGENT, GraphStoreClient.USER_AGENT)
                        .put(Entity.entity(requestContext.getEntityStream(), requestContext.getMediaType()));
                case HttpMethod.DELETE ->
                    target.request()
                        .header(HttpHeaders.USER_AGENT, GraphStoreClient.USER_AGENT)
                        .delete();
                default -> throw new NotAllowedException(requestContext.getMethod());
            };

            try (clientResponse)
            {
                // provide the target URI as a base URI hint so ModelProvider / HtmlJsonLDReader can resolve relative references
                clientResponse.getHeaders().putSingle(com.atomgraph.core.io.ModelProvider.REQUEST_URI_HEADER, targetURI.toString());
                requestContext.abortWith(getResponse(clientResponse));
            }
        }
        catch (MessageBodyProviderNotFoundException ex)
        {
            if (log.isWarnEnabled()) log.warn("Proxied URI {} returned non-RDF media type", targetURI);
            throw new NotAcceptableException(ex);
        }
        catch (ProcessingException ex)
        {
            if (log.isWarnEnabled()) log.warn("Could not dereference proxied URI: {}", targetURI);
            throw new BadGatewayException(ex);
        }
    }

    /**
     * Resolves the proxy target URI for the current request.
     * Returns empty if this request should not be proxied.
     *
     * @param requestContext the current request context
     * @return optional target URI to proxy to
     */
    protected Optional<URI> resolveTargetURI(ContainerRequestContext requestContext)
    {
        // Case 1: explicit ?uri= query parameter
        String uriParam = requestContext.getUriInfo().getQueryParameters().getFirst(AC.uri.getLocalName());
        if (uriParam != null)
        {
            URI targetURI = URI.create(uriParam);
            @SuppressWarnings("unchecked")
            Optional<com.atomgraph.linkeddatahub.apps.model.Application> appOpt =
                (Optional<com.atomgraph.linkeddatahub.apps.model.Application>) requestContext.getProperty(LAPP.Application.getURI());
            // ApplicationFilter rewrites ?uri= values that are relative to the app base URI; skip those
            if (appOpt != null && appOpt.isPresent() && !appOpt.get().getBaseURI().relativize(targetURI).isAbsolute())
                return Optional.empty();
            return Optional.of(targetURI);
        }

        // Case 2: lapp:Dataset proxy
        @SuppressWarnings("unchecked")
        Optional<Dataset> datasetOpt =
            (Optional<Dataset>) requestContext.getProperty(LAPP.Dataset.getURI());
        if (datasetOpt != null && datasetOpt.isPresent())
        {
            URI proxied = datasetOpt.get().getProxied(requestContext.getUriInfo().getAbsolutePath());
            if (proxied != null) return Optional.of(proxied);
        }

        return Optional.empty();
    }

    /**
     * Converts a client response from the proxy target into a JAX-RS response.
     *
     * @param clientResponse response from the proxy target
     * @return JAX-RS response to return to the original caller
     */
    protected Response getResponse(Response clientResponse)
    {
        if (clientResponse.getMediaType() == null) return Response.status(clientResponse.getStatus()).build();
        return getResponse(clientResponse, clientResponse.getStatusInfo());
    }

    /**
     * Converts a client response from the proxy target into a JAX-RS response with the given status.
     *
     * @param clientResponse response from the proxy target
     * @param statusType status to use in the returned response
     * @return JAX-RS response
     */
    protected Response getResponse(Response clientResponse, Response.StatusType statusType)
    {
        MediaType formatType = new MediaType(clientResponse.getMediaType().getType(), clientResponse.getMediaType().getSubtype()); // discard charset param

        Lang lang = RDFLanguages.contentTypeToLang(formatType.toString());
        if (lang != null && ResultSetReaderRegistry.isRegistered(lang))
        {
            ResultSetRewindable results = clientResponse.readEntity(ResultSetRewindable.class);
            return getResponse(results, statusType);
        }

        Model model = clientResponse.readEntity(Model.class);
        return getResponse(model, statusType);
    }

    /**
     * Builds a content-negotiated response for the given RDF model.
     *
     * @param model RDF model
     * @param statusType response status
     * @return JAX-RS response
     */
    protected Response getResponse(Model model, Response.StatusType statusType)
    {
        List<Variant> variants = com.atomgraph.core.model.impl.Response.getVariants(
            mediaTypes.getWritable(Model.class),
            getSystem().getSupportedLanguages(),
            new ArrayList<>());

        return new com.atomgraph.core.model.impl.Response(request,
                model,
                null,
                new EntityTag(Long.toHexString(ModelUtils.hashModel(model))),
                variants,
                new HTMLMediaTypePredicate()).
            getResponseBuilder().
            status(statusType).
            build();
    }

    /**
     * Builds a content-negotiated response for the given SPARQL result set.
     *
     * @param resultSet SPARQL result set
     * @param statusType response status
     * @return JAX-RS response
     */
    protected Response getResponse(ResultSetRewindable resultSet, Response.StatusType statusType)
    {
        long hash = ResultSetUtils.hashResultSet(resultSet);
        resultSet.reset();

        List<Variant> variants = com.atomgraph.core.model.impl.Response.getVariants(
            mediaTypes.getWritable(ResultSet.class),
            getSystem().getSupportedLanguages(),
            new ArrayList<>());

        return new com.atomgraph.core.model.impl.Response(request,
                resultSet,
                null,
                new EntityTag(Long.toHexString(hash)),
                variants,
                new HTMLMediaTypePredicate()).
            getResponseBuilder().
            status(statusType).
            build();
    }

    /**
     * Returns the system application.
     *
     * @return system application
     */
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }

}
