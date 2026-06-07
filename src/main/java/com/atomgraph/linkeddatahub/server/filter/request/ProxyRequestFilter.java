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
import java.io.InputStream;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import org.apache.jena.query.QueryExecution;
import org.apache.jena.query.QueryFactory;
import jakarta.annotation.Priority;
import jakarta.inject.Inject;
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
import org.apache.jena.query.ResultSet;
import org.apache.jena.query.ResultSetRewindable;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFLanguages;
import org.apache.jena.riot.RiotException;
import org.apache.jena.riot.resultset.ResultSetReaderRegistry;
import org.glassfish.jersey.message.internal.MessageBodyProviderNotFoundException;
import java.util.regex.Pattern;
import jakarta.ws.rs.NotAcceptableException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.atomgraph.core.io.ModelProvider;
import com.atomgraph.core.util.ResultSetUtils;

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
 * This filter does <em>not</em> proxy requests from clients that explicitly accept (X)HTML.
 * Rendering arbitrary external URIs as (X)HTML through the full server-side pipeline
 * (SPARQL DESCRIBE + XSLT) is expensive and creates a resource-exhaustion attack vector.
 * When the {@code Accept} header contains a non-wildcard {@code text/html} or
 * {@code application/xhtml+xml} type, the filter returns immediately so the downstream handler
 * serves the LDH application shell; the client-side Saxon-JS layer then issues a second, RDF-typed
 * request that hits this filter and is proxied cheaply. Pure API clients that send only
 * {@code *}{@code /*} (e.g. curl) reach the proxy because they do not list an explicit HTML type.
 * <p>
 * External HTTP responses are dispatched on upstream {@code Content-Type} via Jena's live
 * RIOT registry (the same predicate {@code ModelProvider.isReadable} consults): RDF langs route
 * to {@link Model} (including HTML with embedded JSON-LD via {@code HtmlJsonLDReader} and
 * RDF/POST), SPARQL results langs route to {@link ResultSet}, and both branches are re-served
 * through the same content-negotiating builders used by local responses so the client gets the
 * format it asked for via {@code Accept}. Bodies in non-RDF types (binary, octet-stream, etc.)
 * are piped through as raw {@link InputStream}.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@PreMatching
@Priority(Priorities.USER + 50) // after auth filters (Priorities.USER = 4000), before AuthorizationFilter (Priorities.USER + 100)
public class ProxyRequestFilter implements ContainerRequestFilter
{

    private static final Logger log = LoggerFactory.getLogger(ProxyRequestFilter.class);
    private static final Pattern LINK_SPLITTER = Pattern.compile(",(?=\\s*<)");
    /**
     * End-to-end response headers forwarded verbatim from the upstream. Excludes hop-by-hop headers
     * (RFC 7230 §6.1), framing headers re-emitted by the container, origin-bound security headers
     * (CSP, HSTS, CORS), cookies, and {@code Content-Type}/{@code Link} which are set explicitly.
     */
    private static final Set<String> FORWARDED_RESPONSE_HEADERS = Set.of(
        HttpHeaders.ETAG,
        HttpHeaders.LAST_MODIFIED,
        HttpHeaders.CACHE_CONTROL,
        HttpHeaders.VARY,
        HttpHeaders.EXPIRES,
        HttpHeaders.CONTENT_LANGUAGE,
        HttpHeaders.CONTENT_DISPOSITION,
        HttpHeaders.CONTENT_LOCATION,
        HttpHeaders.LOCATION,
        HttpHeaders.RETRY_AFTER,
        "Age");

    @Inject com.atomgraph.linkeddatahub.Application system;
    @Inject jakarta.inject.Provider<Optional<Ontology>> ontology;
    @Inject MediaTypes mediaTypes;
    @Context Request request;

    @Override
    public void filter(ContainerRequestContext requestContext) throws IOException
    {
        Optional<URI> targetOpt = resolveTargetURI(requestContext);
        if (targetOpt.isEmpty()) return; // not a proxy request

        URI targetURI = targetOpt.get();

        // do not proxy requests from clients whose top-ranked acceptable type is (X)HTML — they
        // expect the app shell, which the downstream handler serves. Browsers list text/html (or
        // application/xhtml+xml) at q=1.0; API clients that happen to also accept (X)HTML at a
        // lower q (e.g. SaxonJS document() sends application/xml q=1.0, application/xhtml+xml q=0.8)
        // must still reach the proxy.
        // (X)HTML is not offered for proxied documents — rendering external RDF as HTML server-side
        // (SPARQL DESCRIBE + XSLT) is expensive and creates a resource-exhaustion attack vector.
        // Per the JAX-RS spec, getAcceptableMediaTypes() is sorted by q descending, so the first
        // non-wildcard type is the top-ranked one.
        for (MediaType mt : requestContext.getAcceptableMediaTypes())
        {
            if (mt.isWildcardType() || mt.isWildcardSubtype()) continue;
            if (mt.isCompatible(MediaType.TEXT_HTML_TYPE) || mt.isCompatible(MediaType.APPLICATION_XHTML_XML_TYPE)) return;
            break; // first non-wildcard wasn't (X)HTML — proceed with proxy
        }

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

        boolean isSafeMethod = "GET".equalsIgnoreCase(requestContext.getMethod())
            || "HEAD".equalsIgnoreCase(requestContext.getMethod());

        // serve mapped URIs (e.g. system ontologies) directly from the DataManager cache
        if (isSafeMethod && getSystem().getDataManager().isMapped(targetURI.toString()))
        {
            if (log.isDebugEnabled()) log.debug("Serving mapped URI from DataManager cache: {}", targetURI);
            Model model = getSystem().getDataManager().loadModel(targetURI.toString());
            requestContext.abortWith(getResponse(model, Response.Status.OK));
            return;
        }

        // serve terms from the app's in-memory namespace ontology (full imports closure) via DESCRIBE.
        // covers both slash-based term URIs (e.g. schema:category) and hash-based namespaces
        // (e.g. sioc:UserAccount → ac:document-uri strips to sioc:ns, so we also describe all
        // ?term where STR(?term) starts with "<targetURI>#")
        if (isSafeMethod && getOntology().isPresent())
        {
            String describeQueryStr = "DESCRIBE <" + targetURI + "> ?term " +
                "WHERE { ?term ?p ?o FILTER(STRSTARTS(STR(?term), CONCAT(STR(<" + targetURI + ">), \"#\"))) }";
            try (QueryExecution qe = QueryExecution.create(QueryFactory.create(describeQueryStr), getOntology().get().getOntModel()))
            {
                Model description = qe.execDescribe();
                if (!description.isEmpty())
                {
                    if (log.isDebugEnabled()) log.debug("Serving URI from namespace ontology: {}", targetURI);
                    requestContext.abortWith(getResponse(description, Response.Status.OK));
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

        MediaType[] clientAcceptTypes = requestContext.getAcceptableMediaTypes().toArray(MediaType[]::new);
        if (log.isDebugEnabled()) log.debug("Proxying {} {} → {}", requestContext.getMethod(), requestContext.getUriInfo().getRequestUri(), targetURI);

        try
        {
            Invocation.Builder builder = target.request().
                accept(clientAcceptTypes).
                header(HttpHeaders.USER_AGENT, GraphStoreClient.USER_AGENT);

            Response clientResponse = requestContext.hasEntity()
                ? builder.method(requestContext.getMethod(),
                    Entity.entity(requestContext.getEntityStream(), requestContext.getMediaType()))
                : builder.method(requestContext.getMethod());

            try (clientResponse)
            {
                requestContext.abortWith(getResponse(clientResponse, targetURI));
            }
        }
        catch (MessageBodyProviderNotFoundException ex)
        {
            if (log.isWarnEnabled()) log.warn("Proxied URI {} returned non-RDF media type", targetURI);
            throw new NotAcceptableException(ex);
        }
        catch (RiotException ex)
        {
            if (log.isWarnEnabled()) log.warn("Proxied URI {} returned body typed as RDF but unparseable", targetURI);
            throw new BadGatewayException(ex);
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
     * Converts the proxy target's HTTP response into a JAX-RS response for the original caller.
     * Dispatches on upstream {@code Content-Type} via Jena's live RIOT registry:
     * <ul>
     *   <li>{@link RDFLanguages#contentTypeToLang} + {@link ResultSetReaderRegistry#isRegistered}
     *       → parse as {@code ResultSetRewindable}, re-serialize through
     *       {@link #getResponse(ResultSetRewindable, Response.StatusType)};</li>
     *   <li>{@link RDFLanguages#contentTypeToLang} only → parse as {@code Model}, re-serialize
     *       through {@link #getResponse(Model, Response.StatusType)} so the client gets the
     *       format it asked for via {@code Accept};</li>
     *   <li>anything else → pipe raw bytes with upstream {@code Content-Type} verbatim.</li>
     * </ul>
     * Why the live RIOT registry and not {@code MediaTypes.getReadable(...)}: the latter is a
     * static-initializer snapshot built the first time {@code client.MediaTypes} loads, which
     * happens during {@code Application}'s constructor argument evaluation — before the
     * constructor body registers the late langs (HTML, RDFPOST). Those langs are present in the
     * live RIOT registry by request time (which is why {@code ModelProvider.isReadable} also
     * queries it directly), but they are permanently absent from the {@code MediaTypes} snapshot.
     * <p>
     * Selecting the entity class up-front from the upstream {@code Content-Type} guarantees the
     * later {@code selectVariant} call inside the typed builders runs over a single-class writable
     * list (Model-only or ResultSet-only), so the cross-class mismatch fixed by commit
     * {@code 56f7730cf} (pre-selecting a variant from a combined {@code Model+ResultSet} list
     * before knowing the entity type, then writing a {@code Model} body to a sparql-results
     * variant → 500) is structurally unreachable: by the time {@code selectVariant} runs, the
     * entity class is known.
     * <p>
     * {@code Link} headers and end-to-end cache/content headers from upstream are overlaid on top
     * of all three branches; {@code ETag}/{@code Last-Modified} are skipped on the typed branches
     * because the Model/ResultSet builders stamp their own validators that describe the
     * re-serialized representation, not the upstream bytes.
     *
     * @param clientResponse response from the proxy target
     * @param targetURI upstream URI (used as the parse base URI hint for {@code ModelProvider})
     * @return JAX-RS response to return to the original caller
     */
    protected Response getResponse(Response clientResponse, URI targetURI)
    {
        if (clientResponse.getMediaType() == null)
        {
            Response.ResponseBuilder rb = Response.status(clientResponse.getStatus());
            for (String name : FORWARDED_RESPONSE_HEADERS)
            {
                String value = clientResponse.getHeaderString(name);
                if (value != null) rb.header(name, value);
            }
            return rb.build();
        }

        // dispatch on the live Jena RIOT registry — same predicate ModelProvider.isReadable uses,
        // so any RDF lang Jersey can read into a Model (including HTML via HtmlJsonLDReader and
        // RDFPOST) routes to the Model branch. We can't use MediaTypes.getReadable(Model.class)
        // here: that list is captured by a static initializer in client.MediaTypes the first time
        // its class is loaded — earlier than Application's constructor body registers the late
        // langs (HTML, RDFPOST), so they're permanently absent from the static snapshot.
        MediaType upstreamCT = clientResponse.getMediaType();
        MediaType formatType = new MediaType(upstreamCT.getType(), upstreamCT.getSubtype()); // strip charset
        Lang lang = RDFLanguages.contentTypeToLang(formatType.toString());

        if (lang != null && ResultSetReaderRegistry.isRegistered(lang))
        {
            ResultSetRewindable results = clientResponse.readEntity(ResultSetRewindable.class);
            return overlayHeaders(getResponse(results, clientResponse.getStatusInfo()), clientResponse, false);
        }

        if (lang != null)
        {
            // base URI hint so ModelProvider (and HtmlJsonLDReader through it) resolve relative IRIs against the upstream URI
            clientResponse.getHeaders().putSingle(ModelProvider.REQUEST_URI_HEADER, targetURI.toString());
            Model model = clientResponse.readEntity(Model.class);
            return overlayHeaders(getResponse(model, clientResponse.getStatusInfo()), clientResponse, false);
        }

        // upstream is neither RDF nor SPARQL results — pipe raw bytes
        // buffer so the stream remains readable after try-with-resources closes the client response
        clientResponse.bufferEntity();
        InputStream entity = clientResponse.readEntity(InputStream.class);

        Response.ResponseBuilder rb = Response.status(clientResponse.getStatus()).
            type(upstreamCT).
            entity(entity);

        return overlayHeaders(rb.build(), clientResponse, true);
    }

    /**
     * Copies the upstream {@code Link} and end-to-end cache/content headers onto the given
     * built response. {@code ETag}/{@code Last-Modified} are skipped when {@code copyValidators}
     * is {@code false} (typed branches), because the Model/ResultSet builders stamp their own
     * validators that describe the re-serialized representation rather than the upstream bytes.
     *
     * @param response the response built by the typed or raw branch
     * @param clientResponse upstream response to copy headers from
     * @param copyValidators whether to forward {@code ETag} and {@code Last-Modified}
     * @return response with overlaid upstream headers
     */
    private Response overlayHeaders(Response response, Response clientResponse, boolean copyValidators)
    {
        Response.ResponseBuilder rb = Response.fromResponse(response);

        // forward all Link headers from the external response so the client receives remote hypermedia
        // (e.g. sd:endpoint pointing to the remote SPARQL endpoint);
        // ResponseHeadersFilter will see sd:endpoint already present and skip injecting the local one
        String linkHeader = clientResponse.getHeaderString(HttpHeaders.LINK);
        if (linkHeader != null)
            for (String part : LINK_SPLITTER.split(linkHeader))
                rb.header(HttpHeaders.LINK, part.trim());

        for (String name : FORWARDED_RESPONSE_HEADERS)
        {
            if (!copyValidators && (HttpHeaders.ETAG.equalsIgnoreCase(name) || HttpHeaders.LAST_MODIFIED.equalsIgnoreCase(name))) continue;
            String value = clientResponse.getHeaderString(name);
            if (value != null) rb.header(name, value);
        }

        return rb.build();
    }

    /**
     * Builds a response for the given RDF model with type-appropriate content negotiation.
     * Used for locally-served responses (DataManager cache, namespace ontology DESCRIBE) and for
     * the proxy's Model branch.
     *
     * @param model RDF model
     * @param statusType response status
     * @return JAX-RS response
     */
    protected Response getResponse(Model model, Response.StatusType statusType)
    {
        List<MediaType> writableTypes = new ArrayList<>(getMediaTypes().getWritable(Model.class));
        writableTypes.removeIf(mt -> mt.isCompatible(MediaType.TEXT_HTML_TYPE) ||
            mt.isCompatible(MediaType.APPLICATION_XHTML_XML_TYPE));

        return new com.atomgraph.core.model.impl.Response(getRequest(),
                model,
                null,
                new EntityTag(Long.toHexString(ModelUtils.hashModel(model))),
                writableTypes,
                getSystem().getSupportedLanguages(),
                new ArrayList<>(),
                new HTMLMediaTypePredicate()).
            getResponseBuilder().
            status(statusType).
            build();
    }

    /**
     * Builds a response for the given SPARQL result set with type-appropriate content negotiation.
     * Used by the proxy's ResultSet branch when an upstream returns SPARQL results.
     *
     * @param resultSet SPARQL result set (rewindable so we can hash without consuming)
     * @param statusType response status
     * @return JAX-RS response
     */
    protected Response getResponse(ResultSetRewindable resultSet, Response.StatusType statusType)
    {
        long hash = ResultSetUtils.hashResultSet(resultSet);
        resultSet.reset();

        return new com.atomgraph.core.model.impl.Response(getRequest(),
                resultSet,
                null,
                new EntityTag(Long.toHexString(hash)),
                getMediaTypes().getWritable(ResultSet.class),
                getSystem().getSupportedLanguages(),
                new ArrayList<>(),
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
     * Returns the media types registry used for content negotiation and outbound {@code Accept} headers.
     *
     * @return media types
     */
    public MediaTypes getMediaTypes()
    {
        return mediaTypes;
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
