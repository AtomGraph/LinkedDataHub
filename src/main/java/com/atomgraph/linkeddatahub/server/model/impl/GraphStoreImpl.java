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
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.io.SkolemizingModelProvider;
import com.atomgraph.linkeddatahub.vocabulary.APLT;
import com.atomgraph.linkeddatahub.vocabulary.NFO;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.URISyntaxException;
import java.nio.channels.Channels;
import java.nio.channels.FileChannel;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import javax.inject.Inject;
import javax.ws.rs.BadRequestException;
import javax.ws.rs.Consumes;
import javax.ws.rs.DefaultValue;
import javax.ws.rs.InternalServerErrorException;
import javax.ws.rs.POST;
import javax.ws.rs.QueryParam;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.UriInfo;
import javax.ws.rs.ext.MessageBodyReader;
import javax.ws.rs.ext.Providers;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
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
public class GraphStoreImpl extends com.atomgraph.core.model.impl.GraphStoreImpl
{
    
    private static final Logger log = LoggerFactory.getLogger(GraphStoreImpl.class);

    private final UriInfo uriInfo;
    private final Providers providers;
    private final com.atomgraph.linkeddatahub.Application system;

    @Inject
    public GraphStoreImpl(@Context Request request, Optional<Service> service, MediaTypes mediaTypes,
        @Context UriInfo uriInfo, @Context Providers providers, com.atomgraph.linkeddatahub.Application system)
    {
        super(request, service.get(), mediaTypes);
        this.uriInfo = uriInfo;
        this.providers = providers;
        this.system = system;
    }
    
    @POST
    @Override
    public Response post(Model model, @QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        if (log.isDebugEnabled()) log.debug("POST Graph Store request with RDF payload: {} payload size(): {}", model, model.size());
        
        if (model.isEmpty()) return Response.noContent().build();
        
        if (defaultGraph)
        {
            if (log.isDebugEnabled()) log.debug("POST Model to default graph");
            getDatasetAccessor().add(model);
            return Response.ok().build();
        }
        else
        {
            final boolean existingGraph;
            if (graphUri != null) existingGraph = getDatasetAccessor().containsModel(graphUri.toString());
            else
            {
                existingGraph = false;
  
                final URI forClass;
                try
                {
                    if (getUriInfo().getQueryParameters().containsKey(APLT.forClass.getLocalName()))
                        forClass = new URI(getUriInfo().getQueryParameters().getFirst(APLT.forClass.getLocalName()));
                    else
                        throw new BadRequestException("aplt:ForClass parameter not provided");
                    
                    return post(model, forClass);
                }
                catch (URISyntaxException ex)
                {
                    throw new BadRequestException(ex);
                }
                
//                Resource instance = getForClassResource(model, ResourceFactory.createResource(forClass.toString()));
//                graphUri = URI.create(instance.getURI());
                
//                ResIterator it = model.listSubjects();
//                try
//                {
//                    // TO-DO: this is really fragile, we should get rid of this and require an explicit graphUri
//                    graphUri = URI.create(it.next().getURI()); // there has to be a subject resource since we checked (above) that the model is not empty
//                    graphUri = new URI(graphUri.getScheme(), graphUri.getSchemeSpecificPart(), null).normalize(); // strip the possible fragment identifier
//                }
//                catch (URISyntaxException ex)
//                {
//                    // shouldn't happen
//                }
//                finally
//                {
//                    it.close();
//                }
            }

            // is this implemented correctly? The specification is not very clear.
            if (log.isDebugEnabled()) log.debug("POST Model to named graph with URI: {} Did it already exist? {}", graphUri, existingGraph);
            getDatasetAccessor().add(graphUri.toString(), model);

            if (existingGraph) return Response.ok().build();
            else return Response.created(graphUri).build();
        }
    }

