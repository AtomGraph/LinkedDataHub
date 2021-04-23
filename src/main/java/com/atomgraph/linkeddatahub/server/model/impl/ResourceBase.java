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

import com.atomgraph.client.util.Constructor;
import com.atomgraph.client.vocabulary.AC;
import static com.atomgraph.core.MediaType.APPLICATION_SPARQL_QUERY_TYPE;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.core.riot.lang.RDFPostReader;
import com.atomgraph.core.util.ModelUtils;
import com.atomgraph.core.vocabulary.SD;
import com.atomgraph.client.util.DataManager;
import com.atomgraph.core.client.LinkedDataClient;
import com.atomgraph.linkeddatahub.client.SesameProtocolClient;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.exception.ResourceExistsException;
import com.atomgraph.linkeddatahub.model.Agent;
import com.atomgraph.linkeddatahub.server.io.SkolemizingModelProvider;
import com.atomgraph.linkeddatahub.server.model.ClientUriInfo;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.linkeddatahub.vocabulary.APL;
import com.atomgraph.linkeddatahub.vocabulary.APLT;
import com.atomgraph.linkeddatahub.vocabulary.NFO;
import com.atomgraph.linkeddatahub.vocabulary.PROV;
import com.atomgraph.linkeddatahub.vocabulary.VoID;
import com.atomgraph.processor.model.TemplateCall;
import com.atomgraph.processor.vocabulary.DH;
import com.atomgraph.processor.vocabulary.SIOC;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.query.*;
import org.apache.jena.rdf.model.*;
import org.apache.jena.sparql.vocabulary.FOAF;
import org.apache.jena.util.ResourceUtils;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import javax.ws.rs.Consumes;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.core.*;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.Response.Status;
import javax.ws.rs.ext.MessageBodyReader;
import javax.ws.rs.ext.Providers;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.URISyntaxException;
import java.nio.channels.Channels;
import java.nio.channels.FileChannel;
import java.util.*;
import javax.inject.Inject;
import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.HttpMethod;
import javax.ws.rs.NotFoundException;
import javax.ws.rs.OPTIONS;
import javax.ws.rs.client.Client;
import javax.ws.rs.client.Invocation;
import javax.ws.rs.container.ResourceContext;
import javax.ws.rs.core.Response.ResponseBuilder;
import org.apache.commons.codec.digest.DigestUtils;
import org.apache.commons.lang3.StringUtils;
import org.apache.jena.datatypes.xsd.XSDDateTime;
import org.glassfish.jersey.media.multipart.BodyPart;
import org.glassfish.jersey.media.multipart.FormDataBodyPart;
import org.glassfish.jersey.media.multipart.FormDataMultiPart;
import org.glassfish.jersey.uri.UriComponent;

