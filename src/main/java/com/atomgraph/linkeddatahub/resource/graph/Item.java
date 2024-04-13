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
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.client.LinkedDataClient;
import com.atomgraph.linkeddatahub.model.CSVImport;
import com.atomgraph.linkeddatahub.model.RDFImport;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.io.ValidatingModelProvider;
import com.atomgraph.linkeddatahub.server.model.impl.GraphStoreImpl;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.atomgraph.linkeddatahub.server.util.PatchUpdateVisitor;
import com.atomgraph.linkeddatahub.server.util.Skolemizer;
import com.atomgraph.linkeddatahub.vocabulary.DH;
import com.atomgraph.linkeddatahub.vocabulary.Default;
import com.atomgraph.linkeddatahub.vocabulary.LDH;
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
import jakarta.ws.rs.core.HttpHeaders;
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
import org.apache.jena.ontology.Ontology;
import org.apache.jena.query.Dataset;
import org.apache.jena.query.DatasetFactory;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.rdf.model.Statement;
import org.apache.jena.rdf.model.StmtIterator;
import org.apache.jena.sparql.modify.request.UpdateModify;
import org.apache.jena.sparql.vocabulary.FOAF;
import org.apache.jena.update.Update;
import org.apache.jena.update.UpdateAction;
import org.apache.jena.update.UpdateRequest;
import org.apache.jena.util.ResourceUtils;
import org.apache.jena.util.iterator.ExtendedIterator;
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

    private final Set<String> allowedMethods;
    
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
        
        URI uri = uriInfo.getAbsolutePath();
        allowedMethods = new HashSet<>();
        allowedMethods.add(HttpMethod.GET);
        allowedMethods.add(HttpMethod.POST);

        if (!ownerDocURI.equals(uri) &&
            !secretaryDocURI.equals(uri))
            allowedMethods.add(HttpMethod.PUT);

        if (!application.getBaseURI().equals(uri) &&
            !ownerDocURI.equals(uri) &&
            !secretaryDocURI.equals(uri))
            allowedMethods.add(HttpMethod.DELETE);
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

        final Model existingModel = getService().getGraphStoreClient().getModel(getURI().toString());
        // if (existingModel == null) throw new NotFoundException("Named graph with URI <" + getURI() + "> not found"); // directly-identified graph has to exist
        
        model.createResource(getURI().toString()).
            removeAll(DCTerms.modified).
            addLiteral(DCTerms.modified, ResourceFactory.createTypedLiteral(GregorianCalendar.getInstance()));
        
        // container/item (graph) resource is already skolemized, skolemize the rest of the model
        new Skolemizer(getURI().toString()).apply(model);
        
        // is this implemented correctly? The specification is not very clear.
        if (log.isDebugEnabled()) log.debug("POST Model to named graph with URI: {}", getURI());
        getService().getGraphStoreClient().add(getURI().toString(), model); // append new data to existing model
        
        submitImports(model);

        getInternalResponse(existingModel, null).evaluatePreconditions();
        Model updatedModel = existingModel.add(model);
        
        return Response.noContent().
            tag(getInternalResponse(updatedModel, null).getVariantEntityTag()). // entity tag of the updated graph
            build();
    }
    
    @Override
    @PUT
    // the AuthorizationFilter only allows creating new child URIs for existing containers (i.e. there has to be a .. container already)
    public Response put(Model model, @QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUriUnused)
    {
        if (log.isTraceEnabled()) log.trace("PUT Graph Store request with RDF payload: {} payload size(): {}", model, model.size());

        if (!getAllowedMethods().contains(HttpMethod.PUT))
        {
            if (log.isErrorEnabled()) log.error("Method '{}' is not allowed on document URI <{}>", HttpMethod.PUT, getURI());
            throw new WebApplicationException("Method '" + HttpMethod.PUT + "' is not allowed on document URI <" + getURI() + ">", Response.status(Response.Status.METHOD_NOT_ALLOWED).allow(getAllowedMethods()).build());
        }
        
        Resource resource = model.createResource(getURI().toString());
        // enforce that request URI always end with a slash and is present in the RDF document
        if (!getURI().toString().endsWith("/") || !model.containsResource(resource))
        {
            if (log.isErrorEnabled()) log.error("Document URI <{}> does not end with a slash", getURI());
            throw new WebApplicationException("Document URI <" + getURI() + "> does not end with a slash", UNPROCESSABLE_ENTITY.getStatusCode()); // 422 Unprocessable Entity
        }
        
        new Skolemizer(getURI().toString()).apply(model);
        final boolean existingGraph = getService().getGraphStoreClient().containsModel(getURI().toString());
        
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
            if (getAgentContext().isPresent()) resource.addProperty(DCTerms.creator, getAgentContext().get().getAgent());

            if (log.isDebugEnabled()) log.debug("PUT Model into new named graph with URI: {}", getURI());
            getService().getGraphStoreClient().putModel(getURI().toString(), model); // TO-DO: catch exceptions

            return Response.created(getURI()).
                build();
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

            final Model existingModel = getService().getGraphStoreClient().getModel(getURI().toString());

            if (log.isDebugEnabled()) log.debug("PUT Model into existing named graph with URI: {}", getURI());
            getService().getGraphStoreClient().putModel(getURI().toString(), model); // TO-DO: catch exceptions

            return getInternalResponse(existingModel, null).getResponseBuilder().
                build();
        }
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

        if (updateRequest.getOperations().size() > 1)
            throw new WebApplicationException("Only a single SPARQL Update is supported by PATCH", UNPROCESSABLE_ENTITY.getStatusCode()); // 422 Unprocessable Entity

        Update update = updateRequest.getOperations().get(0);
        if (!(update instanceof UpdateModify)) throw new WebApplicationException("Only INSERT/WHERE form of SPARQL Update are supported by PATCH", UNPROCESSABLE_ENTITY.getStatusCode()); // 422 Unprocessable Entity

        // check for GRAPH keyword which is disallowed
        PatchUpdateVisitor visitor = new PatchUpdateVisitor();
        update.visit(visitor);
        if (visitor.containsNamedGraph())
        {
            if (log.isWarnEnabled()) log.debug("SPARQL update used with PATCH method cannot contain the GRAPH keyword");
            throw new WebApplicationException("SPARQL update used with PATCH method cannot contain the GRAPH keyword", UNPROCESSABLE_ENTITY.getStatusCode()); // 422 Unprocessable Entity
        }
        // no need to set WITH <graphUri> since we'll be updating model in memory before persisting it

        final Dataset dataset;
        final Model existingModel = getService().getGraphStoreClient().getModel(getURI().toString());
        if (existingModel == null) throw new NotFoundException("Named graph with URI <" + getURI() + "> not found");

        com.atomgraph.core.model.impl.Response response = getInternalResponse(existingModel, null);
        ResponseBuilder rb = response.evaluatePreconditions();
        if (rb != null) return rb.build(); // preconditions not met

        dataset = DatasetFactory.wrap(existingModel);
        UpdateAction.execute(updateRequest, dataset); // update model in memory
        validate(dataset.getDefaultModel()); // this would normally be done transparently by the ValidatingModelProvider
        put(dataset.getDefaultModel(), Boolean.FALSE, getURI());
        
        
        return getInternalResponse(dataset.getDefaultModel(), null).getResponseBuilder(). // entity tag of the updated graph
            status(Response.Status.NO_CONTENT).
            entity(null). // 'Content-Type' header has to be explicitly unset in ResponseHeadersFilter
            header(HttpHeaders.CONTENT_LOCATION, getURI()).
            tag(getInternalResponse(dataset.getDefaultModel(), null).getVariantEntityTag()). // TO-DO: optimize!
            build();
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
            validate(model);
            if (log.isTraceEnabled()) log.trace("POST Graph Store request with RDF payload: {} payload size(): {}", model, model.size());

            final boolean existingGraph = getService().getGraphStoreClient().containsModel(getURI().toString());
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
        if (!getAllowedMethods().contains(HttpMethod.DELETE))
            throw new WebApplicationException("Cannot delete document", Response.status(Response.Status.METHOD_NOT_ALLOWED).allow(getAllowedMethods()).build());
        
        return super.delete(false, getURI());
    }
    
    /**
     * Get internal response object.
     * 
     * @param model RDF model
     * @param graphUri graph URI
     * @return response
     */
    public com.atomgraph.core.model.impl.Response getInternalResponse(Model model, URI graphUri) // TO-DO: graphUri not required?
    {
        return new com.atomgraph.core.model.impl.Response(getRequest(),
                model,
                getLastModified(model, graphUri),
                getEntityTag(model),
                getWritableMediaTypes(Model.class),
                getLanguages(),
                getEncodings());
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
    
    public void submitImports(Model model)
    {
        if (model == null) throw new IllegalArgumentException("Model cannot be null");

        ExtendedIterator<Resource> it = model.listSubjectsWithProperty(RDF.type, LDH.CSVImport).
            andThen(model.listSubjectsWithProperty(RDF.type, LDH.RDFImport)).
            filterKeep(_import -> { return _import.canAs(CSVImport.class) || _import.canAs(RDFImport.class); }); // canAs(Import.class) would require InfModel
        try
        {
            Service adminService = getApplication().canAs(EndUserApplication.class) ? getApplication().as(EndUserApplication.class).getAdminApplication().getService() : null;
            LinkedDataClient ldc = LinkedDataClient.create(getSystem().getClient(), getSystem().getMediaTypes()).
                delegation(getUriInfo().getBaseUri(), getAgentContext().orElse(null));

            while (it.hasNext())
            {
                Resource _import = it.next();

                // start the import asynchroniously
                if (_import.canAs(CSVImport.class))
                    getSystem().submitImport(_import.as(CSVImport.class), getApplication(), getApplication().getService(), adminService, getUriInfo().getBaseUri().toString(), ldc);
                if (_import.canAs(RDFImport.class))
                    getSystem().submitImport(_import.as(RDFImport.class), getApplication(), getApplication().getService(), adminService, getUriInfo().getBaseUri().toString(), ldc);
            }
        }
        finally
        {
            it.close();
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
