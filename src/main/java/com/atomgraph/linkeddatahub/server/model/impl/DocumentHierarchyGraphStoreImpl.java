/**
 *  Copyright 2019 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.server.model.impl;

import com.atomgraph.client.util.HTMLMediaTypePredicate;
import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.core.model.EndpointAccessor;
import com.atomgraph.core.riot.lang.RDFPostReader;
import com.atomgraph.linkeddatahub.dataspaces.model.EndUserDataspace;
import com.atomgraph.linkeddatahub.client.GitHubClient;
import com.atomgraph.linkeddatahub.client.GraphStoreClient;
import com.atomgraph.linkeddatahub.client.filter.UnlimitedContentLengthFilter;
import com.atomgraph.linkeddatahub.model.CSVImport;
import com.atomgraph.linkeddatahub.model.RDFImport;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.io.ValidatingModelProvider;
import com.atomgraph.linkeddatahub.server.model.Patchable;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.atomgraph.linkeddatahub.server.util.PatchUpdateVisitor;
import com.atomgraph.linkeddatahub.server.util.EntityTags;
import com.atomgraph.linkeddatahub.server.util.GraphLocks;
import com.atomgraph.linkeddatahub.server.util.Skolemizer;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.linkeddatahub.vocabulary.DH;
import com.atomgraph.linkeddatahub.vocabulary.LDH;
import com.atomgraph.linkeddatahub.vocabulary.NFO;
import com.atomgraph.linkeddatahub.vocabulary.SIOC;
import com.atomgraph.linkeddatahub.writer.TimeMapWriter;
import com.atomgraph.server.exception.SHACLConstraintViolationException;
import com.atomgraph.server.exception.SPINConstraintViolationException;
import static com.atomgraph.server.status.UnprocessableEntityStatus.UNPROCESSABLE_ENTITY;
import com.atomgraph.spinrdf.constraints.ConstraintViolation;
import com.atomgraph.spinrdf.vocabulary.SPIN;
import com.atomgraph.core.vocabulary.SD;
import java.net.URI;
import java.net.URISyntaxException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import jakarta.inject.Inject;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.HttpMethod;
import jakarta.ws.rs.InternalServerErrorException;
import jakarta.ws.rs.NotAcceptableException;
import jakarta.ws.rs.NotAllowedException;
import jakarta.ws.rs.NotFoundException;
import jakarta.ws.rs.OPTIONS;
import jakarta.ws.rs.PATCH;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.CacheControl;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.EntityTag;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.Response;
import static jakarta.ws.rs.core.Response.Status.PERMANENT_REDIRECT;
import jakarta.ws.rs.core.SecurityContext;
import jakarta.ws.rs.core.UriBuilder;
import jakarta.ws.rs.core.UriInfo;
import jakarta.ws.rs.core.Variant;
import jakarta.ws.rs.ext.MessageBodyReader;
import jakarta.ws.rs.ext.Providers;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.time.DateTimeException;
import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.security.DigestInputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.locks.Lock;
import java.util.function.Supplier;
import org.apache.commons.codec.binary.Hex;
import org.apache.commons.lang3.StringUtils;
import org.apache.jena.atlas.RuntimeIOException;
import org.apache.jena.datatypes.xsd.XSDDateTime;
import org.apache.jena.ontapi.model.OntModel;
import org.apache.jena.query.Dataset;
import org.apache.jena.query.DatasetFactory;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Property;
import org.apache.jena.rdf.model.RDFNode;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.rdf.model.Statement;
import org.apache.jena.rdf.model.StmtIterator;
import org.apache.jena.shacl.validation.ReportEntry;
import org.apache.jena.sparql.vocabulary.FOAF;
import org.apache.jena.update.UpdateAction;
import org.apache.jena.update.UpdateRequest;
import org.apache.jena.util.ResourceUtils;
import org.apache.jena.util.iterator.ExtendedIterator;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;
import org.glassfish.jersey.media.multipart.BodyPart;
import org.glassfish.jersey.media.multipart.FormDataBodyPart;
import org.glassfish.jersey.media.multipart.FormDataMultiPart;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * LinkedDataHub Graph Store implementation.
 * We need to subclass the Core class because we're injecting a subclass of Service.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class DocumentHierarchyGraphStoreImpl extends com.atomgraph.core.model.impl.DirectGraphStoreImpl implements Patchable
{
    
    private static final Logger log = LoggerFactory.getLogger(DocumentHierarchyGraphStoreImpl.class);

    /**
     * The relative path of the content-addressed file container.
     */
    public static final String UPLOADS_PATH = "uploads";

    /**
     * Name of the query parameter that selects a historical graph version by commit SHA.
     */
    public static final String VERSION_PARAM_NAME = "version";

    /**
     * Name of the query parameter that retrieves the graph's version history as a Memento TimeMap.
     */
    public static final String TIMEMAP_PARAM_NAME = "timemap";

    /**
     * Name of the query parameter that addresses the graph's Memento TimeGate, which negotiates on
     * <code>Accept-Datetime</code>.
     */
    public static final String TIMEGATE_PARAM_NAME = "timegate";

    /**
     * Name of the request header conveying the datetime a TimeGate negotiates on.
     */
    public static final String ACCEPT_DATETIME_HEADER = "Accept-Datetime";

    /**
     * Name of the Graph Store Protocol query parameter that identifies a named graph indirectly.
     */
    public static final String GRAPH_PARAM_NAME = "graph";

    /**
     * Name of the Graph Store Protocol query parameter that identifies the default graph indirectly.
     */
    public static final String DEFAULT_PARAM_NAME = "default";
    
    private final com.atomgraph.linkeddatahub.dataspaces.model.Dataspace application;
    private final OntModel ontology;
    private final Service service;
    private final Providers providers;
    private final com.atomgraph.linkeddatahub.Application system;
    private final UriBuilder uploadsUriBuilder;
    /** The URIs for owner and secretary documents. */
    protected final URI ownerDocURI, secretaryDocURI;
    private final SecurityContext securityContext;
    private final Optional<AgentContext> agentContext;
    private final Set<String> allowedMethods;

    /**
     * Constructs Graph Store.
     * 
     * @param request current request
     * @param uriInfo URI info of the current request
     * @param mediaTypes a registry of readable/writable media types
     * @param application current application
     * @param ontology ontology of the current application
     * @param service SPARQL service of the current application
     * @param securityContext JAX-RS security context
     * @param agentContext authenticated agent's context
     * @param providers registry of JAX-RS providers
     * @param system system application
     * @param httpHeaders request headers
     */
    @Inject
    public DocumentHierarchyGraphStoreImpl(@Context Request request, @Context UriInfo uriInfo, MediaTypes mediaTypes,
        com.atomgraph.linkeddatahub.dataspaces.model.Dataspace application, Optional<OntModel> ontology, Optional<Service> service,
        @Context SecurityContext securityContext, Optional<AgentContext> agentContext,
        @Context Providers providers, com.atomgraph.linkeddatahub.Application system, @Context HttpHeaders httpHeaders)
    {
        // orElseThrow: the super() call dereferences the service before any statement can check emptiness
        super(request, httpHeaders, system.getServiceContext(service.orElseThrow(() -> new InternalServerErrorException("Service is not specified"))).getGraphStoreClient(), mediaTypes, uriInfo);
        if (ontology.isEmpty()) throw new InternalServerErrorException("Ontology is not specified");
        this.application = application;
        this.ontology = ontology.get();
        this.service = service.get();
        this.securityContext = securityContext;
        this.agentContext = agentContext;
        this.providers = providers;
        this.system = system;
        uploadsUriBuilder = uriInfo.getBaseUriBuilder().path(UPLOADS_PATH);
        URI ownerURI = URI.create(application.getMaker().getURI());
        try
        {
            this.ownerDocURI = new URI(ownerURI.getScheme(), ownerURI.getSchemeSpecificPart(), null).normalize();
            this.secretaryDocURI = new URI(system.getSecretaryWebIDURI().getScheme(), system.getSecretaryWebIDURI().getSchemeSpecificPart(), null).normalize();
        }
        catch (URISyntaxException ex)
        {
            throw new InternalServerErrorException(ex);
        }
        
        allowedMethods = allowedMethods(uriInfo.getAbsolutePath(), application.getBaseURI(), ownerDocURI, secretaryDocURI, isSnapshotRequest(uriInfo));
    }

    /**
     * Returns the methods allowed on a document.
     * The owner's and the secretary's WebID documents cannot be replaced or deleted, the root document cannot be
     * deleted, and historical versions, TimeMaps and TimeGates are read-only.
     *
     * @param uri document URI
     * @param baseURI application's base URI (the root document)
     * @param ownerDocURI owner's WebID document URI
     * @param secretaryDocURI secretary's WebID document URI
     * @param snapshot true if the request addresses a historical version, a TimeMap or a TimeGate
     * @return set of HTTP method names
     */
    public static Set<String> allowedMethods(URI uri, URI baseURI, URI ownerDocURI, URI secretaryDocURI, boolean snapshot)
    {
        if (snapshot) return Set.of(HttpMethod.GET, HttpMethod.HEAD, HttpMethod.OPTIONS);

        Set<String> methods = new HashSet<>(Set.of(HttpMethod.GET, HttpMethod.HEAD, HttpMethod.OPTIONS, HttpMethod.POST, HttpMethod.PATCH));

        if (!ownerDocURI.equals(uri) &&
            !secretaryDocURI.equals(uri))
            methods.add(HttpMethod.PUT);

        if (!baseURI.equals(uri) &&
            !ownerDocURI.equals(uri) &&
            !secretaryDocURI.equals(uri))
            methods.add(HttpMethod.DELETE);

        return methods;
    }

    /**
     * Returns true if the request addresses a historical version, a TimeMap or a TimeGate rather than the
     * document itself.
     *
     * @param uriInfo URI info of the request
     * @return true if this is a Memento, TimeMap or TimeGate request
     */
    public static boolean isSnapshotRequest(UriInfo uriInfo)
    {
        return uriInfo.getQueryParameters().containsKey(VERSION_PARAM_NAME) ||
            uriInfo.getQueryParameters().containsKey(TIMEMAP_PARAM_NAME) ||
            uriInfo.getQueryParameters().containsKey(TIMEGATE_PARAM_NAME);
    }

    /**
     * Rejects the request if it addresses a historical version, TimeMap or TimeGate view, which are read-only.
     */
    private void checkSnapshotReadOnly()
    {
        if (isSnapshotRequest(getUriInfo()))
            throw new NotAllowedException("Historical versions, TimeMaps and TimeGates are read-only",
                Response.status(Response.Status.METHOD_NOT_ALLOWED).allow(getAllowedMethods()).build());
    }

    /**
     * Returns true if the request uses the Graph Store Protocol's indirect graph identification, i.e. carries a
     * <code>graph</code> or <code>default</code> query parameter.
     *
     * @param uriInfo URI info of the request
     * @return true if the request identifies its graph indirectly
     */
    public static boolean isIndirectIdentification(UriInfo uriInfo)
    {
        return uriInfo.getQueryParameters().containsKey(GRAPH_PARAM_NAME) ||
            uriInfo.getQueryParameters().containsKey(DEFAULT_PARAM_NAME);
    }

    /**
     * Rejects a request that identifies its graph indirectly.
     * Documents form a directly identified graph store (GSP &sect;4.1): the request URI names the graph, so a
     * <code>graph</code> or <code>default</code> parameter would otherwise be ignored and the operation would apply
     * to this document instead of the graph the client named.
     *
     * @param uriInfo URI info of the request
     * @throws BadRequestException if the request carries a <code>graph</code> or <code>default</code> parameter
     */
    public static void checkDirectIdentification(UriInfo uriInfo)
    {
        if (isIndirectIdentification(uriInfo))
            throw new BadRequestException("Indirect graph identification (the '" + GRAPH_PARAM_NAME + "' and '" + DEFAULT_PARAM_NAME +
                "' query parameters) is not supported: the request URI identifies the graph");
    }

    /**
     * Implements <code>GET</code> method of SPARQL Graph Store Protocol.
     * With a <code>version</code> query parameter, returns the graph's state at that commit from the
     * versioning repository instead of the triplestore. Version responses are immutable.
     *
     * @return HTTP response
     */
    @Override
    @GET
    public Response get()
    {
        checkDirectIdentification(getUriInfo());

        if (getUriInfo().getQueryParameters().containsKey(TIMEGATE_PARAM_NAME))
        {
            String acceptDatetime = getHttpHeaders().getHeaderString(ACCEPT_DATETIME_HEADER);
            final Instant datetime;
            try
            {
                // parse leniently (RFC 1123 permits an unpadded day and numeric offsets), format strictly
                datetime = acceptDatetime != null ? Instant.from(DateTimeFormatter.RFC_1123_DATE_TIME.parse(acceptDatetime)) : null;
            }
            catch (DateTimeException ex)
            {
                throw new BadRequestException("Value '" + acceptDatetime + "' of the '" + ACCEPT_DATETIME_HEADER + "' header is not an RFC 1123 datetime");
            }

            GitHubClient.CommitInfo commit = getSystem().getGraphVersioningService().
                getMemento(getDataspace().getURI(), getDataspace().getBaseURI(), getURI(), datetime).
                orElseThrow(() -> new NotFoundException("Document <" + getURI() + "> has no version history"));

            // negotiation has to see the current history, and Accept-Datetime takes unbounded values, so the
            // redirect is not stored: a cached one would outlive the commit that made it the most recent
            CacheControl noStore = new CacheControl();
            noStore.setNoStore(true);

            // a 302 TimeGate response carries no Memento-Datetime; the Memento it points at does
            return Response.status(Response.Status.FOUND).
                location(getUriInfo().getAbsolutePathBuilder().queryParam(VERSION_PARAM_NAME, commit.sha()).build()).
                header(HttpHeaders.VARY, ACCEPT_DATETIME_HEADER.toLowerCase(Locale.ROOT)).
                cacheControl(noStore).
                build();
        }

        if (getUriInfo().getQueryParameters().containsKey(TIMEMAP_PARAM_NAME))
        {
            Model timeMap = getSystem().getGraphVersioningService().
                getTimeMap(getDataspace().getURI(), getDataspace().getBaseURI(), getURI()).
                orElseThrow(() -> new NotFoundException("Document <" + getURI() + "> has no version history"));

            // link-format is only offered on the TimeMap, where it is meaningful; it leads the list so that
            // Accept: */* clients get the RFC 7089 serialization, while browsers still resolve to HTML on q-value
            List<jakarta.ws.rs.core.MediaType> timeMapMediaTypes = new ArrayList<>();
            timeMapMediaTypes.add(TimeMapWriter.APPLICATION_LINK_FORMAT_TYPE);
            timeMapMediaTypes.addAll(getWritableMediaTypes(Model.class));

            return new com.atomgraph.core.model.impl.Response(getRequest(), getHttpHeaders(),
                    timeMap,
                    null,
                    getEntityTag(timeMap),
                    timeMapMediaTypes,
                    getLanguages(),
                    getEncodings(),
                    new HTMLMediaTypePredicate()).
                getResponseBuilder().build();
        }

        String version = getUriInfo().getQueryParameters().getFirst(VERSION_PARAM_NAME);
        if (version == null) return super.get();
        // commit SHAs only: movable refs (branches, tags) must not be served with immutable caching,
        // and the hex-only value seeds the ETag (the variant folding and the HTML writer add to it as a hex number)
        if (!version.matches("[0-9a-f]{4,64}")) throw new NotFoundException("Version '" + version + "' of graph <" + getURI() + "> not found");

        com.atomgraph.linkeddatahub.server.util.GraphVersioningService.Version graphVersion = getSystem().getGraphVersioningService().
            getVersion(getDataspace().getURI(), getDataspace().getBaseURI(), getURI(), version).
            orElseThrow(() -> new NotFoundException("Version '" + version + "' of graph <" + getURI() + "> not found"));

        // the tag is derived per variant from the commit SHA, and the same tag is evaluated and sent: tagging every
        // variant with the bare SHA after evaluating against the content digest meant If-None-Match never matched
        Response.ResponseBuilder rb = getInternalResponse(graphVersion.model(), getLastModified(graphVersion.model(), getURI()), new EntityTag(version)).
            getResponseBuilder().
            cacheControl(graphVersion.getCacheControl());
        if (graphVersion.datetime() != null)
            rb.header("Memento-Datetime", TimeMapWriter.RFC_1123_GMT.format(graphVersion.datetime().atZone(ZoneId.of("GMT"))));

        return rb.build();
    }

    /**
     * Implements <code>POST</code> method of SPARQL Graph Store Protocol.
     * Adds triples to the existing graph, skolemizes blank nodes, updates modification timestamp, and submits any imports.
     *
     * @param model RDF model to add to the graph
     * @return HTTP response with updated entity tag
     */
    @Override
    @POST
    public Response post(Model model)
    {
        checkDirectIdentification(getUriInfo());
        return post(model, () -> {});
    }

    /**
     * Appends triples to the existing graph, running a step right before the graph is written: once the
     * preconditions have been met and the resulting document has been validated, inside the document's lock.
     *
     * @param model RDF model to add to the graph
     * @param beforeWrite step to run before the graph is written, such as moving uploaded files into place
     * @return HTTP response with updated entity tag
     */
    protected Response post(Model model, Runnable beforeWrite)
    {
        checkSnapshotReadOnly();

        if (log.isTraceEnabled()) log.trace("POST Graph Store request with RDF payload: {} payload size(): {}", model, model.size());

        // appending nothing is a no-op (GSP 5.5): there is no state to quote, so it needs no If-Match, and nothing is
        // written - stamping dct:modified would change the graph and its entity tag although no triple was added
        if (model.isEmpty()) return Response.noContent().build();

        return writeLocked(() ->
        {
            final Model existingModel = getSystem().getServiceContext(getService()).getGraphStoreClient().getModel(getURI().toString());
        
            Response.ResponseBuilder rb = evaluatePreconditions(existingModel, getHttpHeaders());
            if (rb != null) return rb.build(); // preconditions not met
        
            // dct:created and dct:modified are the server's to assign: the document keeps the creation date it has, and
            // the append is its modification. Ownership is not the payload's to assert either: the stored acl:owner and
            // dct:creator are kept as they are
            removeOwnership(model, getURI().toString()).
                removeAll(DCTerms.created).
                removeAll(DCTerms.modified).
                addLiteral(DCTerms.modified, ResourceFactory.createTypedLiteral(GregorianCalendar.getInstance()));
        
            // container/item (graph) resource is already skolemized, skolemize the rest of the model
            new Skolemizer(getURI().toString()).apply(model);
        
            // is this implemented correctly? The specification is not very clear.
            if (log.isDebugEnabled()) log.debug("POST Model to named graph with URI: {}", getURI());
            // the imports the append adds or redefines, judged by the document as it will be against the document as it
            // is - read before the merge below changes it in place
            List<Resource> imports = getChangedImports(ModelFactory.createUnion(existingModel, model), existingModel);

            // First remove old dct:modified values from the triplestore, then add new data
            existingModel.createResource(getURI().toString()).removeAll(DCTerms.modified);
            Model updatedModel = existingModel.add(model);

            // the payload was validated on its own when it was read, where a constraint that spans the document -
            // a block the payload appends to a document it does not type - had nothing to apply to; what is written
            // is the whole document, so that is what is held to the constraints
            validateConstraints(updatedModel);

            beforeWrite.run();
            getSystem().getServiceContext(getService()).getGraphStoreClient().putModel(getURI().toString(), updatedModel); // replace entire graph to avoid accumulating dct:modified

            submitImports(imports.stream().map(_import -> _import.inModel(updatedModel)).toList());
        
            Response.ResponseBuilder noContent = Response.noContent();
            // entity tag of the updated graph, for the variant the request negotiates - none when it accepts no RDF syntax
            getWriteResponse(updatedModel, null).ifPresent(response -> noContent.tag(response.getVariantEntityTag()));
            return noContent.build();
        });
    }
    
    /**
     * Implements <code>PUT</code> method of SPARQL Graph Store Protocol.
     * Creates a new graph or updates an existing one. Enforces trailing slash in URIs, skolemizes blank nodes,
     * establishes parent/container relationships, and manages metadata (created, modified, creator, owner timestamps).
     *
     * @param model RDF model to create or update
     * @return HTTP response with 201 Created for new graphs or 204 No Content for updates, neither with a validator
     */
    @Override
    @PUT
    // the AuthorizationFilter only allows creating new child URIs for existing containers (i.e. there has to be a .. container already)
    public Response put(Model model)
    {
        checkDirectIdentification(getUriInfo());
        return put(model, () -> {});
    }

    /**
     * Creates or replaces the graph, running a step right before the graph is written: once the preconditions
     * have been met and the document has been validated, inside the document's lock.
     *
     * @param model RDF model to create or update
     * @param beforeWrite step to run before the graph is written, such as moving uploaded files into place
     * @return HTTP response with 201 Created for new graphs or 204 No Content for updates, neither with a validator
     */
    protected Response put(Model model, Runnable beforeWrite)
    {
        checkSnapshotReadOnly();

        if (log.isTraceEnabled()) log.trace("PUT Graph Store request with RDF payload: {} payload size(): {}", model, model.size());

        if (!getAllowedMethods().contains(HttpMethod.PUT))
        {
            if (log.isErrorEnabled()) log.error("Method '{}' is not allowed on document URI <{}>", HttpMethod.PUT, getURI());
            throw new WebApplicationException("Method '" + HttpMethod.PUT + "' is not allowed on document URI <" + getURI() + ">", Response.status(Response.Status.METHOD_NOT_ALLOWED).allow(getAllowedMethods()).build());
        }
        
        // enforce that request URI always end with a slash - by redirecting to it if doesn't not already
        if (!getURI().toString().endsWith("/"))
        {
            String uriWithSlash = getURI().toString() + "/";

            if (log.isDebugEnabled()) log.debug("Redirecting document URI <{}> to <{}> in order to enforce trailing a slash", getURI(), uriWithSlash);

            return Response.status(PERMANENT_REDIRECT).
                location(URI.create(uriWithSlash)).
                build();
        }
        if (getURI().getPath().contains("//"))
        {
            if (log.isDebugEnabled()) log.debug("Rejected document URI <{}> - double slashes are not allowed", getURI());
            throw new BadRequestException("Double slashes not allowed in document URIs");
        }
        
        return writeLocked(() ->
        {
            new Skolemizer(getURI().toString()).apply(model);
            Model existingModel = null;
            try
            {
                existingModel = getSystem().getServiceContext(getService()).getGraphStoreClient().getModel(getURI().toString());
            
                Response.ResponseBuilder rb = evaluatePreconditions(existingModel, getHttpHeaders());
                if (rb != null) return rb.build(); // preconditions not met
            }
            catch (NotFoundException ex)
            {
                // If-Match is false when there is no current representation (RFC 9110 13.1.1): a write quoting the
                // state of a document deleted in the meantime must not recreate it
                String ifMatch = getHttpHeaders().getHeaderString(HttpHeaders.IF_MATCH);
                if (ifMatch != null && !ifMatch.isBlank()) return Response.status(Response.Status.PRECONDITION_FAILED).build();
            }

            Resource parent = model.createResource(getURI().resolve("..").toString());
            // ownership is not the payload's to assert: a new document gets the agent's below, an existing one keeps the stored values
            Resource resource = removeOwnership(model, getURI().toString()).
                removeAll(SIOC.HAS_PARENT).
                removeAll(SIOC.HAS_CONTAINER);

            boolean typed = false; // whether the document's class is assigned here rather than by the payload
            if (!getDataspace().getBaseURI().equals(getURI())) // don't update Root document's metadata
            {
                if (resource.hasProperty(RDF.type, DH.Container))
                    resource.addProperty(SIOC.HAS_PARENT, parent);
                else
                {
                    typed = !resource.hasProperty(RDF.type, DH.Item);
                    resource.addProperty(SIOC.HAS_CONTAINER, parent).
                        addProperty(RDF.type, DH.Item); // TO-DO: replace with foaf:Document?
                }
            }

            // the payload was validated when it was read, while the document was still untyped and so held to no
            // class's constraints; a document typed here is held to dh:Item's now, before it is written
            if (typed) validateConstraints(model);

            if (existingModel == null) // creating new graph and attaching it to the document hierarchy
            {
                // a new document was created now and has not been modified since: neither date is the client's
                resource.removeAll(DCTerms.created).
                    removeAll(DCTerms.modified).
                    addLiteral(DCTerms.created, ResourceFactory.createTypedLiteral(GregorianCalendar.getInstance()));
            
                if (getAgentContext().isPresent()) resource.addProperty(DCTerms.creator, getAgentContext().get().getAgent()).
                        addProperty(ACL.owner, getAgentContext().get().getAgent());

                if (log.isDebugEnabled()) log.debug("PUT Model into new named graph with URI: {}", getURI());
                beforeWrite.run();
                getSystem().getServiceContext(getService()).getGraphStoreClient().putModel(getURI().toString(), model); // TO-DO: catch exceptions

                submitImports(getChangedImports(model, null));

                return Response.created(getURI()).
                    build();
            }
            else // updating existing graph
            {        
                // the creation date is the stored one, not the client's: a client-supplied dct:created would be kept
                // alongside it and, being the later of the two, could move Last-Modified anywhere it likes
                resource.removeAll(DCTerms.created);

                // retain metadata from existing document resource
                ExtendedIterator<Statement> it = existingModel.createResource(getURI().toString()).listProperties(DCTerms.created).
                    andThen(existingModel.createResource(getURI().toString()).listProperties(DCTerms.creator)).
                    andThen(existingModel.createResource(getURI().toString()).listProperties(ACL.owner));
                try
                {
                    it.forEach(stmt -> model.add(stmt));
                }
                finally
                {
                    it.close();
                }

                resource.removeAll(DCTerms.modified).
                    addLiteral(DCTerms.modified, ResourceFactory.createTypedLiteral(GregorianCalendar.getInstance()));

                if (log.isDebugEnabled()) log.debug("PUT Model into existing named graph with URI: {}", getURI());
                beforeWrite.run();
                getSystem().getServiceContext(getService()).getGraphStoreClient().putModel(getURI().toString(), model); // TO-DO: catch exceptions

                // a PUT replaces the whole document, so it carries its imports every time; re-running one whose title
                // changed would fetch and import its source again
                submitImports(getChangedImports(model, existingModel));

                // no ETag or Last-Modified: what is stored is not the payload - dct:modified, the document's metadata and
                // skolemized blank nodes are added - and a PUT response may only carry a validator of a representation
                // saved without any transformation (RFC 9110 9.3.4). The client reads the new one when it needs it
                return Response.noContent().build();
            }
        });
    }
    
    /**
     * Implements <code>PATCH</code> method of SPARQL Graph Store Protocol.
     * Accepts SPARQL update as the request body which is executed in the context of the specified graph.
     * The <code>GRAPH</code> keyword and the <code>WITH</code>, <code>USING</code> and <code>USING NAMED</code> clauses are
     * therefore not allowed in the update string, and are refused with <code>422 Unprocessable Entity</code>.
     * 
     * @param updateRequest SPARQL update
     * @return response response object
     */
    @PATCH
    @Override
    public Response patch(UpdateRequest updateRequest)
    {
        checkDirectIdentification(getUriInfo());
        checkSnapshotReadOnly();

        if (updateRequest == null) throw new BadRequestException("SPARQL update not specified");
        if (log.isDebugEnabled()) log.debug("PATCH request on named graph with URI: {}", getURI());
        if (log.isDebugEnabled()) log.debug("PATCH update string: {}", updateRequest.toString());
        
        // one operation of the INSERT/DELETE forms, with no GRAPH and no WITH/USING - the update runs against this
        // graph alone, so any of those would match nothing and the PATCH would answer 204 having changed nothing
        PatchUpdateVisitor.validate(updateRequest);

        return writeLocked(() ->
        {
            final Dataset dataset;
            final Model existingModel = getSystem().getServiceContext(getService()).getGraphStoreClient().getModel(getURI().toString());
            if (existingModel == null) throw new NotFoundException("Named graph with URI <" + getURI() + "> not found");

            Response.ResponseBuilder rb = evaluatePreconditions(existingModel, getHttpHeaders());
            if (rb != null) return rb.build(); // preconditions not met

            Model beforeUpdateModel = ModelFactory.createDefaultModel().add(existingModel);
            dataset = DatasetFactory.wrap(existingModel);
            UpdateAction.execute(updateRequest, dataset); // update model in memory
            new Skolemizer(getURI().toString()).apply(existingModel); // skolemize blank nodes introduced by INSERT

            // if PATCH results in an empty graph, treat it as a DELETE request
            if (existingModel.isEmpty())
            {
                // the document cannot be deleted (the root, the owner's and the secretary's), but PATCH is supported on it:
                // 405 would say otherwise, and the update itself is what cannot be applied
                if (!getAllowedMethods().contains(HttpMethod.DELETE))
                    throw new WebApplicationException("The update would empty document <" + getURI() + ">, which cannot be deleted", UNPROCESSABLE_ENTITY.getStatusCode());

                return delete();
            }

            // ownership changes go through the admin ACL documents: a PATCH cannot be rewritten safely, so it is refused
            if (isOwnershipChanged(beforeUpdateModel, existingModel, getURI().toString()))
                throw new WebApplicationException("acl:owner and dct:creator of document <" + getURI() + "> cannot be changed", UNPROCESSABLE_ENTITY.getStatusCode());

            // SPIN constraints are class-scoped; allowing rdf:type removal would silently bypass them
            for (Resource resource : getChangedResources(beforeUpdateModel, existingModel))
            {
                Resource before = resource.inModel(beforeUpdateModel);
                Resource after = resource.inModel(existingModel);
                if (before.hasProperty(RDF.type) && !after.hasProperty(RDF.type) && after.listProperties().hasNext())
                    throw new WebApplicationException("rdf:type cannot be removed from resource <" + resource + ">", UNPROCESSABLE_ENTITY.getStatusCode());
            }

            stampModified(getURI(), beforeUpdateModel, existingModel);

            try
            {
                validate(dataset.getDefaultModel()); // this would normally be done transparently by the ValidatingModelProvider
            }
            catch (SPINConstraintViolationException ex)
            {
                // the whole post-PATCH graph gets validated, but the 422 body must describe only the
                // violating resources - the full graph would leak every sibling resource into the
                // error response
                throw describeViolations(ex, dataset.getDefaultModel());
            }
            catch (SHACLConstraintViolationException ex)
            {
                throw describeViolations(ex, dataset.getDefaultModel());
            }
            put(dataset.getDefaultModel(), Boolean.FALSE, getURI());

            // a request that accepts no RDF syntax gets no entity tag, which identifies a negotiated variant, but the write stands
            if (getWriteResponse(dataset.getDefaultModel(), null).isEmpty())
                return Response.noContent().header(HttpHeaders.CONTENT_LOCATION, getURI()).build();

            return getInternalResponse(dataset.getDefaultModel(), null).getResponseBuilder(). // entity tag of the updated graph
                status(Response.Status.NO_CONTENT).
                entity(null). // 'Content-Type' header has to be explicitly unset in ResponseHeadersFilter
                header(HttpHeaders.CONTENT_LOCATION, getURI()).
                tag(getInternalResponse(dataset.getDefaultModel(), null).getVariantEntityTag()). // TO-DO: optimize!
                build();
        });
    }
    
    /**
     * Keeps the document's dates server-managed across a <code>PATCH</code>.
     * The update can change the document's <code>dct:created</code> and <code>dct:modified</code> like any other
     * triple, and <code>Last-Modified</code> is derived from them: the stored creation date is restored, and an update
     * that changed the graph is stamped with the current time as its modification, so that a cache revalidating with
     * <code>If-Modified-Since</code> sees the change. An update that changed nothing leaves the graph, and its
     * validators, as they were.
     *
     * @param documentURI the document's URI
     * @param beforeUpdateModel the graph before the update
     * @param afterUpdateModel the graph after the update, which is changed in place
     */
    public static void stampModified(URI documentURI, Model beforeUpdateModel, Model afterUpdateModel)
    {
        if (documentURI == null) throw new IllegalArgumentException("Document URI cannot be null");
        if (beforeUpdateModel == null) throw new IllegalArgumentException("Model before update cannot be null");
        if (afterUpdateModel == null) throw new IllegalArgumentException("Model after update cannot be null");

        Resource before = beforeUpdateModel.createResource(documentURI.toString());
        Resource after = afterUpdateModel.createResource(documentURI.toString());

        after.removeAll(DCTerms.created);
        before.listProperties(DCTerms.created).forEach(stmt -> after.addProperty(DCTerms.created, stmt.getObject()));

        after.removeAll(DCTerms.modified);
        before.listProperties(DCTerms.modified).forEach(stmt -> after.addProperty(DCTerms.modified, stmt.getObject()));

        if (!afterUpdateModel.isIsomorphicWith(beforeUpdateModel))
            after.removeAll(DCTerms.modified).
                addLiteral(DCTerms.modified, ResourceFactory.createTypedLiteral(GregorianCalendar.getInstance()));
    }

    /**
     * Overrides <code>OPTIONS</code> HTTP header values.Specifies allowed methods.
     *
     * @return HTTP response
     */
    @OPTIONS
    public Response options()
    {
        Response.ResponseBuilder rb = Response.ok();
        
        rb.allow(getAllowedMethods());
        
        String acceptWritable = StringUtils.join(getWritableMediaTypes(Model.class), ",");
        rb.header("Accept-Post", acceptWritable);
        
        return rb.build();
    }
    
    /**
     * Handles multipart <code>POST</code> (RDF/POST with file parts).
     * The same append as {@link #post(Model)}, whatever encodes it: the same preconditions, <code>dct:modified</code>,
     * constraints over the whole document, imports and response. The files are staged before the write and moved
     * into place only once it goes ahead, so a refused upload leaves nothing in the upload folder.
     * 
     * @param multiPart multipart form data
     * @return HTTP response
     */
    @POST
    @Consumes(MediaType.MULTIPART_FORM_DATA)
    public Response postMultipart(FormDataMultiPart multiPart)
    {
        checkDirectIdentification(getUriInfo());
        checkSnapshotReadOnly();

        if (log.isDebugEnabled()) log.debug("MultiPart fields: {} body parts: {}", multiPart.getFields(), multiPart.getBodyParts());

        try
        {
            Model model = parseModel(multiPart);
            validate(model);
            if (log.isTraceEnabled()) log.trace("POST Graph Store request with RDF payload: {} payload size(): {}", model, model.size());

            new Skolemizer(getURI().toString()).apply(model); // skolemize before staging files (they require absolute URIs)

            List<StagedFile> stagedFiles = stageFiles(model, getFileNameBodyPartMap(multiPart));
            if (log.isDebugEnabled()) log.debug("# of files uploaded: {} ", stagedFiles.size());
            try
            {
                return post(model, () -> commitFiles(stagedFiles));
            }
            finally
            {
                discardFiles(stagedFiles); // a write that was refused, or failed, leaves its files behind otherwise
            }
        }
        catch (URISyntaxException ex)
        {
            if (log.isErrorEnabled()) log.error("URI '{}' has syntax error in request with media type: {}", ex.getInput(), multiPart.getMediaType());
            throw new BadRequestException(ex);
        }
        catch (RuntimeIOException ex)
        {
            if (log.isErrorEnabled()) log.error("Could not read uploaded file as media type: {}", multiPart.getMediaType());
            throw new BadRequestException(ex);
        }
    }

    /**
     * Handles multipart <code>PUT</code> (RDF/POST with file parts).
     * The same write as {@link #put(Model)}. The files are staged before the write and moved into place only once it
     * goes ahead, so a refused upload leaves nothing in the upload folder.
     * 
     * @param multiPart multipart form data
     * @return HTTP response
     */
    @PUT
    @Consumes(MediaType.MULTIPART_FORM_DATA)
    public Response putMultipart(FormDataMultiPart multiPart)
    {
        checkDirectIdentification(getUriInfo());
        checkSnapshotReadOnly();

        if (log.isDebugEnabled()) log.debug("MultiPart fields: {} body parts: {}", multiPart.getFields(), multiPart.getBodyParts());

        try
        {
            Model model = parseModel(multiPart);
            MessageBodyReader<Model> reader = getProviders().getMessageBodyReader(Model.class, null, null, com.atomgraph.core.MediaType.APPLICATION_NTRIPLES_TYPE);
            if (reader instanceof ValidatingModelProvider validatingModelProvider) model = validatingModelProvider.processRead(model);
            if (log.isDebugEnabled()) log.debug("POSTed Model size: {}", model.size());

            new Skolemizer(getURI().toString()).apply(model); // skolemize before staging files (they require absolute URIs)

            List<StagedFile> stagedFiles = stageFiles(model, getFileNameBodyPartMap(multiPart));
            if (log.isDebugEnabled()) log.debug("# of files uploaded: {} ", stagedFiles.size());
            try
            {
                // the same PUT as an RDF body gets - the document's type and container, its created/creator/owner
                // metadata, the If-Match precondition and the constraints of a class assigned here - rather than the
                // raw graph write, which skipped all of it for the document form
                return put(model, () -> commitFiles(stagedFiles));
            }
            finally
            {
                discardFiles(stagedFiles); // a write that was refused, or failed, leaves its files behind otherwise
            }
        }
        catch (URISyntaxException ex)
        {
            if (log.isErrorEnabled()) log.error("URI '{}' has syntax error in request with media type: {}", ex.getInput(), multiPart.getMediaType());
            throw new BadRequestException(ex);
        }
        catch (RuntimeIOException ex)
        {
            if (log.isErrorEnabled()) log.error("Could not read uploaded file as media type: {}", multiPart.getMediaType());
            throw new BadRequestException(ex);
        }
    }

    /**
     * Implements DELETE method of SPARQL Graph Store Protocol.
     * 
     * @return response
     */
    @DELETE
    @Override
    public Response delete()
    {
        checkDirectIdentification(getUriInfo());
        checkSnapshotReadOnly();

        if (!getAllowedMethods().contains(HttpMethod.DELETE))
            throw new WebApplicationException("Cannot delete document", Response.status(Response.Status.METHOD_NOT_ALLOWED).allow(getAllowedMethods()).build());

        return writeLocked(() ->
        {
            try
            {
                Model existingModel = getSystem().getServiceContext(getService()).getGraphStoreClient().getModel(getURI().toString());
            
                Response.ResponseBuilder rb = evaluatePreconditions(existingModel, getHttpHeaders());
                if (rb != null) return rb.build(); // preconditions not met
            }
            catch (NotFoundException ex)
            {
                //if (existingModel == null) existingModel = null;
            }
            
            return super.delete(false, getURI());
        });
    }
    
    /**
     * Removes the ownership properties (<code>acl:owner</code> and <code>dct:creator</code>) of the document resource
     * from a request payload. The server asserts them on creation and keeps the stored ones afterwards.
     * 
     * @param model request payload
     * @param documentURI document URI
     * @return the document resource in the payload
     */
    public static Resource removeOwnership(Model model, String documentURI)
    {
        if (model == null) throw new IllegalArgumentException("Model cannot be null");
        if (documentURI == null) throw new IllegalArgumentException("Document URI cannot be null");

        return model.createResource(documentURI).
            removeAll(ACL.owner).
            removeAll(DCTerms.creator);
    }
    
    /**
     * Returns true if the ownership properties (<code>acl:owner</code> and <code>dct:creator</code>) of the document
     * resource differ between two states of the document graph.
     * 
     * @param beforeUpdateModel graph before the update
     * @param afterUpdateModel graph after the update
     * @param documentURI document URI
     * @return true if ownership changed
     */
    public static boolean isOwnershipChanged(Model beforeUpdateModel, Model afterUpdateModel, String documentURI)
    {
        if (beforeUpdateModel == null) throw new IllegalArgumentException("Model before update cannot be null");
        if (afterUpdateModel == null) throw new IllegalArgumentException("Model after update cannot be null");
        if (documentURI == null) throw new IllegalArgumentException("Document URI cannot be null");

        Resource document = ResourceFactory.createResource(documentURI);
        for (Property property : List.of(ACL.owner, DCTerms.creator))
        {
            Set<RDFNode> before = beforeUpdateModel.listObjectsOfProperty(document, property).toSet();
            Set<RDFNode> after = afterUpdateModel.listObjectsOfProperty(document, property).toSet();
            if (!before.equals(after)) return true;
        }
        
        return false;
    }
    
    /**
     * Gets a diff of triples between two models and returns a set of their subject resources.
     * 
     * @param beforeUpdateModel model before the update
     * @param afterUpdateModel model after the update
     * @return set of changed resources
     */
    public Set<Resource> getChangedResources(Model beforeUpdateModel, Model afterUpdateModel)
    {
        if (beforeUpdateModel == null) throw new IllegalArgumentException("Model before update cannot be null");
        if (afterUpdateModel == null) throw new IllegalArgumentException("Model after update cannot be null");

        Model addedTriples = afterUpdateModel.difference(beforeUpdateModel);
        Model removedTriples = beforeUpdateModel.difference(afterUpdateModel);

        Set<Resource> changedResources = new HashSet<>();
        addedTriples.listStatements().forEachRemaining(statement -> {
            changedResources.add(statement.getSubject());
        });
        removedTriples.listStatements().forEachRemaining(statement -> {
            changedResources.add(statement.getSubject());
        });
        
        return changedResources;
    }
    
    /**
     * Get internal response object.
     * 
     * @param model RDF model
     * @param graphUri graph URI
     * @return response
     */
    public com.atomgraph.core.model.impl.Response getInternalResponse(Model model, URI graphUri)
    {
        return getInternalResponse(model, getLastModified(model, graphUri), getEntityTag(model));
    }

    /**
     * Get internal response object with the given validators.
     * The variant entity tags are derived from the given one, so the tag a response carries is the tag its
     * preconditions are evaluated against.
     *
     * @param model RDF model
     * @param lastModified last modified date
     * @param entityTag entity tag of the graph
     * @return response
     */
    public com.atomgraph.core.model.impl.Response getInternalResponse(Model model, Date lastModified, EntityTag entityTag)
    {
        return new RenderedResponse(getRequest(), getHttpHeaders(),
                model,
                lastModified,
                entityTag,
                getWritableMediaTypes(Model.class),
                getLanguages(),
                getEncodings(),
                new HTMLMediaTypePredicate(),
                // the HTML rendering negotiates over the whole accepted-language list, so two requests selecting the same
                // variant can still differ; passing it makes the entity tag tell those representations apart
                getHttpHeaders().getAcceptableLanguages(),
                new HTMLMediaTypePredicate(),
                this::getRenderingKey);
    }

    /**
     * Returns the key of the stylesheet the HTML representation is rendered with: the dataspace's stylesheet, the
     * packages it imports and, when the client stylesheet service runs, the platform build it fingerprints (the key
     * of the composed client stylesheet). Any of them changing changes the HTML, so the key goes into its entity tag.
     *
     * @return rendering key
     * @see RenderedResponse
     */
    public String getRenderingKey()
    {
        StringBuilder key = new StringBuilder();

        com.atomgraph.linkeddatahub.dataspaces.model.Dataspace dataspace = getDataspace();
        // packages are composed into the dataspace's stylesheet only, as XsltExecutableFilter does
        List<URI> packages = dataspace != null && dataspace.getStylesheet() != null ?
            getSystem().getPackageService().getPackageURIs(dataspace) : List.of();

        com.atomgraph.linkeddatahub.server.util.ClientStylesheetService stylesheetService = getSystem().getClientStylesheetService();
        if (stylesheetService != null) key.append(stylesheetService.getKey(packages));
        key.append('\n');
        if (dataspace != null && dataspace.getStylesheet() != null) key.append(dataspace.getStylesheet().getURI());
        for (URI pkg : packages) key.append('\n').append(pkg);

        return key.toString();
    }
    
    /**
     * Get response builder.
     * 
     * @param model RDF model
     * @param graphUri graph URI
     * @return response builder
     */
    @Override
    public Response.ResponseBuilder getResponseBuilder(Model model, URI graphUri)
    {
        return getInternalResponse(model, graphUri).getResponseBuilder();
    }
    
    /**
     * An uploaded file written under a temporary name in the upload folder, and the content-addressed file it is
     * moved to once the write it belongs to goes ahead.
     *
     * @param temp temporary file
     * @param target content-addressed file
     */
    public record StagedFile(Path temp, Path target) { }

    /**
     * Stages all files from the multipart RDF/POST request body. Each file resource is renamed to its
     * content-addressed URI and given its SHA1 and format, so this has to run before the model is written.
     * 
     * @param model model with RDF resources
     * @param fileNameBodyPartMap a mapping of request part names and objects
     * @return staged files, to be committed with {@link #commitFiles(List)} and discarded with {@link #discardFiles(List)}
     */
    public List<StagedFile> stageFiles(Model model, Map<String, FormDataBodyPart> fileNameBodyPartMap)
    {
        if (model == null) throw new IllegalArgumentException("Model cannot be null");
        if (fileNameBodyPartMap == null) throw new IllegalArgumentException("Map<String, FormDataBodyPart> cannot be null");
        
        List<StagedFile> stagedFiles = new ArrayList<>();
        try
        {
            // listed up front: staging renames the resource, which changes the model the iterator walks
            for (Resource file : model.listResourcesWithProperty(NFO.fileName).toList())
            {
                String fileName = file.getProperty(NFO.fileName).getString();
                FormDataBodyPart bodyPart = fileNameBodyPartMap.get(fileName);
                
                if (bodyPart != null) // bodyPart is null if nfo:fileName is a simple input and not a file input
                {
                    if (log.isDebugEnabled()) log.debug("Staging FormDataBodyPart with fileName {} for file with URI {}", fileName, file.getURI());
                    stagedFiles.add(stageFile(file, bodyPart));
                }
            }
        }
        catch (RuntimeException ex)
        {
            discardFiles(stagedFiles);
            throw ex;
        }

        return stagedFiles;
    }

    /**
     * Returns the file in a folder that a URI relative to the base addresses.
     * 
     * @param uri file URI
     * @param base application's base URI
     * @param uploadRoot destination folder URI
     * @return file
     */
    public File getFile(URI uri, URI base, URI uploadRoot)
    {
        if (uri == null) throw new IllegalArgumentException("File URI cannot be null");
        if (!uri.isAbsolute()) throw new IllegalArgumentException("File URI must be absolute");
        if (base == null) throw new IllegalArgumentException("Base URI cannot be null");
        if (uploadRoot == null) throw new IllegalArgumentException("Upload root URI cannot be null");
        
        URI relative = base.relativize(uri);
        if (log.isDebugEnabled()) log.debug("Upload folder root URI: {}", uploadRoot);
        return new File(uploadRoot.resolve(relative));
    }
    
    /**
     * Writes the specified part of the multipart request body to a temporary file in the upload folder.
     * File's RDF resource is used to attach metadata about the file, such as format and SHA1 hash sum, and is
     * renamed to the file's content-addressed URI.
     * The part is read to its end: a body over the request size limit is refused with <code>413</code> by the
     * stream {@link com.atomgraph.linkeddatahub.server.filter.request.ContentLengthLimitFilter} wraps the request in.
     * 
     * @param resource file's RDF resource
     * @param bodyPart file's body part
     * @return staged file
     */
    public StagedFile stageFile(Resource resource, FormDataBodyPart bodyPart)
    {
        if (resource == null) throw new IllegalArgumentException("File Resource cannot be null");
        if (!resource.isURIResource()) throw new IllegalArgumentException("File Resource must have a URI");
        if (bodyPart == null) throw new IllegalArgumentException("FormDataBodyPart cannot be null");

        final MessageDigest messageDigest;
        try
        {
            messageDigest = MessageDigest.getInstance("SHA-1"); // per upload: MessageDigest is not thread-safe
        }
        catch (NoSuchAlgorithmException ex)
        {
            throw new InternalServerErrorException(ex);
        }

        // in the upload folder itself, so that committing the file is a rename on the same file system
        Path uploadFolder = getFile(getUploadsUriBuilder().build(), getUriInfo().getBaseUri(), getSystem().getUploadRoot()).toPath();
        Path temp = null;
        try
        {
            temp = Files.createTempFile(uploadFolder, ".upload-", ".tmp");
            try (InputStream is = bodyPart.getEntityAs(InputStream.class);
                DigestInputStream dis = new DigestInputStream(is, messageDigest))
            {
                Files.copy(dis, temp, StandardCopyOption.REPLACE_EXISTING);
            }
            String sha1Hash = Hex.encodeHexString(messageDigest.digest()); // BigInteger seems to have an issue when the leading hex digit is 0
            if (log.isDebugEnabled()) log.debug("Staged file: {} with SHA1 hash: {}", temp, sha1Hash);

            resource.addLiteral(FOAF.sha1, sha1Hash);
            // user could have specified an explicit media type; otherwise - use the media type that the browser has sent
            if (!resource.hasProperty(DCTerms.format)) resource.addProperty(DCTerms.format, com.atomgraph.linkeddatahub.MediaType.toResource(bodyPart.getMediaType()));

            URI sha1Uri = getUploadsUriBuilder().path("{sha1}").build(sha1Hash);
            if (log.isDebugEnabled()) log.debug("Renaming resource: {} to SHA1 based URI: {}", resource, sha1Uri);
            ResourceUtils.renameResource(resource, sha1Uri.toString());

            return new StagedFile(temp, getFile(sha1Uri, getUriInfo().getBaseUri(), getSystem().getUploadRoot()).toPath());
        }
        catch (IOException ex)
        {
            deleteQuietly(temp);
            if (log.isErrorEnabled()) log.error("File I/O error", ex);
            throw new InternalServerErrorException(ex);
        }
        catch (RuntimeException ex)
        {
            deleteQuietly(temp);
            throw ex;
        }
    }

    /**
     * Moves staged files to their content-addressed names. A name that is already taken holds the same bytes,
     * possibly another document's, so it is left as it is.
     * 
     * @param stagedFiles staged files
     */
    public void commitFiles(List<StagedFile> stagedFiles)
    {
        if (stagedFiles == null) throw new IllegalArgumentException("List<StagedFile> cannot be null");

        for (StagedFile stagedFile : stagedFiles)
        {
            try
            {
                if (Files.exists(stagedFile.target())) Files.delete(stagedFile.temp());
                // a rename: a reader of the content-addressed file sees all of it or none of it
                else Files.move(stagedFile.temp(), stagedFile.target(), StandardCopyOption.ATOMIC_MOVE);
            }
            catch (IOException ex)
            {
                if (log.isErrorEnabled()) log.error("Could not move staged file {} to {}", stagedFile.temp(), stagedFile.target(), ex);
                throw new InternalServerErrorException(ex);
            }
        }
    }

    /**
     * Deletes the staged files that were not committed.
     * 
     * @param stagedFiles staged files
     */
    public void discardFiles(List<StagedFile> stagedFiles)
    {
        if (stagedFiles == null) throw new IllegalArgumentException("List<StagedFile> cannot be null");

        stagedFiles.forEach(stagedFile -> deleteQuietly(stagedFile.temp()));
    }

    /**
     * Deletes a file if it exists, logging rather than throwing on failure.
     *
     * @param path file path, or <code>null</code>
     */
    private void deleteQuietly(Path path)
    {
        if (path == null) return;

        try
        {
            Files.deleteIfExists(path);
        }
        catch (IOException ex)
        {
            if (log.isWarnEnabled()) log.warn("Could not delete staged file {}", path, ex);
        }
    }
    
    /**
     * The properties that define what an import does: its kind, its source, its transformation, its CSV delimiter and
     * its target graph. Its title, description and the provenance the import appends to it when it runs do not.
     */
    public static final List<Property> IMPORT_DEFINITION = List.of(RDF.type, LDH.file, SPIN.query, LDH.delimiter, SD.name);

    /**
     * Returns the imports in a model that are new or have been redefined against the stored document.
     * An import runs when it is defined: a write that carries an import unchanged - every <code>PUT</code> of the
     * document it is in, or one that only retitles it - must not fetch and import its source again (a <code>PUT</code>
     * is idempotent, RFC 9110 9.2.2). An import is redefined when one of its {@link #IMPORT_DEFINITION} properties has
     * other values than it has in the stored document.
     *
     * @param model the document as it is written
     * @param existingModel the document as it is stored, or <code>null</code> if it is being created
     * @return the imports to submit
     */
    public static List<Resource> getChangedImports(Model model, Model existingModel)
    {
        if (model == null) throw new IllegalArgumentException("Model cannot be null");

        ExtendedIterator<Resource> it = model.listSubjectsWithProperty(RDF.type, LDH.CSVImport).
            andThen(model.listSubjectsWithProperty(RDF.type, LDH.RDFImport)).
            filterKeep(_import -> { return _import.canAs(CSVImport.class) || _import.canAs(RDFImport.class); }); // canAs(Import.class) would require InfModel
        try
        {
            List<Resource> imports = new ArrayList<>();
            while (it.hasNext())
            {
                Resource _import = it.next();
                if (!imports.contains(_import) && (existingModel == null || isImportChanged(_import, existingModel))) imports.add(_import);
            }
            return imports;
        }
        finally
        {
            it.close();
        }
    }

    /**
     * Returns true if an import is not in the stored document, or is defined differently there.
     *
     * @param _import import resource
     * @param existingModel the document as it is stored
     * @return true if the import is new or redefined
     * @see #IMPORT_DEFINITION
     */
    public static boolean isImportChanged(Resource _import, Model existingModel)
    {
        if (_import == null) throw new IllegalArgumentException("Resource cannot be null");
        if (existingModel == null) throw new IllegalArgumentException("Model cannot be null");
        if (_import.isAnon()) return true; // a blank node is a new resource in every payload

        Resource existing = existingModel.createResource(_import.getURI());
        for (Property property : IMPORT_DEFINITION)
            if (!_import.listProperties(property).mapWith(Statement::getObject).toSet().
                    equals(existing.listProperties(property).mapWith(Statement::getObject).toSet()))
                return true;

        return false;
    }

    /**
     * Submits imports for asynchronous execution.
     * 
     * @param imports import resources
     * @see #getChangedImports(Model, Model)
     */
    public void submitImports(List<Resource> imports)
    {
        if (imports == null) throw new IllegalArgumentException("List<Resource> cannot be null");
        if (imports.isEmpty()) return;

        Service adminService = getDataspace().canAs(EndUserDataspace.class) ? getDataspace().as(EndUserDataspace.class).getAdminDataspace().getService() : null;
        // the graphs this writes are this deployment's own documents, so the content limit does not
        // apply - registered on the client, not on importClient, which also fetches the import SOURCE
        // from a URL nobody controls and stays bounded
        GraphStoreClient gsc = GraphStoreClient.create(getSystem().getImportClient(), getSystem().getMediaTypes()).
            delegation(getUriInfo().getBaseUri(), getAgentContext().orElse(null), uri -> getSystem().matchApp(uri) != null);
        gsc.register(new UnlimitedContentLengthFilter());

        for (Resource _import : imports)
        {
            // start the import asynchroniously
            if (_import.canAs(CSVImport.class))
                getSystem().submitImport(_import.as(CSVImport.class), getDataspace(), getDataspace().getService(), adminService, getUriInfo().getBaseUri().toString(), gsc);
            if (_import.canAs(RDFImport.class))
                getSystem().submitImport(_import.as(RDFImport.class), getDataspace(), getDataspace().getService(), adminService, getUriInfo().getBaseUri().toString(), gsc);
        }
    }

    /**
     * Returns the date of last modification of the specified URI resource.
     * 
     * @param model resource model
     * @param graphUri resource URI
     * @return modification date
     */
    @Override
    public Date getLastModified(Model model, URI graphUri)
    {
        if (graphUri == null) return null;
        
        return getLastModified(model.createResource(graphUri.toString()));
    }
    
    /**
     * Returns the date of last modification of the specified resource.
     * 
     * @param resource resource
     * @return modification date
     */
    public Date getLastModified(Resource resource)
    {
        if (resource == null) throw new IllegalArgumentException("Resource cannot be null");
        
        List<Date> dates = new ArrayList<>();

        StmtIterator createdIt = resource.listProperties(DCTerms.created);
        try
        {
            while (createdIt.hasNext())
            {
                Statement stmt = createdIt.next();
                if (stmt.getObject().isLiteral() && stmt.getObject().asLiteral().getValue() instanceof XSDDateTime)
                    dates.add(((XSDDateTime)stmt.getObject().asLiteral().getValue()).asCalendar().getTime());
            }
        }
        finally
        {
            createdIt.close();
        }

        StmtIterator modifiedIt = resource.listProperties(DCTerms.modified);
        try
        {
            while (modifiedIt.hasNext())
            {
                Statement stmt = modifiedIt.next();
                if (stmt.getObject().isLiteral() && stmt.getObject().asLiteral().getValue() instanceof XSDDateTime)
                    dates.add(((XSDDateTime)stmt.getObject().asLiteral().getValue()).asCalendar().getTime());
            }
        }
        finally
        {
            modifiedIt.close();
        }
        
        if (dates.isEmpty()) return null;

        // an origin must not send a Last-Modified later than the time of the response (RFC 9110 8.8.2.1); the dates are
        // data, and a document can still hold one in the future - written before they were server-managed, or imported
        Date lastModified = Collections.max(dates);
        Date now = new Date();
        return lastModified.after(now) ? now : lastModified;
    }
    
    /**
     * Gets a list of media types that a writable for a message body class.
     * 
     * @param clazz message body class, normally <code>Dataset.class</code> or <code>Model.class</code>
     * @return list of media types
     */
    @Override
    public List<MediaType> getWritableMediaTypes(Class clazz)
    {
        // restrict writable MediaTypes to the requested one (usually by RDF export feature)
        if (getUriInfo().getQueryParameters().containsKey(AC.accept.getLocalName())) // TO-DO: move to ResourceFilter?
        {
            String accept = getUriInfo().getQueryParameters().getFirst(AC.accept.getLocalName());
            
            MediaType mediaType = MediaType.valueOf(accept).withCharset(StandardCharsets.UTF_8.name()); // set charset=UTF-8
            return Arrays.asList(mediaType);
        }

        return super.getWritableMediaTypes(clazz);
    }
    
    /**
     * Validates model against SPIN and SHACL constraints.
     * 
     * @param model RDF model
     * @return validated model
     */
    public Model validate(Model model)
    {
        MessageBodyReader<Model> reader = getProviders().getMessageBodyReader(Model.class, null, null, com.atomgraph.core.MediaType.APPLICATION_NTRIPLES_TYPE);
        if (reader instanceof ValidatingModelProvider validatingModelProvider) return validatingModelProvider.processRead(model);

        throw new InternalServerErrorException("Could not obtain ValidatingModelProvider instance");
    }

    /**
     * Checks a model against the ontology's SPIN constraints and SHACL shapes, and nothing else: unlike
     * {@link #validate(Model)}, which runs the processing a request body gets when it is read, this does not
     * announce the model's <code>acl:Authorization</code>s again. A violation is reported with only the
     * violating resources described.
     *
     * @param model RDF model
     */
    public void validateConstraints(Model model)
    {
        MessageBodyReader<Model> reader = getProviders().getMessageBodyReader(Model.class, null, null, com.atomgraph.core.MediaType.APPLICATION_NTRIPLES_TYPE);
        if (!(reader instanceof ValidatingModelProvider validatingModelProvider)) throw new InternalServerErrorException("Could not obtain ValidatingModelProvider instance");

        try
        {
            validatingModelProvider.validate(model);
        }
        catch (SPINConstraintViolationException ex)
        {
            throw describeViolations(ex, model);
        }
        catch (SHACLConstraintViolationException ex)
        {
            throw describeViolations(ex, model);
        }
    }

    /**
     * Returns a SPIN violation whose model describes only the violating resources.
     *
     * @param ex violation over the whole model
     * @param model validated model
     * @return violation with the violating resources' descriptions
     */
    public SPINConstraintViolationException describeViolations(SPINConstraintViolationException ex, Model model)
    {
        Set<Resource> roots = new HashSet<>();
        for (ConstraintViolation cv : ex.getConstraintViolations())
            if (cv.getRoot() != null) roots.add(cv.getRoot());
        // the SHACL half of the same write, if it has one: its focus nodes are violating resources too
        if (ex.getValidationReport() != null)
            for (ReportEntry entry : ex.getValidationReport().getEntries())
                if (!entry.focusNode().isLiteral()) roots.add(model.asRDFNode(entry.focusNode()).asResource());

        return new SPINConstraintViolationException(ex.getConstraintViolations(), describeResources(roots, model), null, ex.getValidationReport());
    }

    /**
     * Returns a SHACL violation whose model describes only the focus nodes of the report.
     *
     * @param ex violation over the whole model
     * @param model validated model
     * @return violation with the focus nodes' descriptions
     */
    public SHACLConstraintViolationException describeViolations(SHACLConstraintViolationException ex, Model model)
    {
        Set<Resource> roots = new HashSet<>();
        for (ReportEntry entry : ex.getValidationReport().getEntries())
            if (!entry.focusNode().isLiteral()) roots.add(model.asRDFNode(entry.focusNode()).asResource());

        return new SHACLConstraintViolationException(ex.getValidationReport(), describeResources(roots, model));
    }

    /**
     * Copies the concise bounded descriptions of the given resources from a model.
     *
     * @param resources described resources
     * @param model source model
     * @return model with the descriptions
     */
    public Model describeResources(Set<Resource> resources, Model model)
    {
        Model description = ModelFactory.createDefaultModel();
        for (Resource resource : resources) addDescription(resource.inModel(model), description);
        return description;
    }

    /**
     * Adds a resource's properties to the description model, following anonymous objects.
     *
     * @param resource described resource
     * @param description target model
     */
    protected void addDescription(Resource resource, Model description)
    {
        StmtIterator it = resource.listProperties();
        try
        {
            while (it.hasNext())
            {
                Statement stmt = it.next();
                description.add(stmt);
                if (stmt.getObject().isAnon() && !description.contains(stmt.getResource(), null, (RDFNode)null))
                    addDescription(stmt.getResource(), description);
            }
        }
        finally
        {
            it.close();
        }
    }
    
    /**
     * Returns the entity tag of a graph, digested with its URI rather than folded from its triples.
     *
     * Core's implementation XORs a hash per triple, which makes the tag linear in the set: appending
     * a triple moves it by a value the appender can compute. Since HEAD is answered for any access
     * mode - so that an agent with acl:Append and no acl:Read can obtain the validator its writes
     * must quote - that turns a dropbox into a membership oracle: append a triple, see whether the
     * tag moved by its hash, learn whether it was already there. The URI goes into the digest for
     * the same reason: without it, identical content in two documents shares a tag, and a guess can
     * be materialized somewhere readable and compared.
     *
     * @param model RDF model
     * @return entity tag
     */
    @Override
    public EntityTag getEntityTag(Model model)
    {
        return EntityTags.entityTag(getURI(), model);
    }

    /**
     * Evaluates the request preconditions against the given graph's <code>Last-Modified</code> date and variant
     * <code>ETag</code>.
     * A write to a graph that already exists must carry either <code>If-Match</code> with an entity tag, or
     * <code>If-None-Match: *</code>; one that carries neither is refused with <code>428 Precondition Required</code>.
     *
     * @param model RDF model
     * @param httpHeaders the request headers the preconditions are read from
     * @return <code>null</code> if the preconditions are met; otherwise a response builder for the failed precondition
     * (<code>412</code> or <code>304</code>), tagged with the graph's current variant entity tag
     * @throws WebApplicationException with status <code>428</code> if the graph exists and the request quotes no state
     */
    public Response.ResponseBuilder evaluatePreconditions(Model model, HttpHeaders httpHeaders)
    {
        // A write to a document that already exists has to say which state it was written against. Every write
        // here is a whole-graph read-modify-write - the graph is read, changed in memory and written back - so
        // two unconditional writers overwrite each other with nothing to show that anything was lost. Measured
        // in the constructor editor: one save's DELETE was correct in every detail, answered 204, and was
        // reinstated by a second write that had read the graph before it landed. A document that does not exist
        // yet has no validator to match, so creating one is exempt.
        // Only two headers say that. If-Match with an entity tag quotes the state the write was made against;
        // If-Match: * asserts only that some state exists (RFC 9110 13.1.1), which makes the write unconditional,
        // and a blank If-Match is not a validator at all - measured, sending one opted out with 204, not 428.
        // If-None-Match: * asks to CREATE - "only if this does not exist" - and cannot also quote an entity tag it
        // is asserting there is none of; on an existing document it fails 412 below. The import writer uses exactly
        // that idiom, PUT with If-None-Match: * and then POST on the 412 that says the document is already there.
        // Any other If-None-Match only fails when it names the current tag, so a made-up one let the write through.
        String ifMatch = httpHeaders.getHeaderString(HttpHeaders.IF_MATCH);
        String ifNoneMatch = httpHeaders.getHeaderString(HttpHeaders.IF_NONE_MATCH);
        if (model != null && !model.isEmpty() && !quotesEntityTag(ifMatch) && !(ifNoneMatch != null && ifNoneMatch.strip().equals("*")))
            throw new WebApplicationException("Writing an existing document requires If-Match with its current entity tag",
                getPreconditionRequiredResponse()); // RFC 6585 3: the response SHOULD explain how to resubmit the request

        Optional<com.atomgraph.core.model.impl.Response> negotiated = getWriteResponse(model, getURI());
        if (negotiated.isEmpty()) return evaluatePreconditionsUnnegotiated(model, httpHeaders);

        com.atomgraph.core.model.impl.Response internalResponse = negotiated.get();
        Response.ResponseBuilder rb = internalResponse.evaluatePreconditions();

        // a precondition that failed says what the current validator IS, so the client can retry against it
        // without a second read - the create-or-append idiom (PUT If-None-Match: *, POST on the 412) has no
        // other way to learn it, and a 304 is supposed to carry its entity tag in any case
        if (rb != null) rb.tag(internalResponse.getVariantEntityTag());

        return rb;
    }

    /**
     * Returns the response a write evaluates its preconditions against and takes its entity tag from: the one for the
     * variant the request negotiates, or none when its <code>Accept</code> names no RDF syntax.
     * A write answers with no body - <code>204</code>, or <code>201</code> - so there is nothing for the client to
     * accept, and refusing it with <code>406</code> would refuse the write for the sake of a representation it is not
     * sent (GSP 5.3, 5.4; RFC 9110 12.5.1).
     *
     * @param model RDF model
     * @param graphUri graph URI, or <code>null</code> to leave out <code>Last-Modified</code>
     * @return the negotiated response, or empty if no variant is acceptable
     */
    public Optional<com.atomgraph.core.model.impl.Response> getWriteResponse(Model model, URI graphUri)
    {
        try
        {
            return Optional.of(getInternalResponse(model, graphUri));
        }
        catch (NotAcceptableException ex)
        {
            return Optional.empty();
        }
    }

    /**
     * Evaluates a write's preconditions when its <code>Accept</code> selects no variant.
     * An entity tag identifies a representation of the document, and with none selected the one the client quotes can
     * be any of them: <code>If-Match</code> holds when it names the current tag of any variant, and
     * <code>If-None-Match</code> fails when it names the current tag of any variant (or is <code>*</code>).
     *
     * @param model RDF model
     * @param httpHeaders the request headers the preconditions are read from
     * @return <code>null</code> if the preconditions are met; otherwise a response builder for the failed precondition
     */
    protected Response.ResponseBuilder evaluatePreconditionsUnnegotiated(Model model, HttpHeaders httpHeaders)
    {
        List<Variant> variants = new ArrayList<>(com.atomgraph.core.model.impl.Response.getVariants(getWritableMediaTypes(Model.class), getLanguages(), getEncodings(), new HTMLMediaTypePredicate()));
        // the language-neutral variants as well, as Core offers them in negotiation
        for (Variant languageNeutral : com.atomgraph.core.model.impl.Response.removeLanguages(variants))
            if (!variants.contains(languageNeutral)) variants.add(languageNeutral);

        boolean ifMatch = quotesEntityTag(httpHeaders.getHeaderString(HttpHeaders.IF_MATCH));
        Response.ResponseBuilder failed = null;
        for (Variant variant : variants)
        {
            com.atomgraph.core.model.impl.Response response = new com.atomgraph.core.model.impl.Response(getRequest(), httpHeaders,
                model,
                getLastModified(model, getURI()),
                getEntityTag(model),
                variant,
                new HTMLMediaTypePredicate(),
                httpHeaders.getAcceptableLanguages());

            Response.ResponseBuilder rb = response.evaluatePreconditions();
            if (rb == null)
            {
                if (ifMatch) return null; // the quoted tag is the current tag of this variant
            }
            else
            {
                if (failed == null) failed = rb.tag(response.getVariantEntityTag());
                if (!ifMatch) return failed; // If-None-Match named a current tag
            }
        }

        return failed;
    }

    /**
     * The body of a <code>428 Precondition Required</code> response to a write: which precondition the write needs
     * and where to get the entity tag it quotes (RFC 6585 3).
     */
    public static final String PRECONDITION_REQUIRED_MESSAGE =
        "Writing an existing resource requires the If-Match header with its current entity tag, " +
        "or If-None-Match: * to create one that does not exist yet.\n" +
        "Read the entity tag from the ETag header of a HEAD (or GET) request to the same URI, sent with the same " +
        "Accept header as the write: the tag identifies the negotiated representation.\n";

    /**
     * Returns the <code>428 Precondition Required</code> response to a write that quotes no state.
     *
     * @return response with a plain-text explanation
     * @see #PRECONDITION_REQUIRED_MESSAGE
     */
    public static Response getPreconditionRequiredResponse()
    {
        return Response.status(Response.Status.PRECONDITION_REQUIRED).
            entity(PRECONDITION_REQUIRED_MESSAGE).
            type(MediaType.TEXT_PLAIN_TYPE.withCharset(StandardCharsets.UTF_8.name())).
            build();
    }

    /**
     * Returns true if an <code>If-Match</code> header value lists at least one entity tag, as opposed to being
     * absent, blank or the <code>*</code> wildcard. Repeated headers arrive joined with commas.
     *
     * @param ifMatch <code>If-Match</code> header value, or <code>null</code>
     * @return true if the value quotes an entity tag
     */
    public static boolean quotesEntityTag(String ifMatch)
    {
        if (ifMatch == null) return false;

        return Arrays.stream(ifMatch.split(",")).map(String::strip).anyMatch(tag -> !tag.isEmpty() && !tag.equals("*"));
    }

    /**
     * Runs a write to this document while holding the document's lock.
     * <p>
     * The precondition {@link #evaluatePreconditions(Model, HttpHeaders)} checks is evaluated against a graph
     * read moments earlier and written back moments later, in separate calls to the store. Two writers quoting the
     * same entity tag that both read before either has written both pass it - the check alone does not close
     * the lost update it is there to refuse. Holding the lock from the read to the write does: the writer behind
     * reads the graph as the first one left it, and its tag no longer matches. The lock is reentrant, so a
     * <code>PATCH</code> that empties the graph can complete as the <code>DELETE</code> it is.
     * 
     * @param write the read-check-write sequence
     * @return the write's response
     * @see GraphLocks
     */
    protected Response writeLocked(Supplier<Response> write)
    {
        Lock lock = getSystem().getGraphLocks().get(getURI());
        lock.lock();
        try
        {
            return write.get();
        }
        finally
        {
            lock.unlock();
        }
    }
    
    /**
     * Parses multipart RDF/POST request.
     * 
     * @param multiPart multipart form data
     * @return RDF graph
     * @throws URISyntaxException thrown if there is a syntax error in RDF/POST data
     * @see <a href="https://atomgraph.github.io/RDF-POST/">RDF/POST Encoding for RDF</a>
     */
    public Model parseModel(FormDataMultiPart multiPart) throws URISyntaxException
    {
        if (multiPart == null) throw new IllegalArgumentException("FormDataMultiPart cannot be null");
        
        List<String> keys = new ArrayList<>(), values = new ArrayList<>();
        Iterator<BodyPart> it = multiPart.getBodyParts().iterator(); // not using getFields() to retain ordering

        while (it.hasNext())
        {
            FormDataBodyPart bodyPart = (FormDataBodyPart)it.next();
            if (log.isDebugEnabled()) log.debug("Body part media type: {} headers: {}", bodyPart.getMediaType(), bodyPart.getHeaders());

            // it's a file (if the filename is not empty)
            if (bodyPart.getContentDisposition().getFileName() != null &&
                    !bodyPart.getContentDisposition().getFileName().isEmpty())
            {
                keys.add(bodyPart.getName());
                if (log.isDebugEnabled()) log.debug("FormDataBodyPart name: {} value: {}", bodyPart.getName(), bodyPart.getContentDisposition().getFileName());
                values.add(bodyPart.getContentDisposition().getFileName());
            }
            else
            {
                if (bodyPart.isSimple() && !bodyPart.getValue().isEmpty())
                {
                    keys.add(bodyPart.getName());
                    if (log.isDebugEnabled()) log.debug("FormDataBodyPart name: {} value: {}", bodyPart.getName(), bodyPart.getValue());
                    values.add(bodyPart.getValue());
                }
            }
        }

        return RDFPostReader.parse(keys, values);
    }
    
    /**
     * Gets a map of file parts from multipart form data.
     * 
     * @param multiPart multipart form data
     * @return map of file parts
     */
    public Map<String, FormDataBodyPart> getFileNameBodyPartMap(FormDataMultiPart multiPart)
    {
        if (multiPart == null) throw new IllegalArgumentException("FormDataMultiPart cannot be null");

        Map<String, FormDataBodyPart> fileNameBodyPartMap = new HashMap<>();
        Iterator<BodyPart> it = multiPart.getBodyParts().iterator(); // not using getFields() to retain ordering
        while (it.hasNext())
        {
            FormDataBodyPart bodyPart = (FormDataBodyPart)it.next();
            if (log.isDebugEnabled()) log.debug("Body part media type: {} headers: {}", bodyPart.getMediaType(), bodyPart.getHeaders());

            if (bodyPart.getContentDisposition().getFileName() != null) // it's a file
            {
                if (log.isDebugEnabled()) log.debug("FormDataBodyPart name: {} value: {}", bodyPart.getName(), bodyPart.getContentDisposition().getFileName());
                fileNameBodyPartMap.put(bodyPart.getContentDisposition().getFileName(), bodyPart);
            }
        }
        return fileNameBodyPartMap;
    }
    
    /**
     * List allowed HTTP methods for the current graph URI.
     * Exceptions apply to the application's Root document, owner's WebID document, and secretary's WebID document.
     * 
     * @return list of HTTP methods
     */
    public Set<String> getAllowedMethods()
    {
        return allowedMethods;
    }
    
    /**
     * Returns SPARQL endpoint accessor.
     * 
     * @return endpoint accessor
     */
    public EndpointAccessor getEndpointAccessor()
    {
        return getSystem().getServiceContext(getService()).getEndpointAccessor();
    }
    
    /**
     * Returns a list of supported languages.
     * 
     * @return list of languages
     */
    @Override
    public List<Locale> getLanguages()
    {
        return getSystem().getSupportedLanguages();
    }
    
    /**
     * Returns URI builder for uploaded file resources.
     * 
     * @return URI builder
     */
    public UriBuilder getUploadsUriBuilder()
    {
        return uploadsUriBuilder.clone();
    }


    /**
     * Returns the current application.
     * 
     * @return application resource
     */
    public com.atomgraph.linkeddatahub.dataspaces.model.Dataspace getDataspace()
    {
        return application;
    }
    
    /**
     * Returns the ontology of the current application.
     * 
     * @return ontology resource
     */
    public OntModel getOntology()
    {
        return ontology;
    }

    /**
     * Returns the SPARQL service of the current application.
     * 
     * @return service resource
     */
    public Service getService()
    {
        return service;
    }
    
    /**
     * Get JAX-RS security context
     * 
     * @return security context object
     */
    public SecurityContext getSecurityContext()
    {
        return securityContext;
    }
    
    /**
     * Gets authenticated agent's context
     * 
     * @return optional agent's context
     */
    public Optional<AgentContext> getAgentContext()
    {
        return agentContext;
    }
    
    /**
     * Returns a registry of JAX-RS providers.
     * 
     * @return provider registry
     */
    public Providers getProviders()
    {
        return providers;
    }
    
    /**
     * Returns the system application.
     * 
     * @return JAX-RS application
     */
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }

    /**
     * Returns URI of the WebID document of the applications owner.
     * 
     * @return document URI
     */
    public URI getOwnerDocURI()
    {
        return ownerDocURI;
    }
    
    /**
     * Returns URI of the WebID document of the applications secretary.
     * 
     * @return document URI
     */
    public URI getSecretaryDocURI()
    {
        return secretaryDocURI;
    }
    
}