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
import com.atomgraph.linkeddatahub.client.SesameProtocolClient;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.model.Agent;
import com.atomgraph.linkeddatahub.server.io.SkolemizingModelProvider;
import com.atomgraph.linkeddatahub.server.model.ClientUriInfo;
import com.atomgraph.linkeddatahub.server.model.Patchable;
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
import javax.ws.rs.OPTIONS;
import javax.ws.rs.PATCH;
import javax.ws.rs.client.Client;
import javax.ws.rs.client.Invocation;
import javax.ws.rs.container.ResourceContext;
import javax.ws.rs.core.Response.ResponseBuilder;
import org.apache.commons.codec.digest.DigestUtils;
import org.apache.commons.lang3.StringUtils;
import org.apache.jena.datatypes.xsd.XSDDateTime;
import org.apache.jena.update.UpdateRequest;
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
public class ResourceBase extends com.atomgraph.server.model.impl.ResourceBase implements com.atomgraph.linkeddatahub.server.model.Resource, Patchable
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
        
        String acceptWritable = StringUtils.join(getWritableMediaTypes(Model.class), ",");
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

        StmtIterator it = model.listStatements(); // TO-DO: refactor using ResIterator?
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

                    // add provenance metadata for base URI-relative (internal) documents
                    if (docURI != null && !getUriInfo().getBaseUri().relativize(URI.create(docURI)).isAbsolute())
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

            return postMultipart(model, getFileNameBodyPartMap(multiPart));
        }
        catch (URISyntaxException ex)
        {
            if (log.isErrorEnabled()) log.error("URI '{}' has syntax error in request with media type: {}", ex.getInput(), multiPart.getMediaType());
            throw new WebApplicationException(ex, Response.Status.BAD_REQUEST);
        }
    }
    
    public Response postMultipart(Model model, Map<String, FormDataBodyPart> fileNameBodyPartMap)
    {
        if (model == null) throw new IllegalArgumentException("Model cannot be null");
        if (fileNameBodyPartMap == null) throw new IllegalArgumentException("Map<String, FormDataBodyPart> cannot be null");
        
        Resource itemClass = getOntology().getOntModel().getOntClass(getUriInfo().getBaseUri().resolve("ns/domain/default#Item").toString()); // TO-DO: make class URI configurable?
        if (itemClass == null) throw new IllegalStateException("nsdd:Item class not found in the application ontology");
        Resource container = null; // for uploaded triples/quads
        
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
                    container = file.getPropertyResourceValue(SIOC.HAS_CONTAINER);

                    MediaType mediaType = null;
                    if (file.hasProperty(DCTerms.format)) mediaType = com.atomgraph.linkeddatahub.MediaType.valueOf(file.getPropertyResourceValue(DCTerms.format));
                    if (mediaType != null) bodyPart.setMediaType(mediaType);

                    Model partModel = bodyPart.getValueAs(Model.class);
                    partModel = processExternalResources(partModel, container, itemClass);
                    post(partModel); // append uploaded triples/quads
                }
                else // write file
                {
                    // writing files has to go before post() as it can change model (e.g. add body part media type as dct:format)
                    if (log.isDebugEnabled()) log.debug("Writing FormDataBodyPart with fileName {} to file with URI {}", fileName, file.getURI());
                    writeFile(file, bodyPart);
                }
                count++;
            }
        }
        catch (IOException ex)
        {
            if (log.isErrorEnabled()) log.error("Error reading multipart request");
            throw new WebApplicationException(ex);
        }
        finally
        {
            resIt.close();
        }
        
        if (container != null)
        {
            if (log.isDebugEnabled()) log.debug("Redirecting to container: {} ", container.getURI());
            return Response.seeOther(URI.create(container.getURI())).build();
        }
        else
        {
            if (log.isDebugEnabled()) log.debug("# of files uploaded: {} ", count);
            return post(model);
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

    /**
     * Attaches external resources to the document hierarchy.
     * External resources: resources with URIs not relative to the app's base URI and without a fragment identifier
     * 
     * @param model with external URIs
     * @param container target container
     * @param itemClass RDF type of the internal documents that will be paired with external resources
     * @return augmented dataset
     */
    public Model processExternalResources(Model model, Resource container, Resource itemClass)
    {
        URI containerURI = URI.create(container.getURI());
        
        ResIterator it = model.listSubjects();
        try
        {
            while (it.hasNext())
            {
                Resource res = it.next();
                // pair external resources with internal resources
                if (res.isURIResource() && getUriInfo().getBaseUri().relativize(URI.create(res.getURI())).isAbsolute())
                {
                    // encode external URI as a path fragment
                    URI docURI = UriBuilder.fromUri(containerURI).path("{uri}/").buildFromEncoded(UriComponent.encode(res.getURI(), UriComponent.Type.UNRESERVED));
                    model.createResource(docURI.toString()).
                        addProperty(RDF.type, itemClass).
                        addProperty(SIOC.HAS_CONTAINER, container).
                        addProperty(FOAF.primaryTopic, res);
                }
            }
        }
        finally
        {
            it.close();
        }
        
            
//            Iterator<String> it = dataset.listNames();
//            while (it.hasNext())
//            {
//                String graphURI = it.next();
//            }
            
        return model;
    }
    
    @PATCH
    @Override
    public Response patch(UpdateRequest updateRequest)
    {
        // TO-DO: do a check that the update only uses this named graph
        getService().getEndpointAccessor().update(updateRequest, Collections.<URI>emptyList(), Collections.<URI>emptyList());
        
        return Response.ok().build();
    }
    
    /**
     * Bans up to 2 request URLs from Varnish proxy cache
     * @param resources request URLs
     * @return response from the proxy
     * @see <a href="https://varnish-cache.org/docs/trunk/users-guide/purging.html#bans">Purging and banning</a>
     */
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
    public Model describe()
    {
        // send query bindings separately from the query if the service supports the Sesame protocol
        if (getService().getSPARQLClient() instanceof SesameProtocolClient)
        {
            // get the original query string without applied bindings
            Query query = new ParameterizedSparqlString(getTemplateCall().get().getTemplate().getQuery().as(com.atomgraph.spinrdf.model.Query.class).getText(),
                getUriInfo().getBaseUri().toString()).asQuery();
            
            try (Response cr = ((SesameProtocolClient)getService().getSPARQLClient()).query(query, Model.class, getQuerySolutionMap(), new MultivaluedHashMap()))
            {
                return cr.readEntity(Model.class);
            }
        }
        else
        {
            try (Response cr = getService().getSPARQLClient().query(getQuery(), Model.class, new MultivaluedHashMap()))
            {
                return cr.readEntity(Model.class);
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