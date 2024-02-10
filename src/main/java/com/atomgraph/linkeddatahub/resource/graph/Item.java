/**
 *  Copyright 2121 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.resource.graph;

import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.core.model.EndpointAccessor;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.io.ValidatingModelProvider;
import com.atomgraph.linkeddatahub.server.model.impl.GraphStoreImpl;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.atomgraph.linkeddatahub.server.util.PatchUpdateVisitor;
import com.atomgraph.linkeddatahub.server.util.Skolemizer;
import com.atomgraph.linkeddatahub.vocabulary.DH;
import com.atomgraph.linkeddatahub.vocabulary.Default;
import com.atomgraph.linkeddatahub.vocabulary.NFO;
import com.atomgraph.linkeddatahub.vocabulary.SIOC;
import static com.atomgraph.server.status.UnprocessableEntityStatus.UNPROCESSABLE_ENTITY;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import jakarta.inject.Inject;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.HttpMethod;
import jakarta.ws.rs.InternalServerErrorException;
import jakarta.ws.rs.NotFoundException;
import jakarta.ws.rs.OPTIONS;
import jakarta.ws.rs.PATCH;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.EntityTag;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.Response.ResponseBuilder;
import jakarta.ws.rs.core.SecurityContext;
import jakarta.ws.rs.core.UriInfo;
import jakarta.ws.rs.ext.MessageBodyReader;
import jakarta.ws.rs.ext.Providers;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URISyntaxException;
import java.nio.channels.Channels;
import java.nio.channels.FileChannel;
import java.security.DigestInputStream;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import org.apache.commons.codec.binary.Hex;
import org.apache.commons.lang3.StringUtils;
import org.apache.jena.atlas.RuntimeIOException;
import org.apache.jena.datatypes.xsd.XSDDateTime;
import org.apache.jena.graph.NodeFactory;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.rdf.model.Statement;
import org.apache.jena.rdf.model.StmtIterator;
import org.apache.jena.sparql.modify.request.UpdateModify;
import org.apache.jena.sparql.vocabulary.FOAF;
import org.apache.jena.update.UpdateRequest;
import org.apache.jena.util.ResourceUtils;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;
import org.glassfish.jersey.media.multipart.FormDataBodyPart;
import org.glassfish.jersey.media.multipart.FormDataMultiPart;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS resource that handles requests to directly-identified named graphs.
 * Direct identification is specified in the Graph Store Protocol.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class Item extends GraphStoreImpl
{
    
    private static final Logger log = LoggerFactory.getLogger(Item.class);

    /**
     * Constructs resource.
     * 
     * @param request current request
     * @param uriInfo URI information of the current request
     * @param mediaTypes a registry of readable/writable media types
     * @param application current application
     * @param ontology ontology of the current application
     * @param service SPARQL service of the current application
     * @param securityContext JAX-RS security context
     * @param agentContext authenticated agent's context
     * @param providers JAX-RS provider registry
     * @param system system application
     */
    @Inject
    public Item(@Context Request request, @Context UriInfo uriInfo, MediaTypes mediaTypes,
        com.atomgraph.linkeddatahub.apps.model.Application application, Optional<Ontology> ontology, Optional<Service> service,
        @Context SecurityContext securityContext, Optional<AgentContext> agentContext,
        @Context Providers providers, com.atomgraph.linkeddatahub.Application system)
    {
        super(request, uriInfo, mediaTypes, application, ontology, service, securityContext, agentContext, providers, system);
    }

    @Override
    @GET
    public Response get(@QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUriUnused)
    {
        return super.get(false, getURI());
    }
    
    @Override
    @POST
    public Response post(Model model, @QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUriUnused)
    {
        if (log.isTraceEnabled()) log.trace("POST Graph Store request with RDF payload: {} payload size(): {}", model, model.size());

        final boolean existingGraph = getDatasetAccessor().containsModel(getURI().toString());
        if (!existingGraph) throw new NotFoundException("Named graph with URI <" + getURI() + "> not found");
        
        model.createResource(getURI().toString()).
            removeAll(DCTerms.modified).
            addLiteral(DCTerms.modified, ResourceFactory.createTypedLiteral(GregorianCalendar.getInstance()));
        
        // container/item (graph) resource is already skolemized, skolemize the rest of the model
        new Skolemizer(getURI().toString()).apply(model);
        
        // is this implemented correctly? The specification is not very clear.
        if (log.isDebugEnabled()) log.debug("POST Model to named graph with URI: {} Did it already exist? {}", getURI(), existingGraph);
        getDatasetAccessor().add(getURI().toString(), model);

        if (existingGraph) return Response.ok().build();
        else return Response.created(getURI()).build();
    }
    
    @Override
    @PUT
    // the AuthorizationFilter only allows creating new child URIs for existing containers (i.e. there has to be a .. container already)
    public Response put(Model model, @QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUriUnused)
    {
        if (log.isTraceEnabled()) log.trace("PUT Graph Store request with RDF payload: {} payload size(): {}", model, model.size());

        Set<String> allowedMethods = getAllowedMethods(getURI());
        if (!allowedMethods.contains(HttpMethod.PUT))
        {
            if (log.isErrorEnabled()) log.error("Method '{}' is not allowed on document URI <{}>", HttpMethod.PUT, getURI());
            throw new WebApplicationException("Method '" + HttpMethod.PUT + "' is not allowed on document URI <" + getURI() + ">", Response.status(Response.Status.METHOD_NOT_ALLOWED).allow(allowedMethods).build());
        }
        
        // enforce that document URIs always end with a slash
        if (!getURI().toString().endsWith("/"))
        {
            if (log.isErrorEnabled()) log.error("Document URI <{}> does not end with a slash", getURI());
            throw new WebApplicationException("Document URI <" + getURI() + "> does not end with a slash", UNPROCESSABLE_ENTITY.getStatusCode()); // 422 Unprocessable Entity
        }
        
        final boolean existingGraph = getDatasetAccessor().containsModel(getURI().toString());
        
        Resource resource = model.createResource(getURI().toString());
        if (!existingGraph) // creating new graph and attaching it to the document hierarchy
        {
            URI parentURI = getURI().resolve("..");
            Resource parent = model.createResource(parentURI.toString());
            
            resource.removeAll(SIOC.HAS_PARENT).
                removeAll(SIOC.HAS_CONTAINER);

            if (resource.hasProperty(RDF.type, DH.Container))
                resource.addProperty(SIOC.HAS_PARENT, parent);
            else
                resource.addProperty(SIOC.HAS_CONTAINER, parent).
                    addProperty(RDF.type, DH.Item); // TO-DO: replace with foaf:Document?

            resource.addLiteral(DCTerms.created, ResourceFactory.createTypedLiteral(GregorianCalendar.getInstance()));
        }
        else // updating existing graph
        {
            // TO-DO: enforce that only document with application's base URI can have the def:Root type
            if (!resource.hasProperty(RDF.type, Default.Root) &&
                !resource.hasProperty(RDF.type, DH.Container) &&
                !resource.hasProperty(RDF.type, DH.Item))
            {
                if (log.isErrorEnabled()) log.error("Named graph <{}> must contain a document resource (instance of dh:Container or dh:Item)", getURI());
                throw new WebApplicationException("Named graph <" + getURI() + "> must contain a document resource (instance of dh:Container or dh:Item)", UNPROCESSABLE_ENTITY.getStatusCode()); // 422 Unprocessable Entity
            }

            resource.removeAll(DCTerms.modified).
                addLiteral(DCTerms.modified, ResourceFactory.createTypedLiteral(GregorianCalendar.getInstance()));
        }

        new Skolemizer(getURI().toString()).apply(model);
        
        if (log.isDebugEnabled()) log.debug("PUT Model to named graph with URI: {} Did it already exist? {}", getURI(), existingGraph);
        getDatasetAccessor().putModel(getURI().toString(), model);

        if (existingGraph) return Response.ok().build();
        else return Response.created(getURI()).build();
    }
    
    /**
     * Implements <code>PATCH</code> method of SPARQL Graph Store Protocol.
     * Accepts SPARQL update as the request body which is executed in the context of the specified graph.
     * The <code>GRAPH</code> keyword is therefore not allowed in the update string.
     * 
     * @param updateRequest SPARQL update
     * @param graphUriUnused named graph URI (unused)
     * @return response response object
     */
    @PATCH
    public Response patch(UpdateRequest updateRequest, @QueryParam("graph") URI graphUriUnused)
    {
        if (updateRequest == null) throw new BadRequestException("SPARQL update not specified");

        final Model existingGraph = getDatasetAccessor().getModel(getURI().toString());
        if (existingGraph == null) throw new NotFoundException("Named graph with URI <" + getURI() + "> not found");
        
        ResponseBuilder rb = this.getResponseBuilder(existingGraph, null);
        if (rb != null) return rb.build(); // preconditions not met

        updateRequest.getOperations().forEach(update ->
        {
            // check for GRAPH keyword which is disallowed
            PatchUpdateVisitor visitor = new PatchUpdateVisitor();
            update.visit(visitor);
            if (visitor.containsNamedGraph())
            {
                if (log.isWarnEnabled()) log.debug("SPARQL update used with PATCH method cannot contain the GRAPH keyword");
                throw new WebApplicationException("SPARQL update used with PATCH method cannot contain the GRAPH keyword", UNPROCESSABLE_ENTITY.getStatusCode()); // 422 Unprocessable Entity
            }

            // set WITH <graphUri>
            if (!(update instanceof UpdateModify updateModify)) throw new WebApplicationException("Only UpdateModify form of SPARQL Update is supported", UNPROCESSABLE_ENTITY.getStatusCode()); // 422 Unprocessable Entity
            updateModify.setWithIRI(NodeFactory.createURI(getURI().toString())); // ignore the @QueryParam("graph") value
        });

        getService().getEndpointAccessor().update(updateRequest, Collections.<URI>emptyList(), Collections.<URI>emptyList());
        
        return Response.ok().build();
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
        
        rb.allow(getAllowedMethods(getURI()));
        
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
     * @param graphUriUnused named graph URI (unused)
     * @return HTTP response
     */
    @POST
    @Consumes(MediaType.MULTIPART_FORM_DATA)
    public Response postMultipart(FormDataMultiPart multiPart, @QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUriUnused)
    {
        if (log.isDebugEnabled()) log.debug("MultiPart fields: {} body parts: {}", multiPart.getFields(), multiPart.getBodyParts());

        try
        {
            Model model = parseModel(multiPart);
            MessageBodyReader<Model> reader = getProviders().getMessageBodyReader(Model.class, null, null, com.atomgraph.core.MediaType.APPLICATION_NTRIPLES_TYPE);
            if (reader instanceof ValidatingModelProvider validatingModelProvider) model = validatingModelProvider.processRead(model);
            
            if (log.isTraceEnabled()) log.trace("POST Graph Store request with RDF payload: {} payload size(): {}", model, model.size());

            final boolean existingGraph = getDatasetAccessor().containsModel(getURI().toString());
            if (!existingGraph) throw new NotFoundException("Named graph with URI <" + getURI() + "> not found");

            new Skolemizer(getURI().toString()).apply(model); // skolemize before writing files (they require absolute URIs)

            int fileCount = writeFiles(model, getFileNameBodyPartMap(multiPart));
            if (log.isDebugEnabled()) log.debug("# of files uploaded: {} ", fileCount);

            if (log.isDebugEnabled()) log.debug("POSTed Model size: {}", model.size());
            return post(model, false, getURI()); // ignore the @QueryParam("graph") value
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
     * @param graphUriUnused named graph URI (unused)
     * @return HTTP response
     */
    @PUT
    @Consumes(MediaType.MULTIPART_FORM_DATA)
    public Response putMultipart(FormDataMultiPart multiPart, @QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUriUnused)
    {
        if (log.isDebugEnabled()) log.debug("MultiPart fields: {} body parts: {}", multiPart.getFields(), multiPart.getBodyParts());

        try
        {
            Model model = parseModel(multiPart);
            MessageBodyReader<Model> reader = getProviders().getMessageBodyReader(Model.class, null, null, com.atomgraph.core.MediaType.APPLICATION_NTRIPLES_TYPE);
            if (reader instanceof ValidatingModelProvider validatingModelProvider) model = validatingModelProvider.processRead(model);
            if (log.isDebugEnabled()) log.debug("POSTed Model size: {}", model.size());

            new Skolemizer(getURI().toString()).apply(model); // skolemize before writing files (they require absolute URIs)

            int fileCount = writeFiles(model, getFileNameBodyPartMap(multiPart));
            if (log.isDebugEnabled()) log.debug("# of files uploaded: {} ", fileCount);
            
            return put(model, defaultGraph, getURI()); // ignore the @QueryParam("graph") value
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
     * @param graphUriUnused named graph URI (unused)
     * @return response
     */
    @DELETE
    @Override
    public Response delete(@QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUriUnused)
    {
        Set<String> allowedMethods = getAllowedMethods(getURI());
        if (!allowedMethods.contains(HttpMethod.DELETE))
            throw new WebApplicationException("Cannot delete document", Response.status(Response.Status.METHOD_NOT_ALLOWED).allow(allowedMethods).build());
        
        return super.delete(false, getURI());
    }
    
    /**
     * List allowed HTTP methods for the given graph URI.
     * Exceptions apply to the application's Root document, owner's WebID document, and secretary's WebID document.
     * 
     * @param graphUri ma,ed graph URI
     * @return list of HTTP methods
     */
    public Set<String> getAllowedMethods(URI graphUri)
    {
        Set<String> methods = new HashSet<>();
        methods.add(HttpMethod.GET);
        methods.add(HttpMethod.POST);
        
        if (!getOwnerDocURI().equals(graphUri) &&
            !getSecretaryDocURI().equals(graphUri))
            methods.add(HttpMethod.PUT);

        if (!getApplication().getBaseURI().equals(graphUri) &&
            !getOwnerDocURI().equals(graphUri) &&
            !getSecretaryDocURI().equals(graphUri))
            methods.add(HttpMethod.DELETE);

        return methods;
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
     * Returns the named graph URI.
     * 
     * @return graph URI
     */
    public URI getURI()
    {
        return getUriInfo().getAbsolutePath();
    }
    
    /**
     * Returns SPARQL endpoint accessor.
     * 
     * @return endpoint accessor
     */
    public EndpointAccessor getEndpointAccessor()
    {
        return getService().getEndpointAccessor();
    }
    
}
