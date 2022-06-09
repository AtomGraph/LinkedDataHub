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

import com.atomgraph.core.MediaTypes;
import com.atomgraph.core.riot.lang.RDFPostReader;
import static com.atomgraph.linkeddatahub.apps.model.Application.UPLOADS_PATH;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.io.ValidatingModelProvider;
import com.atomgraph.linkeddatahub.server.model.Patchable;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.atomgraph.linkeddatahub.server.util.Skolemizer;
import com.atomgraph.linkeddatahub.vocabulary.Default;
import com.atomgraph.linkeddatahub.vocabulary.NFO;
import com.atomgraph.processor.vocabulary.DH;
import com.atomgraph.processor.vocabulary.SIOC;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.URISyntaxException;
import java.nio.channels.Channels;
import java.nio.channels.FileChannel;
import java.security.DigestInputStream;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Function;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import javax.inject.Inject;
import javax.ws.rs.BadRequestException;
import javax.ws.rs.Consumes;
import javax.ws.rs.DELETE;
import javax.ws.rs.DefaultValue;
import javax.ws.rs.HttpMethod;
import javax.ws.rs.InternalServerErrorException;
import javax.ws.rs.OPTIONS;
import javax.ws.rs.PATCH;
import javax.ws.rs.POST;
import javax.ws.rs.PUT;
import javax.ws.rs.QueryParam;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.SecurityContext;
import javax.ws.rs.core.UriBuilder;
import javax.ws.rs.core.UriInfo;
import javax.ws.rs.ext.MessageBodyReader;
import javax.ws.rs.ext.Providers;
import org.apache.commons.codec.binary.Hex;
import org.apache.commons.lang3.StringUtils;
import org.apache.jena.atlas.RuntimeIOException;
import org.apache.jena.datatypes.xsd.XSDDateTime;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.rdf.model.Statement;
import org.apache.jena.rdf.model.StmtIterator;
import org.apache.jena.sparql.vocabulary.FOAF;
import org.apache.jena.update.UpdateFactory;
import org.apache.jena.update.UpdateRequest;
import org.apache.jena.util.ResourceUtils;
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
public class GraphStoreImpl extends com.atomgraph.core.model.impl.GraphStoreImpl implements Patchable
{
    
    private static final Logger log = LoggerFactory.getLogger(GraphStoreImpl.class);
    
    /**
     * A function that derives a graph name from the Graph Store Protocol request body.
     */
    public static Function<Model, Resource> CREATE_GRAPH = new Function<Model, Resource>()
    {
        
        /**
         * Creates a new graph URI from the document resource in the request body.
         * The new graph URI will be relative to the parent container's URI.
         * 
         * @param model input RDF graph
         * @return graph resource or null
         */
        @Override
        public Resource apply(Model model)
        {
            if (model == null) throw new IllegalArgumentException("Model cannot be null");

            Resource doc = getDocument(model);
            if (doc == null) throw new BadRequestException("Cannot create a new named graph, no Container or Item instance found in request body");

            Resource parent = getParent(doc);
            if (parent == null) throw new BadRequestException("Graph URI is not specified and no document (with sioc:has_parent or sioc:has_container) found in request body");

            // hardcoded hierarchical URL building logic
            final String slug;
            if (doc.hasProperty(DH.slug)) slug = doc.getProperty(DH.slug).getString();
            else slug = UUID.randomUUID().toString();
            URI graphUri = URI.create(parent.getURI()).resolve(slug + "/");

            if (graphUri != null) return ResourceUtils.renameResource(doc, graphUri.toString());
            else return null;
        }

        /**
         * Extracts the document that is being created from the input RDF graph.
         * 
         * @param model RDF input graph
         * @return RDF resource
         */
        public Resource getDocument(Model model)
        {
            if (model == null) throw new IllegalArgumentException("Model cannot be null");

            ResIterator it = model.listSubjectsWithProperty(SIOC.HAS_PARENT);
            try
            {
                if (it.hasNext())
                {
                    Resource doc = it.next();

                    return doc;
                }
            }
            finally
            {
                it.close();
            }

            it = model.listSubjectsWithProperty(SIOC.HAS_CONTAINER);
            try
            {
                if (it.hasNext())
                {
                    Resource doc = it.next();

                    return doc;
                }
            }
            finally
            {
                it.close();
            }

            return null;
        }

        /**
         * Returns the parent container of the specified document.
         * 
         * @param doc document resource
         * @return parent resource
         */
        public Resource getParent(Resource doc)
        {
            Resource parent = doc.getPropertyResourceValue(SIOC.HAS_PARENT);
            if (parent != null) return parent;
            parent = doc.getPropertyResourceValue(SIOC.HAS_CONTAINER);
            return parent;
        }
        
    };
    