/**
 * LinkedDataHub JAX-RS resource implementation.
 * It handles requests by default, unless a more specific Linked Data Template matches.
 * It also serves the base class for all other resource implementations.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Path("/")
public class ResourceBase extends com.atomgraph.server.model.impl.ResourceBase implements com.atomgraph.linkeddatahub.server.model.Resource
{
    private static final Logger log = LoggerFactory.getLogger(ResourceBase.class);
    
    private final com.atomgraph.linkeddatahub.Application system;
    private final com.atomgraph.linkeddatahub.apps.model.Application application;
    private final DataManager dataManager;
    private final SecurityContext securityContext;
    private final Providers providers;
    private final ClientUriInfo clientUriInfo;
    
    @Inject HttpServletRequest httpServletRequest;

    @Inject
    public ResourceBase(@Context UriInfo uriInfo, ClientUriInfo clientUriInfo, @Context Request request, MediaTypes mediaTypes,
            Optional<Service> service, Optional<com.atomgraph.linkeddatahub.apps.model.Application> application,
            Optional<Ontology> ontology, Optional<TemplateCall> templateCall,
            @Context HttpHeaders httpHeaders, @Context ResourceContext resourceContext,
            @Context HttpServletRequest httpServletRequest, @Context SecurityContext securityContext,
            DataManager dataManager, @Context Providers providers,
            com.atomgraph.linkeddatahub.Application system)
    {
        this(uriInfo, clientUriInfo, request, mediaTypes,
            uriInfo.getAbsolutePath(),
            service.orElse(null), application.orElse(null),
            ontology.orElse(null), templateCall,
            httpHeaders, resourceContext,
            httpServletRequest, securityContext,
            dataManager, providers,
            system);
    }

    protected ResourceBase(final UriInfo uriInfo, final ClientUriInfo clientUriInfo, final Request request, final MediaTypes mediaTypes, final URI uri, 
            final Service service, final com.atomgraph.linkeddatahub.apps.model.Application application,
            final Ontology ontology, final Optional<TemplateCall> templateCall,
            final HttpHeaders httpHeaders, final ResourceContext resourceContext,
            final HttpServletRequest httpServletRequest, final SecurityContext securityContext,
            final DataManager dataManager, final Providers providers,
            final com.atomgraph.linkeddatahub.Application system)
    {
        super(uriInfo, request, mediaTypes, uri,
                service, application, ontology, templateCall,
                httpHeaders, resourceContext);
//        if (application == null) throw new IllegalArgumentException("Application cannot be null");
        if (securityContext == null) throw new IllegalArgumentException("SecurityContext cannot be null");
        if (dataManager == null) throw new IllegalArgumentException("DataManager cannot be null");
        if (providers == null) throw new IllegalArgumentException("Providers cannot be null");
        if (system == null) throw new IllegalArgumentException("System Application cannot be null");

        if (log.isDebugEnabled()) log.debug("Constructing {}", getClass());
        this.clientUriInfo = clientUriInfo;
        this.application = application;
        this.dataManager = dataManager;
        this.httpServletRequest = httpServletRequest;
        this.securityContext = securityContext;
        this.providers = providers;
        this.system = system;
        if (log.isDebugEnabled()) log.debug("UserPrincipal: {} ", securityContext.getUserPrincipal());
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
        if (getClientUriInfo().getQueryParameters().containsKey(AC.accept.getLocalName())) // TO-DO: move to ResourceFilter?
        {
            String accept = getClientUriInfo().getQueryParameters().getFirst(AC.accept.getLocalName());
            
            MediaType mediaType = MediaType.valueOf(accept); // parse value
            mediaType = new MediaType(mediaType.getType(), mediaType.getSubtype(), MediaTypes.UTF8_PARAM); // set charset=UTF-8
            return Arrays.asList(mediaType);
        }

        return super.getWritableMediaTypes(clazz);
    }
    
    /**
     * Overrides <code>OPTIONS</code> HTTP header values.
     * Specifies allowed methods.
     * 
     * @return HTTP response
     */
    @OPTIONS
    public Response options()
    {
        ResponseBuilder rb = Response.ok().
            header(HttpHeaders.ALLOW, HttpMethod.GET).
            header(HttpHeaders.ALLOW, HttpMethod.POST);
        
        String acceptWritable = StringUtils.join(getWritableMediaTypes(Dataset.class), ",");
        rb.header("Accept-Post", acceptWritable);
        
        return rb.build();
        
    }
    
    /**
     * Handles HTTP <code>GET</code> method and returns response.
     * Adds support for some system parameters on top of the default LDT implementation.
     * 
     * @return HTTP response
     */
    @Override
    public Response get()
    {
        // special case for constructors. We want to control cache based on the latest constructor, not the Linked Data resource it was invoked on
        if (getClientUriInfo().getQueryParameters().containsKey(AC.mode.getLocalName()) && getClientUriInfo().getQueryParameters().containsKey(AC.forClass.getLocalName()))
        {
            String forClassURI = getClientUriInfo().getQueryParameters().getFirst(AC.forClass.getLocalName());
            Resource instance = new Constructor().construct(getOntology().getOntModel().getOntClass(forClassURI), ModelFactory.createDefaultModel(), getApplication().getBase().getURI());

            Variant variant = getRequest().selectVariant(getVariants(getWritableMediaTypes(Dataset.class)));
            if (variant == null) return getResponseBuilder(instance.getModel()).build(); // if quads are not acceptable, fallback to responding with the default graph

            return getResponseBuilder(DatasetFactory.create(instance.getModel())).build();
        }
        
        if (getTemplateCall().isPresent() && getTemplateCall().get().hasArgument(APLT.debug.getLocalName(), SD.SPARQL11Query))
        {
            if (log.isDebugEnabled()) log.debug("Returning SPARQL query string as debug response");
            return Response.ok(getQuery().toString()).
                    type(new MediaType(APPLICATION_SPARQL_QUERY_TYPE.getType(), APPLICATION_SPARQL_QUERY_TYPE.getType(), MediaTypes.UTF8_PARAM)).
                    build();
        }
        
        return super.get();
    }
    
    @Override
    public EntityTag getEntityTag(Model model)
    {
        long eTagHash = ModelUtils.hashModel(model);

        List<Variant> variants = getVariants(getWritableMediaTypes(Model.class));
        Variant variant = getRequest().selectVariant(variants);
        if (variant != null && variant.getMediaType().isCompatible(MediaType.TEXT_HTML_TYPE))
        {
            // authenticated agents get a different HTML representation
            if (getSecurityContext() != null && getSecurityContext().getUserPrincipal() instanceof Agent)
            {
                Agent agent = (Agent)getSecurityContext().getUserPrincipal();
                eTagHash += agent.hashCode();
            }
        }
        
        return new EntityTag(Long.toHexString(eTagHash));
    }
    
    @Override
    public EntityTag getEntityTag(Dataset dataset)
    {
        long eTagHash = com.atomgraph.core.model.impl.Response.hashDataset(dataset);
        
        List<Variant> variants = getVariants(getWritableMediaTypes(Dataset.class));
        Variant variant = getRequest().selectVariant(variants);
        if (variant != null && variant.getMediaType().isCompatible(MediaType.TEXT_HTML_TYPE))
        {
            // authenticated agents get a different HTML representation
            if (getSecurityContext() != null && getSecurityContext().getUserPrincipal() instanceof Agent)
            {
                Agent agent = (Agent)getSecurityContext().getUserPrincipal();
                eTagHash += agent.hashCode();
            }
        }
        
        return new EntityTag(Long.toHexString(eTagHash));
    }
    
    @Override
    public Date getLastModified(Model model)
    {
        if (model == null) throw new IllegalArgumentException("Model cannot be null");
        
        List<Date> dates = new ArrayList<>();

        NodeIterator createdIt = model.listObjectsOfProperty(getOntResource(), DCTerms.created);
        try
        {
            while (createdIt.hasNext())
            {
                RDFNode object = createdIt.next();
                if (object.isLiteral() && object.asLiteral().getValue() instanceof XSDDateTime)
                    dates.add(((XSDDateTime)object.asLiteral().getValue()).asCalendar().getTime());
            }
        }
        finally
        {
            createdIt.close();
        }

        NodeIterator modifiedIt = model.listObjectsOfProperty(getOntResource(), DCTerms.modified);
        try
        {
            while (modifiedIt.hasNext())
            {
                RDFNode object = modifiedIt.next();
                if (object.isLiteral() && object.asLiteral().getValue() instanceof XSDDateTime)
                    dates.add(((XSDDateTime)object.asLiteral().getValue()).asCalendar().getTime());
            }
        }
        finally
        {
            modifiedIt.close();
        }
        
        if (!dates.isEmpty()) return Collections.max(dates);
        
        return null;
    }
    
    @Override
    public Date getLastModified(Dataset dataset)
    {
        return getLastModified(dataset.getDefaultModel()); // TO-DO: we probably shouldn't be looking in the default model only
    }
    
    /**
     * Checks whether URI resource already exists in the application's service dataset.
     * 
     * @param resource URI resource
     * @return true if resource already exists
     */
    @Override
    public boolean exists(Resource resource)
    {
        if (resource == null) throw new IllegalArgumentException("Resource cannot be null");
        
        QuerySolutionMap qsm = new QuerySolutionMap();
        qsm.add(FOAF.Document.getLocalName(), resource);
        Query query = new ParameterizedSparqlString(getSystem().getGraphDocumentQuery().toString(), qsm).asQuery();
        
        if (query.isSelectType()) return getService().getSPARQLClient().select(query).hasNext();
        if (query.isAskType()) return getService().getSPARQLClient().ask(query);
        
        throw new IllegalStateException("Configured graph document query is neither ASK nor SELECT");
    }
    
    /**
     * Handles <code>POST</code> method, stores the submitted RDF dataset, and returns response.
     * Supports dataset append operation as well as creation of an individual resource using <code>forClass</code> parameter.
     * 
     * @param dataset the RDF payload
     * @return response
     */
    @Override
    public Response post(Dataset dataset)
    {
        return post(dataset, getAgent(), Calendar.getInstance());
    }
    
    public Response post(Dataset dataset, Agent agent, Calendar created)
    {
        if (getTemplateCall().isPresent() && getTemplateCall().get().hasArgument(APLT.ban))
        {
            if (log.isDebugEnabled()) log.debug("BANing current resource from proxy cache: {}", getURI());
            Response response = ban(getOntResource());
            if (response != null) response.close();
        }

        if (getClientUriInfo().getQueryParameters().containsKey(AC.uri.getLocalName())) // TO-DO: move to ResourceFilter?
        {
            String uri = getClientUriInfo().getQueryParameters().getFirst(AC.uri.getLocalName()); // external URI resource
            if (log.isDebugEnabled()) log.debug("POST request URI overridden with: {}", uri);
            return getResourceContext().getResource(ProxyResourceBase.class).post(dataset);
        }
        
        if (getTemplateCall().get().hasArgument(APLT.forClass)) // resource instance
            return construct(dataset.getDefaultModel());

        if (getService().getDatasetQuadAccessor() != null)
        {
            getService().getDatasetQuadAccessor().add(splitDefaultModel(dataset.getDefaultModel(), getUriInfo().getBaseUri(), agent, created));

//            if (getTemplateCall().get().hasArgument(APLT.upload)) // RDF data upload
//                return upload(dataset.getDefaultModel());

            return Response.ok().build();
        }
        else
        {
            Response response = super.post(splitDefaultModel(dataset.getDefaultModel(), getUriInfo().getBaseUri(), agent, created)); // append dataset to service
            
//            if (getTemplateCall().get().hasArgument(APLT.upload)) // RDF data upload
//                return upload(dataset.getDefaultModel());
            
            return response;
        }
    }
    
    @Override
    public Response construct(Model model)
    {
        // we need inference to support subclasses
        InfModel infModel = ModelFactory.createRDFSModel(getOntology().getOntModel(), model);
        return construct(infModel);
    }

    /**
     * Constructs an individual RDF resource for a given ontology class.
     * 
     * @param infModel ontology model with inference (to infer subclass hierarchies)
     * @return HTTP response
     */
    public Response construct(InfModel infModel)
    {
        if (infModel == null) throw new IllegalArgumentException("InfModel cannot be null");
        
        Resource document = getCreatedDocument(infModel);
        if (document == null || !document.isURIResource())
        {
            if (log.isErrorEnabled()) log.error("No URI resource found in constructor POST payload");
            throw new WebApplicationException(Status.BAD_REQUEST); // TO-DO: more specific Exception
        }

        if (exists(document))
        {
            URI uri = URI.create(document.getURI());
            document = ResourceUtils.renameResource(document, null); // turn the skolemized URI into blank node again
            if (log.isDebugEnabled()) log.debug("Bad request - resource '" + uri + "' already exists");
            throw new ResourceExistsException(uri, document, infModel.getRawModel());
        }

        super.post(splitDefaultModel(infModel.getRawModel())); // append description
        
        Variant variant = getRequest().selectVariant(getVariants(getWritableMediaTypes(Dataset.class)));
        if (variant == null)  // if quads are not acceptable, fallback to responding with the default graph
            return getResponseBuilder(infModel.getRawModel()).
                status(Response.Status.CREATED).
                location(URI.create(document.getURI())).
                build();
            
        return getResponseBuilder(DatasetFactory.create(infModel.getRawModel())).
            status(Response.Status.CREATED).
            location(URI.create(document.getURI())).
            build();
    }
    
    /**
     * Extracts the individual that is being created from the input RDF graph.
     * 
     * @param model RDF input graph
     * @return RDF resource
     */
    public Resource getCreatedDocument(InfModel model)
    {
        if (model == null) throw new IllegalArgumentException("Model cannot be null");
        
        ResIterator it = model.listSubjectsWithProperty(RDF.type,
                getTemplateCall().get().getArgumentProperty(APLT.forClass).getResource());
        try
        {
            if (it.hasNext())
            {
                Resource created = it.next();
                
                // handle creation of "things"- they are not documents themselves, so we return the attached document instead
                if (created.hasProperty(FOAF.isPrimaryTopicOf))
                    return created.getPropertyResourceValue(FOAF.isPrimaryTopicOf);
                else
                    return created;
            }
        }
        finally
        {
            it.close();
        }
        
        return null;
    }

