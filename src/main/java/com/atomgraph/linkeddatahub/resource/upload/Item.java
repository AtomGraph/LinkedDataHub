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
package com.atomgraph.linkeddatahub.resource.upload;

import java.io.File;
import java.io.FileNotFoundException;
import java.net.URI;
import java.util.List;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.Response.ResponseBuilder;
import jakarta.ws.rs.core.Variant;
import jakarta.ws.rs.ext.Providers;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.io.FileRangeOutput;
import java.util.Date;
import java.util.Optional;
import jakarta.annotation.PostConstruct;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.NotAcceptableException;
import jakarta.ws.rs.NotFoundException;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.EntityTag;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Response.Status;
import jakarta.ws.rs.core.UriInfo;
import jakarta.ws.rs.core.Variant.VariantListBuilder;
import org.apache.jena.query.QueryFactory;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.sparql.vocabulary.FOAF;
import org.apache.jena.vocabulary.DCTerms;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS resource that serves uploaded file data.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class Item
{
    
    private static final Logger log = LoggerFactory.getLogger(Item.class);
    
    private static final String ACCEPT_RANGES = "Accept-Ranges";
    private static final String BYTES_RANGE = "bytes";
    private static final String RANGE = "Range";
    private static final String CONTENT_RANGE = "Content-Range";
    private static final int CHUNK_SIZE = 1024 * 1024; // 1MB chunks

    private final Request request;
    private final UriInfo uriInfo;
    private final Service service;
    private final Resource resource;
    private final com.atomgraph.linkeddatahub.Application system;
    private final HttpHeaders httpHeaders;
    
    /**
     * Constructs resource.
     * 
     * @param request current request
     * @param uriInfo URI information of the current request
     * @param mediaTypes a registry of readable/writable media types
     * @param service SPARQL service of the current application
     * @param providers JAX-RS provider registry
     * @param system system application
     * @param httpHeaders request headers
     */
    @Inject
    public Item(@Context Request request, @Context UriInfo uriInfo, MediaTypes mediaTypes,
            Optional<Service> service,
            @Context Providers providers, com.atomgraph.linkeddatahub.Application system,
            @Context HttpHeaders httpHeaders)
    {
        this.request = request;
        this.uriInfo = uriInfo;
        this.service = service.get();
        this.resource = ModelFactory.createDefaultModel().createResource(uriInfo.getAbsolutePath().toString());
        this.system = system;
        this.httpHeaders = httpHeaders;
        if (log.isDebugEnabled()) log.debug("Constructing {}", getClass());
    }

    /**
     * Post-construct resource initialization.
     */
    @PostConstruct
    public void init()
    {
        getResource().getModel().add(describe());
    }

    /**
     * Handles GET requests for uploaded files.
     * Evaluates HTTP preconditions and serves file content with appropriate Content-Security-Policy headers.
     *
     * @return HTTP response with file content or 304 Not Modified
     */
    @GET
    public Response get()
    {
        return getResponseBuilder(getResource().getModel(), getURI()).build();
    }

    /**
     * Builds HTTP response for file requests.
     * Handles content negotiation, HTTP precondition evaluation (ETag-based caching),
     * byte-range requests, and applies Content-Security-Policy headers.
     *
     * @param model RDF model describing the file
     * @param graphUri the graph URI (not used for binary file responses)
     * @return response builder configured for file serving
     */
    public ResponseBuilder getResponseBuilder(Model model, URI graphUri)
    {
        // do not pass language list as languages do not apply to binary files
        List<Variant> variants = VariantListBuilder.newInstance().mediaTypes(getMediaType()).build();
        Variant variant = getRequest().selectVariant(variants);
        if (variant == null || !getMediaType().isCompatible(variant.getMediaType()))
        {
            if (log.isTraceEnabled()) log.trace("Requested Variant {} is not on the list of acceptable Response Variants: {}", variant, variants);
            throw new NotAcceptableException();
        }
        
        EntityTag entityTag = getEntityTag();
        ResponseBuilder rb = getRequest().evaluatePreconditions(entityTag);
        if (rb != null) return rb; // file not modified
        
        URI fileURI = getSystem().getUploadRoot().resolve(getUriInfo().getPath());
        File file = new File(fileURI);

        if (!file.exists()) throw new NotFoundException(new FileNotFoundException("File '" + getUriInfo().getPath() + "' not found"));

        if (getHttpHeaders().getRequestHeaders().containsKey(RANGE))
        {
            String range = getHttpHeaders().getHeaderString(RANGE);

//                if (getHttpHeaders().getRequestHeaders().containsKey(IF_RANGE)) {
//                    String ifRangeHeader = getHttpHeaders().getHeaderString(IF_RANGE);
//
//                    EntityTag tag = getEntityTag(model);
//                    if (tag != null && tag.equals(EntityTag.valueOf(ifRangeHeader))) {
//                        //this.applyFilter(requestContext, responseContext);
//    //                    return;
//                    }
////                    Date lastModified = getLastModified(file);
////                    if (lastModified != null && lastModified.equals(ifRangeHeader)) {
////    //                    this.applyFilter(requestContext, responseContext);
////    //                    return;
////                    }
//                }
//                else
            {
                FileRangeOutput rangeOutput = getFileRangeOutput(file, range);
                final long to = rangeOutput.getLength() + rangeOutput.getFrom();
                String contentRangeValue = String.format("bytes %d-%d/%d", rangeOutput.getFrom(), to - 1, rangeOutput.getFile().length());

                return Response.status(Status.PARTIAL_CONTENT).
                    entity(rangeOutput).
                    type(variant.getMediaType()).
                    tag(entityTag).
                    lastModified(getLastModified(file)).
                    header(HttpHeaders.CONTENT_LENGTH, rangeOutput.getLength()). // should override Transfer-Encoding: chunked
                    header(ACCEPT_RANGES, BYTES_RANGE).
                    header(CONTENT_RANGE, contentRangeValue).
                    header("Content-Security-Policy", "default-src 'none'; sandbox"); // LNK-011 fix: prevent XSS in uploaded HTML files
            }
        }

        return Response.ok().
            entity(file).
            type(variant.getMediaType()).
            tag(entityTag).
            lastModified(getLastModified(file)).
            header(HttpHeaders.CONTENT_LENGTH, file.length()). // should override Transfer-Encoding: chunked
            header(ACCEPT_RANGES, BYTES_RANGE).
            header("Content-Security-Policy", "default-src 'none'; sandbox"); // LNK-011 fix: prevent XSS in uploaded HTML files
        //header("Content-Disposition", "attachment; filename=\"" + getRequiredProperty(NFO.fileName).getString() + "\"").
    }

    /**
     * Returns streaming output of a byte range from the given file.
     * 
     * @param file input file
     * @param range range string (integers separated with a dash)
     * @return file's RDF model
     */
    public FileRangeOutput getFileRangeOutput(File file, String range)
    {
        final String[] ranges = range.split("=")[1].split("-");

        final long from = Long.parseLong(ranges[0]);
        if (from >= file.length())
        {
            if (log.isTraceEnabled()) log.trace("Content range '{}': start was after end of file, nothing to return", range);
            throw new WebApplicationException(Response.status(Response.Status.REQUESTED_RANGE_NOT_SATISFIABLE).
                    header(CONTENT_RANGE, "bytes */" + file.length()).
                    build());
        }

        long to;

        if (ranges.length == 2)
        {
            // the header specifies that last included byte so we increase by one for easier handling
            to = Long.parseLong(ranges[1]) + 1;

            if (to < from)
            {
                if (log.isTraceEnabled()) log.trace("Content range '{}': to was smaller than from", range);
                throw new WebApplicationException(Response.status(Response.Status.REQUESTED_RANGE_NOT_SATISFIABLE).
                        header(CONTENT_RANGE, "bytes */" + file.length()).
                        build());
            }
        } 
        else
        {
            // use default range if the range upper bound is unspecified. Chrome sends "bytes=0-"
            to = CHUNK_SIZE + from;
        }

        if (to > file.length())
        {
            if (log.isTraceEnabled()) log.trace("Content range '{}': to was greater than possible, limit to max length", range);
            to = file.length();
        }

        final long length = to - from;
        return new FileRangeOutput(file, from, length);
    }

    /**
     * Returns the ETag for HTTP caching based on the file's SHA1 hash.
     *
     * @return entity tag for cache validation
     */
    public EntityTag getEntityTag()
    {
        return new EntityTag(getSHA1Hash(getResource()));
    }
    
    /**
     * Returns the last modification date for the given file.
     * 
     * @param file input file
     * @return last modification date
     */
    protected Date getLastModified(File file)
    {
        return new Date(file.lastModified());
    }
    
    /**
     * Returns the media type of this file.
     * 
     * @return media type
     */
    public jakarta.ws.rs.core.MediaType getMediaType()
    {
        Resource format = getResource().getPropertyResourceValue(DCTerms.format);
        if (format == null)
        {
            if (log.isErrorEnabled()) log.error("File '{}' does not have a media type", getResource());
            throw new IllegalStateException("File does not have a media type (dct:format)");
        }
        
        return com.atomgraph.linkeddatahub.MediaType.valueOf(format);
    }

    /**
     * Returns the list of media types that can be used to write this file's content.
     *
     * @param clazz the class type (not used, file has single media type)
     * @return list containing the file's media type
     */
    public List<jakarta.ws.rs.core.MediaType> getWritableMediaTypes(Class clazz)
    {
        return List.of(getMediaType());
    }
    
    /**
     * Returns file's RDF description using SPARQL query.
     * 
     * @return file's RDF model
     */
    public Model describe()
    {
        // TO-DO: can we avoid hardcoding the query string here?
        return getService().getSPARQLClient().loadModel(QueryFactory.create("DESCRIBE <" + getURI() + ">"));
    }
    
    /**
     * Returns SHA1 property value of the specified resource.
     * 
     * @param resource RDF resource
     * @return SHA1 hash string
     */
    public String getSHA1Hash(Resource resource)
    {
        return resource.getRequiredProperty(FOAF.sha1).getString();
    }

    /**
     * Returns the absolute URI of this file resource.
     *
     * @return the file's URI
     */
    public URI getURI()
    {
        return getUriInfo().getAbsolutePath();
    }

    /**
     * Returns the current JAX-RS request.
     *
     * @return request object
     */
    public Request getRequest()
    {
        return request;
    }

    /**
     * Returns the URI information of the current request.
     *
     * @return URI info
     */
    public UriInfo getUriInfo()
    {
        return uriInfo;
    }

    /**
     * Returns the SPARQL service of the current application.
     *
     * @return SPARQL service
     */
    public Service getService()
    {
        return service;
    }
    
    /**
     * Returns RDF resource of this file.
     * 
     * @return RDF resource
     */
    public Resource getResource()
    {
        return resource;
    }

    /**
     * Returns the system application instance.
     *
     * @return system application
     */
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }

    /**
     * Returns HTTP headers of the current request.
     * 
     * @return header info
     */
    public HttpHeaders getHttpHeaders()
    {
        return httpHeaders;
    }
    
}