    private final UriInfo uriInfo;
    private final com.atomgraph.linkeddatahub.apps.model.Application application;
    private final Ontology ontology;
    private final Service service;
    private final Providers providers;
    private final com.atomgraph.linkeddatahub.Application system;
    private final UriBuilder uploadsUriBuilder;
    private final MessageDigest messageDigest;
    private final URI ownerDocURI, secretaryDocURI;
    private final SecurityContext securityContext;
    private final Optional<AgentContext> agentContext;
    
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
     */
    @Inject
    public GraphStoreImpl(@Context Request request, @Context UriInfo uriInfo, MediaTypes mediaTypes,
        com.atomgraph.linkeddatahub.apps.model.Application application, Optional<Ontology> ontology, Optional<Service> service,
        @Context SecurityContext securityContext, Optional<AgentContext> agentContext,
        @Context Providers providers, com.atomgraph.linkeddatahub.Application system)
    {
        super(request, service.get(), mediaTypes);
        if (ontology.isEmpty()) throw new InternalServerErrorException("Ontology is not specified");
        if (service.isEmpty()) throw new InternalServerErrorException("Service is not specified");
        this.uriInfo = uriInfo;
        this.application = application;
        this.ontology = ontology.get();
        this.service = service.get();
        this.securityContext = securityContext;
        this.agentContext = agentContext;
        this.providers = providers;
        this.system = system;
        this.messageDigest = system.getMessageDigest();
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
    }
    
    @POST
    @Override
    public Response post(Model model, @QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        if (log.isTraceEnabled()) log.trace("POST Graph Store request with RDF payload: {} payload size(): {}", model, model.size());
        
        final boolean created;
        // neither default graph nor named graph specified -- obtain named graph URI from the document
        if (!defaultGraph && graphUri == null)
        {
            Resource graph = CREATE_GRAPH.apply(model);
            if (graph == null) throw new InternalServerErrorException("Named graph skolemization failed");
            graphUri = URI.create(graph.getURI());
            created = true;
            model.createResource(graphUri.toString()).
                addLiteral(DCTerms.created, ResourceFactory.createTypedLiteral(GregorianCalendar.getInstance()));
        }
        else created = false;
        
        // container/item (graph) resource is already skolemized, skolemize the rest of the model
        new Skolemizer(graphUri.toString()).apply(model);
        
        Response response = super.post(model, false, graphUri);
        if (created) return Response.created(graphUri).build();
        else return response;
    }

    
    @PUT
    @Override
    public Response put(Model model, @QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        if (graphUri == null) throw new BadRequestException("Named graph not specified");

        if (getOwnerDocURI().equals(graphUri)) throw new BadRequestException("Cannot update application owner's document");
        if (getSecretaryDocURI().equals(graphUri)) throw new BadRequestException("Cannot update application secretary's document");
        if (!model.createResource(graphUri.toString()).hasProperty(RDF.type, Default.Root) &&
            !model.createResource(graphUri.toString()).hasProperty(RDF.type, DH.Container) &&
            !model.createResource(graphUri.toString()).hasProperty(RDF.type, DH.Item))
            throw new BadRequestException("Named graph <" + graphUri + "> must contain a document resource (instance of dh:Container or dh:Item)");

        model.createResource(graphUri.toString()).
            removeAll(DCTerms.modified).
            addLiteral(DCTerms.modified, ResourceFactory.createTypedLiteral(GregorianCalendar.getInstance()));
        
        new Skolemizer(graphUri.toString()).apply(model);
        
        return super.put(model, defaultGraph, graphUri);
    }

    /**
     * Implements <code>PATCH</code> method of SPARQL Graph Store Protocol.Accepts SPARQL update as the request body.
     * 
     * @param updateRequest SPARQL update
     * @param graphUri named graph URI
     * @return response
     */
    @PATCH
    @Override
    public Response patch(UpdateRequest updateRequest, @QueryParam("graph") URI graphUri)
    {
        if (updateRequest == null) throw new BadRequestException("SPARQL update not specified");
        if (graphUri == null) throw new BadRequestException("Named graph not specified");
        
        String updateString = updateRequest.toString();
        // check that the update string does not contain "GRAPH <"
        Matcher graphMatcher = Pattern.compile("(?i)GRAPH(\\s*)<").matcher(updateString);
        if (graphMatcher.matches()) throw new WebApplicationException("SPARQL update used with PATCH method cannot contain the GRAPH keyword", 422); // Unprocessable Entity

        // prepend "WITH <graphUri>" before "DELETE {" or "INSERT {"
        Matcher deleteMatcher = Pattern.compile("(?i)DELETE(\\s*)\\{").matcher(updateString);
        if (deleteMatcher.matches())
            updateString = deleteMatcher.replaceAll("WITH <" + graphUri + ">\nDELETE \\{");
        else
        {
            Matcher insertMatcher = Pattern.compile("(?i)INSERT(\\s*)\\{").matcher(updateString);
            if (insertMatcher.matches())
                updateString = insertMatcher.replaceAll("WITH <" + graphUri + ">\nINSERT \\{");
            else throw new BadRequestException("SPARQL update contains no DELETE or INSERT?"); // cannot happen
        }
        updateRequest = UpdateFactory.create(updateString);
        getService().getEndpointAccessor().update(updateRequest, Collections.<URI>emptyList(), Collections.<URI>emptyList());
        
        return Response.ok().build();
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
        Response.ResponseBuilder rb = Response.ok().
            allow(HttpMethod.GET).
            allow(HttpMethod.POST).
            allow(HttpMethod.PUT).
            allow(HttpMethod.DELETE);
        
        String acceptWritable = StringUtils.join(getWritableMediaTypes(Model.class), ",");
        rb.header("Accept-Post", acceptWritable);
        
        return rb.build();
        
    }
    