//    public Response upload(Model model)
//    {
//        // we need inference to support subclasses
//        InfModel infModel = ModelFactory.createRDFSModel(getOntology().getOntModel(), model);
//        return upload(infModel);
//    }
//    
//    public Response upload(InfModel model)
//    {
//        if (model == null) throw new IllegalArgumentException("InfModel cannot be null");
//        
//        ResIterator it = model.listSubjectsWithProperty(RDF.type, APL.File);
//        try
//        {
//            if (it.hasNext())
//            {
//                Resource fileRes = it.next();
//                com.atomgraph.linkeddatahub.model.File file = fileRes.as(com.atomgraph.linkeddatahub.model.File.class);
//                LinkedDataClient ldc = LinkedDataClient.create(getClient().target(file.getURI()), getMediaTypes());
//                List<javax.ws.rs.core.MediaType> readableMediaTypesList = new ArrayList<>();
//                readableMediaTypesList.addAll(getMediaTypes().getReadable(Model.class));
//                try (Response cr = ldc.get(readableMediaTypesList.toArray(new MediaType[readableMediaTypesList.size()])))
//                {
//                    if (!cr.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
//                        throw new WebApplicationException(new IOException("RDF document could not be successfully loaded over HTTP. Status code: " + cr.getStatus()));
//
//                    post(DatasetFactory.create(cr.readEntity(Model.class)));
//                }
//            }
//        }
//        finally
//        {
//            it.close();
//        }
//
//        return Response.ok().build();
//    }
    
    /**
     * Splits the input graph into multiple RDF graphs based on the hash of the subject URI or bnode ID.
     * 
     * @param model RDF input graph
     * @return RDF dataset
     */
    
    public Dataset splitDefaultModel(Model model)
    {
        return splitDefaultModel(model, getUriInfo().getBaseUri(), getAgent(), Calendar.getInstance());
    }
    
    public Dataset splitDefaultModel(Model model, URI base, Agent agent, Calendar created)
    {
        if (model == null) throw new IllegalArgumentException("Model cannot be null");
        if (base == null) throw new IllegalArgumentException("URI base cannot be null");

        Dataset dataset = DatasetFactory.create();

        StmtIterator it = model.listStatements();
        try
        {
            while (it.hasNext())
            {
                Statement stmt = it.next();
                
                String docURI = null;
                final String hash;
                if (stmt.getSubject().isURIResource())
                {
                    docURI = stmt.getSubject().getURI();
                    if (docURI.contains("#")) docURI = docURI.substring(0, docURI.indexOf("#")); // strip the fragment, leaving only document URIs
                    hash = DigestUtils.sha1Hex(docURI);
                }
                else hash = DigestUtils.sha1Hex(stmt.getSubject().getId().getBlankNodeId().toString());
                
                String graphURI = UriBuilder.fromUri(base).path("graphs/{hash}/").build(hash).toString(); // TO-DO: use the apl:GraphItem ldt:path value
                Model namedModel = dataset.getNamedModel(graphURI);
                namedModel.add(stmt);

                // create the meta-graph with provenance metadata
                String graphHash = DigestUtils.sha1Hex(graphURI);
                String metaGraphURI = UriBuilder.fromUri(base).path("graphs/{hash}/").build(graphHash).toString();
                Model namedMetaModel = dataset.getNamedModel(metaGraphURI);
                if (namedMetaModel.isEmpty())
                {
                    Resource graph = namedMetaModel.createResource(graphURI + "#this");
                    Resource graphDoc = namedMetaModel.createResource(graphURI).
                        addProperty(RDF.type, DH.Item).
                        addProperty(SIOC.HAS_SPACE, namedMetaModel.createResource(getUriInfo().getBaseUri().toString())).
                        addProperty(SIOC.HAS_CONTAINER, namedMetaModel.createResource(UriBuilder.fromUri(base).path("graphs/").build().toString())).
                        addProperty(FOAF.maker, agent).
                        addProperty(ACL.owner, agent).
                        addProperty(FOAF.primaryTopic, graph).
                        addLiteral(PROV.generatedAtTime, namedMetaModel.createTypedLiteral(Calendar.getInstance()));
                    graph.addProperty(RDF.type, APL.Dataset).
                        addProperty(FOAF.isPrimaryTopicOf, graphDoc);

                    // add provenance metadata for documents
                    if (docURI != null)
                    {
                        Resource doc = namedMetaModel.createResource(docURI).
                            addProperty(SIOC.HAS_SPACE, namedMetaModel.createResource(getUriInfo().getBaseUri().toString())).
                            addProperty(VoID.inDataset, graph);
                    
                        if (agent != null) doc.addProperty(FOAF.maker, agent).
                            addProperty(ACL.owner, agent);
                        
                        if (created != null) doc.addLiteral(DCTerms.created, created);
                    }
                }
            }
        }
        finally
        {
            it.close();
        }
        
        return dataset;
    }

    /**
     * Handles <code>PUT</code> requests, stores the input RDF data in the application's dataset, and returns response.
     * 
     * @param dataset RDF input dataset
     * @return response <code>201 Created</code> if resource did not exist, <code>200 OK</code> if it did
     */
    @Override
    public Response put(Dataset dataset)
    {
        if (getClientUriInfo().getQueryParameters().containsKey(AC.uri.getLocalName())) // TO-DO: move to ResourceFilter?
        {
            String uri = getClientUriInfo().getQueryParameters().getFirst(AC.uri.getLocalName()); // external URI resource
            if (log.isDebugEnabled()) log.debug("PUT request URI overridden with: {}", uri);
            return getResourceContext().getResource(ProxyResourceBase.class).put(dataset);
        }
        
        Response response;
        try
        {
            Calendar created = null;
            // workaround in order to retain the dct:created value in the meta-graph - without it delete() will wipe all statements about the current resource
            Dataset description = describe();
            Statement createdStmt = description.getDefaultModel().createResource(getURI().toString()).getProperty(DCTerms.created);
            if (createdStmt != null)
            {
                RDFNode object = createdStmt.getObject();
                if (object.isLiteral() && object.asLiteral().getValue() instanceof XSDDateTime)
                    created = (((XSDDateTime)object.asLiteral().getValue()).asCalendar());
            }
            
            delete();
            
            response = post(dataset, getAgent(), created); // add the original dct:created value to the meta-graph
            
            if (created != null)
            {
                ParameterizedSparqlString updateString = new ParameterizedSparqlString(
                    getSystem().getPutUpdate(getUriInfo().getBaseUri().toString()).toString(),
                    getQuerySolutionMap());
                updateString.setLiteral(DCTerms.created.getLocalName(), created); // only match the dct:created value we had before this request, not the one we just added

                if (log.isDebugEnabled()) log.debug("Update meta-graph: {}", updateString);
                getService().getEndpointAccessor().update(updateString.asUpdate(), Collections.<URI>emptyList(), Collections.<URI>emptyList());
            }
        }
        catch (NotFoundException ex)
        {
            post(dataset);
            
            response = Response.created(getURI()).build();
        }
            
        return response;
    }
    
    /**
     * Handles <code>DELETE</code> method, deletes the RDF representation of this resource as well as its meta-graph from the application's dataset, and
     * returns response.
     * 
     * @return response <code>204 No Content</code>
     */
    @Override
    public Response delete()
    {
        Response response = super.delete();
        
        ParameterizedSparqlString updateString = new ParameterizedSparqlString(
                getSystem().getDeleteUpdate(getUriInfo().getBaseUri().toString()).toString(),
                getQuerySolutionMap());
        
        if (getRequest().getMethod().equals(HttpMethod.DELETE)) // don't delete the meta-graph if it's a PUT request
        {
            if (log.isDebugEnabled()) log.debug("Delete meta-graph: {}", updateString);
            getService().getEndpointAccessor().update(updateString.asUpdate(), Collections.<URI>emptyList(), Collections.<URI>emptyList());
        }
        
        return response;
    }
    
    /**
     * Handles multipart <code>POST</code> requests, stores uploaded files, and returns response.
     * Files are written to storage before the RDF data is passed to the default <code>POST</code> handler method.
     * 
     * @param multiPart multipart form data
     * @return HTTP response
     */
    @POST
    @Consumes(MediaType.MULTIPART_FORM_DATA)
    @Override
    public Response postMultipart(FormDataMultiPart multiPart)
    {
        if (log.isDebugEnabled()) log.debug("MultiPart fields: {} body parts: {}", multiPart.getFields(), multiPart.getBodyParts());

        try
        {
            Model model = parseModel(multiPart);
            MessageBodyReader<Model> reader = getProviders().getMessageBodyReader(Model.class, null, null, com.atomgraph.core.MediaType.APPLICATION_NTRIPLES_TYPE);
            if (reader instanceof SkolemizingModelProvider) model = ((SkolemizingModelProvider)reader).process(model);
            if (log.isDebugEnabled()) log.debug("POSTed Model size: {}", model.size());

            // writing files has to go before post() as it can change model (e.g. add body part media type as dct:format)
            int count = processFormDataMultiPart(model, multiPart);
            if (log.isDebugEnabled()) log.debug("{} Files uploaded from FormDataMultiPart: {} ", count, multiPart);

            return post(DatasetFactory.create(model));
        }
        catch (URISyntaxException ex)
        {
            if (log.isErrorEnabled()) log.error("URI '{}' has syntax error in request with media type: {}", ex.getInput(), multiPart.getMediaType());
            throw new WebApplicationException(ex, Response.Status.BAD_REQUEST);
        }
        catch (IOException ex)
        {
            if (log.isErrorEnabled()) log.error("Error reading multipart request");
            throw new WebApplicationException(ex);
        }
    }
    
    /**
     * Parses multipart RDF/POST request.
     * 
     * @param multiPart multipart form data
     * @return RDF graph
     * @throws URISyntaxException thrown if there is a syntax error in RDF/POST data
     * @see <a href="http://www.lsrn.org/semweb/rdfpost.html">RDF/POST Encoding for RDF</a>
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
     * Processes file parts in multipart form data.
     * 
     * @param model RDF graph parsed from multipart form data
     * @param multiPart multipart form data
     * @return number of files written
     * @throws IOException processing error
     */
    public int processFormDataMultiPart(Model model, FormDataMultiPart multiPart) throws IOException
    {
        return processFormDataBodyParts(model, getFileNameBodyPartMap(multiPart));
    }
    
    /**
     * Writes files from multipart form data parts.
     * 
     * @param model RDF graph parsed from multipart form data
     * @param fileNameBodyPartMap map of file parts
     * @return number of files written
     * @throws IOException processing error
     * @see <a href="http://oscaf.sourceforge.net/nfo.html">NFO - Nepomuk File Ontology</a>
     */
    public int processFormDataBodyParts(Model model, Map<String, FormDataBodyPart> fileNameBodyPartMap) throws IOException
    {
        if (model == null) throw new IllegalArgumentException("Model cannot be null");
        if (fileNameBodyPartMap == null) throw new IllegalArgumentException("Map<String, FormDataBodyPart> cannot be null");
        
        int count = 0;
        ResIterator resIt = model.listResourcesWithProperty(NFO.fileName);
        try
        {
            while (resIt.hasNext())
            {
                Resource file = resIt.next();
                String fileName = file.getProperty(NFO.fileName).getString();
                FormDataBodyPart bodyPart = fileNameBodyPartMap.get(fileName);
                
                if (getTemplateCall().get().hasArgument(APLT.upload)) // upload RDF data
                {
                    MediaType mediaType = null;
                    if (file.hasProperty(DCTerms.format)) mediaType = MediaType.valueOf(file.getProperty(DCTerms.format).getString());
                    if (mediaType != null) bodyPart.setMediaType(mediaType);

                    Dataset dataset = bodyPart.getValueAs(Dataset.class);
                    post(dataset);
                }
                else // write file
                {
                    if (log.isDebugEnabled()) log.debug("Writing FormDataBodyPart with fileName {} to file with URI {}", fileName, file.getURI());
                    writeFile(file, bodyPart);
                }
                count++;
            }
        }
        finally
        {
            resIt.close();
        }
        
        return count;
    }

    /**
     * Writes file data part.
     * 
     * @param resource file resource
     * @param bodyPart file data part
     * @return file
     * @throws IOException error while writing
     */
    public File writeFile(Resource resource, FormDataBodyPart bodyPart) throws IOException
    {
        if (resource == null) throw new IllegalArgumentException("File Resource cannot be null");
        if (!resource.isURIResource()) throw new IllegalArgumentException("File Resource must have a URI");
        if (bodyPart == null) throw new IllegalArgumentException("FormDataBodyPart cannot be null");
        
        Resource mediaType = com.atomgraph.linkeddatahub.MediaType.toResource(bodyPart.getMediaType());
        if (log.isDebugEnabled()) log.debug("Setting media type {} for uploaded resource {}", mediaType, resource);
        resource.addProperty(DCTerms.format, mediaType);

        if (log.isDebugEnabled()) log.debug("Uploaded file: {}", bodyPart.getContentDisposition().getFileName());
        try (InputStream is = bodyPart.getEntityAs(InputStream.class))
        {
            return writeFile(URI.create(resource.getURI()), getUriInfo().getBaseUri(), is);
        }
    }

    /**
     * Writes a data stream to the upload folder.
     * 
     * @param uri file URI
     * @param base application's base URI
     * @param is file input stream
     * @return file
     */
    public File writeFile(URI uri, URI base, InputStream is)
    {
        return writeFile(uri, base, getSystem().getUploadRoot(), is);
    }
    
    /**
     * Writes a data stream to a folder.
     * 
     * @param uri file URI
     * @param base application's base URI
     * @param uploadRoot destination folder URI
     * @param is file input stream
     * @return file
     */
    public File writeFile(URI uri, URI base, URI uploadRoot, InputStream is)
    {
        if (uri == null) throw new IllegalArgumentException("File URI cannot be null");
        if (!uri.isAbsolute()) throw new IllegalArgumentException("File URI must be absolute");
        if (base == null) throw new IllegalArgumentException("Base URI cannot be null");
        if (uploadRoot == null) throw new IllegalArgumentException("Upload root URI cannot be null");
        
        URI relative = base.relativize(uri);
        if (log.isDebugEnabled()) log.debug("Upload folder root URI: {}", uploadRoot);
        File file = new File(uploadRoot.resolve(relative));
        
        return writeFile(file, is);
    }
    
    /**
     * Writes data stream to a file destination.
     * 
     * @param file destination
     * @param is input stream
     * @return file
     */
    public File writeFile(File file, InputStream is)
    {
        if (file == null) throw new IllegalArgumentException("File cannot be null");
        if (is == null) throw new IllegalArgumentException("File InputStream cannot be null");
        
        try
        {
            if (log.isDebugEnabled()) log.debug("Writing input stream: {} to file: {}", is, file);
            FileChannel destination = new FileOutputStream(file).getChannel();
            destination.transferFrom(Channels.newChannel(is), 0, 104857600);
            return file;
        }
        catch (IOException ex)
        {
            if (log.isErrorEnabled()) log.error("Error writing file: {}", file);
            throw new WebApplicationException(ex);
        }
    }

    public Response ban(org.apache.jena.rdf.model.Resource... resources)
    {
        if (resources == null) throw new IllegalArgumentException("Resource cannot be null");
        
        if (getApplication().getService().getProxy() != null)
        {
            // create new Client instance, otherwise ApacheHttpClient reuses connection and Varnish ignores BAN request
            Invocation.Builder builder = getClient().target(getApplication().getService().getProxy().getURI()).request();

            for (Resource resource : resources)
                if (resource != null)
                {
                    // make URIs relative *iff* they will appear in SPARQL queries with BASE
                    URI uri = URI.create(resource.getURI());
//                    uri = getApplication().getBaseURI().relativize(uri);

                    // encode the URI, because that is how it will appear in SPARQL Protocol URLs cached by the backend proxy
                    builder = builder.header("X-Escaped-Request-URI", UriComponent.encode(uri.toString(), UriComponent.Type.UNRESERVED));
                }

            return builder.method("BAN", Response.class);
        }

        return null;
    }

    /**
     * Gets agent authenticated for the current request.
     * 
     * @return agent
     */
    @Override
    public Agent getAgent()
    {
        if (getSecurityContext() != null &&
                getSecurityContext().getUserPrincipal() != null &&
                getSecurityContext().getUserPrincipal() instanceof Agent)
            return (Agent)getSecurityContext().getUserPrincipal();
        
        return null;
    }
    
    /**
     * Solution map (variable bindings) for the SPARQL query executed by the current request.
     * 
     * @return solution map
     * @see #getQuery()
     */
    @Override
    public QuerySolutionMap getQuerySolutionMap()
    {
        QuerySolutionMap qsm = super.getQuerySolutionMap();
        
        Agent agent = getAgent();
        if (agent != null) qsm.add(FOAF.Agent.getLocalName(), agent);
        else qsm.add(FOAF.Agent.getLocalName(), FOAF.Agent); // value that will never match

        return qsm;
    }
    
    /**
     * Retrieves RDF description of the resource that is being requested.
     * The description is the result of a SPARQL query execution on the application's service.
     * Variable bindings are either applied to the query string or sent separately as parameters, depending on the service capabilities.
     * 
     * @return RDF dataset
     */
    @Override
    public Dataset describe()
    {
        // send query bindings separately from the query if the service supports the Sesame protocol
        if (getService().getSPARQLClient() instanceof SesameProtocolClient)
        {
            // get the original query string without applied bindings
            Query query = new ParameterizedSparqlString(getTemplateCall().get().getTemplate().getQuery().as(com.atomgraph.spinrdf.model.Query.class).getText(),
                getUriInfo().getBaseUri().toString()).asQuery();
            
            try (Response cr = ((SesameProtocolClient)getService().getSPARQLClient()).query(query, Dataset.class, getQuerySolutionMap(), new MultivaluedHashMap()))
            {
                return cr.readEntity(Dataset.class);
            }
        }
        else
        {
            try (Response cr = getService().getSPARQLClient().query(getQuery(), Dataset.class, new MultivaluedHashMap()))
            {
                return cr.readEntity(Dataset.class);
            }
        }
    }
    
    public Resource getArgument(Model model, Resource type)
    {
        if (model == null) throw new IllegalArgumentException("Model cannot be null");
        if (type == null) throw new IllegalArgumentException("Resource cannot be null");

        ResIterator it = model.listSubjectsWithProperty(RDF.type, type);

        try
        {
            if (it.hasNext()) return it.next();
        }
        finally
        {
            it.close();
        }
        
        return null;
    }
    
    /**
     * Returns the value of the <code>Cache-Control</code> HTTP response header.
     * 
     * @return cache control value
     */
    @Override
    public CacheControl getCacheControl()
    {
        if (getTemplateCall().get().hasArgument(APLT.forClass))
            return CacheControl.valueOf("no-cache"); // do not cache instance pages
        
        return super.getCacheControl();
    }
    
    /**
     * Get supported (readable/writable) media types.
     * 
     * @return 
     */
    @Override
    public MediaTypes getMediaTypes()
    {
        return getSystem().getMediaTypes();
    }

    public ClientUriInfo getClientUriInfo()
    {
        return clientUriInfo;
    }
    
    public DataManager getDataManager()
    {
        return dataManager;
    }
    
    public HttpServletRequest getHttpServletRequest()
    {
        return httpServletRequest;
    }
    
    public SecurityContext getSecurityContext()
    {
        return securityContext;
    }

    public Providers getProviders()
    {
        return providers;
    }
  
    @Override
    public com.atomgraph.linkeddatahub.apps.model.Application getApplication()
    {
        return application;
    }

    @Override
    public com.atomgraph.linkeddatahub.model.Service getService()
    {
        return getApplication().getService();
    }
    
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }
 
    public Client getClient()
    {
        return getSystem().getClient();
    }
    
}