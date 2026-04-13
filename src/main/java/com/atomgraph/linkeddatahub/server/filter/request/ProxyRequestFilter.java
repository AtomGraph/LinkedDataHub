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

import com.atomgraph.core.MediaTypes;
import com.atomgraph.client.util.HTMLMediaTypePredicate;
import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.core.exception.BadGatewayException;
import com.atomgraph.core.util.ModelUtils;
import com.atomgraph.core.util.ResultSetUtils;
import com.atomgraph.linkeddatahub.apps.model.Dataset;
import org.apache.jena.ontology.Ontology;
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
import org.apache.jena.query.QueryExecution;
import org.apache.jena.query.QueryFactory;
import jakarta.annotation.Priority;
import jakarta.inject.Inject;
import jakarta.ws.rs.NotAcceptableException;
import jakarta.ws.rs.NotAllowedException;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.ProcessingException;
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.client.Invocation;
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
import java.util.regex.Pattern;
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
 * <p>
 * This filter intentionally does <em>not</em> proxy requests from clients that explicitly accept
 * (X)HTML. Rendering arbitrary external URIs as (X)HTML through the full server-side pipeline
 * (SPARQL DESCRIBE + XSLT) for every browser-originated proxy request would cause unbounded resource
 * exhaustion — a connection-pool and CPU amplification attack vector. Instead, requests whose
 * {@code Accept} header contains a non-wildcard {@code text/html} or {@code application/xhtml+xml}
 * type fall through to the downstream handler, which serves the LDH application shell; the
 * client-side Saxon-JS layer then issues a second, RDF-typed request that <em>does</em> hit this
 * filter and is handled cheaply. Pure API clients that send only {@code *}{@code /*} (e.g. curl)
 * reach the proxy because they do not list an explicit HTML type.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@PreMatching
@Priority(Priorities.USER + 50) // after auth filters (Priorities.USER = 4000), before AuthorizationFilter (Priorities.USER + 100)
public class ProxyRequestFilter implements ContainerRequestFilter
{

    private static final Logger log = LoggerFactory.getLogger(ProxyRequestFilter.class);
    private static final MediaTypes MEDIA_TYPES = new MediaTypes();
    private static final Pattern LINK_SPLITTER = Pattern.compile(",(?=\\s*<)");

    @Inject com.atomgraph.linkeddatahub.Application system;
    @Inject jakarta.inject.Provider<Optional<Ontology>> ontology;
    @Context Request request;

    @Override
    public void filter(ContainerRequestContext requestContext) throws IOException
    {
        Optional<URI> targetOpt = resolveTargetURI(requestContext);
        if (targetOpt.isEmpty()) return; // not a proxy request

        URI targetURI = targetOpt.get();

        // do not proxy requests from clients that explicitly accept (X)HTML — they expect the app shell,
        // which the downstream handler serves. Browsers list text/html as a non-wildcard type; pure API
        // clients (curl etc.) send only */* and must reach the proxy.
        // Defending against resource exhaustion: proxying + full server-side XSLT rendering for arbitrary
        // external URIs on every browser request would amplify CPU and connection-pool load unboundedly.
        boolean clientAcceptsHtml = requestContext.getAcceptableMediaTypes().stream()
            .anyMatch(mt -> !mt.isWildcardType() && !mt.isWildcardSubtype() &&
                      (mt.isCompatible(MediaType.TEXT_HTML_TYPE) ||
                       mt.isCompatible(MediaType.APPLICATION_XHTML_XML_TYPE)));
        if (clientAcceptsHtml) return;

        // negotiate the response format from RDF/SPARQL writable types
        List<MediaType> writableTypes = new ArrayList<>(getMediaTypes().getWritable(Model.class));
        writableTypes.addAll(getMediaTypes().getWritable(ResultSet.class));
        List<Variant> variants = com.atomgraph.core.model.impl.Response.getVariants(
            writableTypes,
            getSystem().getSupportedLanguages(),
            new ArrayList<>());
        Variant selectedVariant = getRequest().selectVariant(variants);
        if (selectedVariant == null) return; // client accepts no RDF/SPARQL type

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
            requestContext.abortWith(getResponse(model, Response.Status.OK, selectedVariant));
            return;
        }

        // serve terms from the app's in-memory namespace ontology (full imports closure) via DESCRIBE.
        // covers both slash-based term URIs (e.g. schema:category) and hash-based namespaces
        // (e.g. sioc:UserAccount → ac:document-uri strips to sioc:ns, so we also describe all
        // ?term where STR(?term) starts with "<targetURI>#")
        if (getOntology().isPresent())
        {
            String describeQueryStr = "DESCRIBE <" + targetURI + "> ?term " +
                "WHERE { ?term ?p ?o FILTER(STRSTARTS(STR(?term), CONCAT(STR(<" + targetURI + ">), \"#\"))) }";
            try (QueryExecution qe = QueryExecution.create(QueryFactory.create(describeQueryStr), getOntology().get().getOntModel()))
            {
                Model description = qe.execDescribe();
                if (!description.isEmpty())
                {
                    if (log.isDebugEnabled()) log.debug("Serving URI from namespace ontology: {}", targetURI);
                    requestContext.abortWith(getResponse(description, Response.Status.OK, selectedVariant));
                    return;
                }
            }
        }

        boolean isRegisteredApp = getSystem().matchApp(targetURI) != null;
        if (!isRegisteredApp && !getSystem().isEnableLinkedDataProxy())
            throw new NotAllowedException("Linked Data proxy not enabled");
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
        readableMediaTypesList.addAll(getMediaTypes().getReadable(Model.class));
        readableMediaTypesList.addAll(getMediaTypes().getReadable(ResultSet.class));
        MediaType[] readableMediaTypesArray = readableMediaTypesList.toArray(MediaType[]::new);

        if (log.isDebugEnabled()) log.debug("Proxying {} {} → {}", requestContext.getMethod(), requestContext.getUriInfo().getRequestUri(), targetURI);

        try
        {
            Invocation.Builder builder = target.request().
                accept(readableMediaTypesArray).
                header(HttpHeaders.USER_AGENT, GraphStoreClient.USER_AGENT);

            Response clientResponse = requestContext.hasEntity()
                ? builder.method(requestContext.getMethod(),
                    Entity.entity(requestContext.getEntityStream(), requestContext.getMediaType()))
                : builder.method(requestContext.getMethod());

            try (clientResponse)
            {
                // provide the target URI as a base URI hint so ModelProvider / HtmlJsonLDReader can resolve relative references
                clientResponse.getHeaders().putSingle(com.atomgraph.core.io.ModelProvider.REQUEST_URI_HEADER, targetURI.toString());
                requestContext.abortWith(getResponse(clientResponse, selectedVariant));
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
        // Case 1: external ?uri= — ApplicationFilter strips it from UriInfo and stores it here
        URI proxyTarget = (URI) requestContext.getProperty(AC.uri.getURI());
        if (proxyTarget != null) return Optional.of(proxyTarget);

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
     * @param selectedVariant pre-computed variant from content negotiation
     * @return JAX-RS response to return to the original caller
     */
    protected Response getResponse(Response clientResponse, Variant selectedVariant)
    {
        if (clientResponse.getMediaType() == null) return Response.status(clientResponse.getStatus()).build();
        return getResponse(clientResponse, clientResponse.getStatusInfo(), selectedVariant);
    }

    /**
     * Converts a client response from the proxy target into a JAX-RS response with the given status.
     *
     * @param clientResponse response from the proxy target
     * @param statusType status to use in the returned response
     * @param selectedVariant pre-computed variant from content negotiation
     * @return JAX-RS response
     */
    protected Response getResponse(Response clientResponse, Response.StatusType statusType, Variant selectedVariant)
    {
        MediaType formatType = new MediaType(clientResponse.getMediaType().getType(), clientResponse.getMediaType().getSubtype()); // discard charset param

        Lang lang = RDFLanguages.contentTypeToLang(formatType.toString());
        Response response;
        if (lang != null && ResultSetReaderRegistry.isRegistered(lang))
        {
            ResultSetRewindable results = clientResponse.readEntity(ResultSetRewindable.class);
            response = getResponse(results, statusType, selectedVariant);
        }
        else
        {
            Model model = clientResponse.readEntity(Model.class);
            response = getResponse(model, statusType, selectedVariant);
        }

        // forward all Link headers from the external response so the client receives remote hypermedia
        // (e.g. sd:endpoint pointing to the remote SPARQL endpoint);
        // ResponseHeadersFilter will see sd:endpoint already present and skip injecting the local one
        String linkHeader = clientResponse.getHeaderString(HttpHeaders.LINK);
        if (linkHeader != null)
        {
            Response.ResponseBuilder builder = Response.fromResponse(response);
            for (String part : LINK_SPLITTER.split(linkHeader))
                builder.header(HttpHeaders.LINK, part.trim());
            response = builder.build();
        }

        return response;
    }

    /**
     * Builds a response for the given RDF model using a pre-computed variant.
     *
     * @param model RDF model
     * @param statusType response status
     * @param selectedVariant pre-computed variant from content negotiation
     * @return JAX-RS response
     */
    protected Response getResponse(Model model, Response.StatusType statusType, Variant selectedVariant)
    {
        return new com.atomgraph.core.model.impl.Response(getRequest(),
                model,
                null,
                new EntityTag(Long.toHexString(ModelUtils.hashModel(model))),
                selectedVariant,
                new HTMLMediaTypePredicate()).
            getResponseBuilder().
            status(statusType).
            build();
    }

    /**
     * Builds a response for the given SPARQL result set using a pre-computed variant.
     *
     * @param resultSet SPARQL result set
     * @param statusType response status
     * @param selectedVariant pre-computed variant from content negotiation
     * @return JAX-RS response
     */
    protected Response getResponse(ResultSetRewindable resultSet, Response.StatusType statusType, Variant selectedVariant)
    {
        long hash = ResultSetUtils.hashResultSet(resultSet);
        resultSet.reset();

        return new com.atomgraph.core.model.impl.Response(getRequest(),
                resultSet,
                null,
                new EntityTag(Long.toHexString(hash)),
                selectedVariant,
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

    /**
     * Returns the current application's namespace ontology, if available.
     *
     * @return optional ontology
     */
    public Optional<Ontology> getOntology()
    {
        return ontology.get();
    }

    /**
     * Returns the media types registry.
     * Core MediaTypes do not include (X)HTML types, which is what we want here.
     *
     * @return media types
     */
    public MediaTypes getMediaTypes()
    {
        return MEDIA_TYPES;
    }

    /**
     * Returns the JAX-RS request.
     *
     * @return request
     */
    public Request getRequest()
    {
        return request;
    }

}