    public Response post(Model model, URI forClass)
    {
        Resource instance = getForClassResource(model, ResourceFactory.createResource(forClass.toString()));
        if (instance == null) throw new BadRequestException("aplt:ForClass typed resource not found in model");
        
        try
        {
            URI graphUri = URI.create(instance.getURI());
            graphUri = new URI(graphUri.getScheme(), graphUri.getSchemeSpecificPart(), null).normalize(); // strip the possible fragment identifier
            return post(model, false, graphUri);
        }
        catch (URISyntaxException ex)
        {
            // shouldn't happen
            throw new InternalServerErrorException(ex);
        }
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
    public Response postMultipart(FormDataMultiPart multiPart, @QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        if (log.isDebugEnabled()) log.debug("MultiPart fields: {} body parts: {}", multiPart.getFields(), multiPart.getBodyParts());

        try
        {
            Model model = parseModel(multiPart);
            MessageBodyReader<Model> reader = getProviders().getMessageBodyReader(Model.class, null, null, com.atomgraph.core.MediaType.APPLICATION_NTRIPLES_TYPE);
            if (reader instanceof SkolemizingModelProvider) model = ((SkolemizingModelProvider)reader).process(model);
            if (log.isDebugEnabled()) log.debug("POSTed Model size: {}", model.size());

            return postMultipart(model, defaultGraph, graphUri, getFileNameBodyPartMap(multiPart));
        }
        catch (URISyntaxException ex)
        {
            if (log.isErrorEnabled()) log.error("URI '{}' has syntax error in request with media type: {}", ex.getInput(), multiPart.getMediaType());
            throw new WebApplicationException(ex, Response.Status.BAD_REQUEST);
        }
    }
    
    public Response postMultipart(Model model, Boolean defaultGraph, URI graphUri, Map<String, FormDataBodyPart> fileNameBodyPartMap)
    {
        if (model == null) throw new IllegalArgumentException("Model cannot be null");
        if (fileNameBodyPartMap == null) throw new IllegalArgumentException("Map<String, FormDataBodyPart> cannot be null");
        
//        Resource itemClass = getOntology().getOntModel().getOntClass(getUriInfo().getBaseUri().resolve("ns/domain/default#Item").toString()); // TO-DO: make class URI configurable?
//        if (itemClass == null) throw new IllegalStateException("nsdd:Item class not found in the application ontology");
//        Resource container = null; // for uploaded triples/quads
        
        int count = 0;
        ResIterator resIt = model.listResourcesWithProperty(NFO.fileName);
        try
        {
            while (resIt.hasNext())
            {
                Resource file = resIt.next();
                String fileName = file.getProperty(NFO.fileName).getString();
                FormDataBodyPart bodyPart = fileNameBodyPartMap.get(fileName);
                
//                if (getTemplateCall().get().hasArgument(APLT.upload)) // upload RDF data
//                {
//                    container = file.getPropertyResourceValue(SIOC.HAS_CONTAINER);
//
//                    MediaType mediaType = null;
//                    if (file.hasProperty(DCTerms.format)) mediaType = com.atomgraph.linkeddatahub.MediaType.valueOf(file.getPropertyResourceValue(DCTerms.format));
//                    if (mediaType != null) bodyPart.setMediaType(mediaType);
//
//                    Model partModel = bodyPart.getValueAs(Model.class);
//                    partModel = processExternalResources(partModel, container, itemClass);
//                    post(partModel); // append uploaded triples/quads
//                }
//                else // write file
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
        
//        if (container != null)
//        {
//            if (log.isDebugEnabled()) log.debug("Redirecting to container: {} ", container.getURI());
//            return Response.seeOther(URI.create(container.getURI())).build();
//        }
//        else
        {
            if (log.isDebugEnabled()) log.debug("# of files uploaded: {} ", count);
            return post(model, defaultGraph, graphUri);
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
     * Extracts the individual that is being created from the input RDF graph.
     * 
     * @param model RDF input graph
     * @param forClass RDF class
     * @return RDF resource
     */
    public Resource getForClassResource(Model model, Resource forClass)
    {
        if (model == null) throw new IllegalArgumentException("Model cannot be null");
        
        ResIterator it = model.listSubjectsWithProperty(RDF.type, forClass);
        try
        {
            if (it.hasNext())
            {
                Resource created = it.next();
                
                // handle creation of "things"- they are not documents themselves, so we return the attached document instead
//                if (created.hasProperty(FOAF.isPrimaryTopicOf))
//                    return created.getPropertyResourceValue(FOAF.isPrimaryTopicOf);
//                else
//                    return created;

                return created;
            }
        }
        finally
        {
            it.close();
        }
        
        return null;
    }
    
    public UriInfo getUriInfo()
    {
        return uriInfo;
    }
    
    public Providers getProviders()
    {
        return providers;
    }
    
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }
    
}