    /**
     * Handles multipart <code>POST</code>
     * Files are written to storage before the RDF data is passed to the default <code>POST</code> handler method.
     * 
     * @param multiPart multipart form data
     * @param defaultGraph true if default graph is requested
     * @param graphUri named graph URI
     * @return HTTP response
     */
    @POST
    @Consumes(MediaType.MULTIPART_FORM_DATA)
    public Response postMultipart(FormDataMultiPart multiPart, @QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        if (log.isDebugEnabled()) log.debug("MultiPart fields: {} body parts: {}", multiPart.getFields(), multiPart.getBodyParts());

        try
        {
            Model model = parseModel(multiPart);
            MessageBodyReader<Model> reader = getProviders().getMessageBodyReader(Model.class, null, null, com.atomgraph.core.MediaType.APPLICATION_NTRIPLES_TYPE);
            if (reader instanceof ValidatingModelProvider validatingModelProvider) model = validatingModelProvider.processRead(model);
            
            final boolean created;
            // neither default graph nor named graph specified -- obtain named graph URI from the document
            if (!defaultGraph && graphUri == null)
            {
                Resource graph = CREATE_GRAPH.apply(model);
                if (graph == null) throw new InternalServerErrorException("Named graph skolemization failed");
                graphUri = URI.create(graph.getURI());
                created = true;
                model.createResource(graphUri.toString()).
                    addLiteral(DCTerms.created, ResourceFactory.createTypedLiteral(GregorianCalendar.getInstance()));
            }
            else created = false;

            // container/item (graph) resource is already skolemized, skolemize the rest of the model
            new Skolemizer(graphUri.toString()).apply(model);
        
            int fileCount = writeFiles(model, getFileNameBodyPartMap(multiPart));
            if (log.isDebugEnabled()) log.debug("# of files uploaded: {} ", fileCount);

            if (log.isDebugEnabled()) log.debug("POSTed Model size: {}", model.size());
            Response response = post(model, defaultGraph, graphUri);
            if (created) return Response.created(graphUri).build();
            else return response;
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
     * Handles multipart <code>PUT</code>
     * Files are written to storage before the RDF data is passed to the default <code>PUT</code> handler method.
     * 
     * @param multiPart multipart form data
     * @param defaultGraph true if default graph is requested
     * @param graphUri named graph URI
     * @return HTTP response
     */
    @PUT
    @Consumes(MediaType.MULTIPART_FORM_DATA)
    public Response putMultipart(FormDataMultiPart multiPart, @QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        if (graphUri == null) throw new InternalServerErrorException("Named graph not specified");
        if (log.isDebugEnabled()) log.debug("MultiPart fields: {} body parts: {}", multiPart.getFields(), multiPart.getBodyParts());

        try
        {
            Model model = parseModel(multiPart);
            MessageBodyReader<Model> reader = getProviders().getMessageBodyReader(Model.class, null, null, com.atomgraph.core.MediaType.APPLICATION_NTRIPLES_TYPE);
            if (reader instanceof ValidatingModelProvider validatingModelProvider) model = validatingModelProvider.processRead(model);
            if (log.isDebugEnabled()) log.debug("POSTed Model size: {}", model.size());

            int fileCount = writeFiles(model, getFileNameBodyPartMap(multiPart));
            if (log.isDebugEnabled()) log.debug("# of files uploaded: {} ", fileCount);
            
            new Skolemizer(graphUri.toString()).apply(model);
        
            return put(model, defaultGraph, graphUri);
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
     * @param defaultGraph true if default graph is requested
     * @param graphUri named graph URI
     * @return response
     */
    @DELETE
    @Override
    public Response delete(@QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        if (getApplication().getBaseURI().equals(graphUri)) throw new BadRequestException("Cannot delete Root document at application's base URI");
        if (getOwnerDocURI().equals(graphUri)) throw new BadRequestException("Cannot delete application owner's document");
        if (getSecretaryDocURI().equals(graphUri)) throw new BadRequestException("Cannot delete application secretary's document");
        
        return super.delete(false, graphUri);
    }
    
    /**
     * Writes all files from the multipart RDF/POST request body.
     * 
     * @param model model with RDF resources
     * @param fileNameBodyPartMap a mapping of request part names and objects
     * @return number of written files
     */
    public int writeFiles(Model model, Map<String, FormDataBodyPart> fileNameBodyPartMap)
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
                
                if (bodyPart != null) // bodyPart is null if nfo:fileName is a simple input and not a file input
                {
                    // writing files has to go before post() as it can change model (e.g. add body part media type as dct:format)
                    if (log.isDebugEnabled()) log.debug("Writing FormDataBodyPart with fileName {} to file with URI {}", fileName, file.getURI());
                    writeFile(file, bodyPart);

                    count++;
                }
            }
        }
        finally
        {
            resIt.close();
        }

        return count;
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
        
        try (FileOutputStream fos = new FileOutputStream(file))
        {
            if (log.isDebugEnabled()) log.debug("Writing input stream: {} to file: {}", is, file);
            FileChannel destination = fos.getChannel();
            destination.transferFrom(Channels.newChannel(is), 0, 104857600);
            return file;
        }
        catch (IOException ex)
        {
            if (log.isErrorEnabled()) log.error("Error writing file: {}", file);
            throw new InternalServerErrorException(ex);
        }
    }
    
    /**
     * Writes the specified part of the multipart request body as file and returns the file.
     * File's RDF resource is used to attached metadata about the file, such as format and SHA1 hash sum.
     * 
     * @param resource file's RDF resource
     * @param bodyPart file's body part
     * @return written file
     */
    public File writeFile(Resource resource, FormDataBodyPart bodyPart)
    {
        if (resource == null) throw new IllegalArgumentException("File Resource cannot be null");
        if (!resource.isURIResource()) throw new IllegalArgumentException("File Resource must have a URI");
        if (bodyPart == null) throw new IllegalArgumentException("FormDataBodyPart cannot be null");

        try (InputStream is = bodyPart.getEntityAs(InputStream.class);
            DigestInputStream dis = new DigestInputStream(is, getMessageDigest()))
        {
            dis.getMessageDigest().reset();
            File tempFile = File.createTempFile("tmp", null);
            FileChannel destination = new FileOutputStream(tempFile).getChannel();
            destination.transferFrom(Channels.newChannel(dis), 0, 104857600);
            String sha1Hash = Hex.encodeHexString(dis.getMessageDigest().digest()); // BigInteger seems to have an issue when the leading hex digit is 0
            if (log.isDebugEnabled()) log.debug("Wrote file: {} with SHA1 hash: {}", tempFile, sha1Hash);

            resource.addLiteral(FOAF.sha1, sha1Hash);
            // user could have specified an explicit media type; otherwise - use the media type that the browser has sent
            if (!resource.hasProperty(DCTerms.format)) resource.addProperty(DCTerms.format, com.atomgraph.linkeddatahub.MediaType.toResource(bodyPart.getMediaType()));

            URI sha1Uri = getUploadsUriBuilder().path("{sha1}").build(sha1Hash);
            if (log.isDebugEnabled()) log.debug("Renaming resource: {} to SHA1 based URI: {}", resource, sha1Uri);
            ResourceUtils.renameResource(resource, sha1Uri.toString());

            return writeFile(sha1Uri, getUriInfo().getBaseUri(), new FileInputStream(tempFile));
        }
        catch (IOException ex)
        {
            if (log.isErrorEnabled()) log.error("File I/O error", ex);
            throw new InternalServerErrorException(ex);
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
        
        if (!dates.isEmpty()) return Collections.max(dates);
        
        return null;
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
     * Returns message digest used in SHA1 hashing.
     * 
     * @return message digest
     */
    public MessageDigest getMessageDigest()
    {
        return messageDigest;
    }
    
    /**
     * Returns the request URI information.
     * 
     * @return URI info
     */
    public UriInfo getUriInfo()
    {
        return uriInfo;
    }

    /**
     * Returns the current application.
     * 
     * @return application resource
     */
    public com.atomgraph.linkeddatahub.apps.model.Application getApplication()
    {
        return application;
    }
    
    /**
     * Returns the ontology of the current application.
     * 
     * @return ontology resource
     */
    public Ontology getOntology()
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