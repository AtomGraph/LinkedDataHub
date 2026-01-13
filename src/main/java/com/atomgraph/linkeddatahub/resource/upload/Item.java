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
import com.atomgraph.linkeddatahub.server.model.impl.DirectGraphStoreImpl;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import java.util.Collections;
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
import jakarta.ws.rs.core.SecurityContext;
import jakarta.ws.rs.core.UriInfo;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.query.QueryFactory;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.DCTerms;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS resource that serves uploaded file data.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class Item extends DirectGraphStoreImpl
{
    private static final Logger log = LoggerFactory.getLogger(Item.class);
    
    private static final String ACCEPT_RANGES = "Accept-Ranges";
    private static final String BYTES_RANGE = "bytes";
    private static final String RANGE = "Range";
    private static final String CONTENT_RANGE = "Content-Range";
    private static final int CHUNK_SIZE = 1024 * 1024; // 1MB chunks

    private final Resource resource;
    private final HttpHeaders httpHeaders;
    
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
     * @param httpHeaders request headers
     */
    @Inject
    public Item(@Context Request request, @Context UriInfo uriInfo, MediaTypes mediaTypes,
            com.atomgraph.linkeddatahub.apps.model.Application application, Optional<Ontology> ontology, Optional<Service> service,
            @Context SecurityContext securityContext, Optional<AgentContext> agentContext,
            @Context Providers providers, com.atomgraph.linkeddatahub.Application system,
            @Context HttpHeaders httpHeaders)
    {
        super(request, uriInfo, mediaTypes, application, ontology, service, securityContext, agentContext, providers, system);
        this.resource = ModelFactory.createDefaultModel().createResource(uriInfo.getAbsolutePath().toString());
        if (log.isDebugEnabled()) log.debug("Constructing {}", getClass());
        this.httpHeaders = httpHeaders;
    }

    /**
     * Post-construct resource initialization.
     */
    @PostConstruct
    public void init()
    {
        getResource().getModel().add(describe());
    }
    
    @GET
    @Override
    public Response get()
    {
        return getResponseBuilder(getResource().getModel(), getURI()).build();
    }
    
    @Override
    public ResponseBuilder getResponseBuilder(Model model, URI graphUri)
    {
        // do not pass language list as languages do not apply to binary files
        List<Variant> variants = com.atomgraph.core.model.impl.Response.getVariants(getWritableMediaTypes(Model.class), Collections.emptyList(), getEncodings());
        Variant variant = getRequest().selectVariant(variants);
        if (variant == null)
        {
            if (log.isTraceEnabled()) log.trace("Requested Variant {} is not on the list of acceptable Response Variants: {}", variant, variants);
            throw new NotAcceptableException();
        }
        
        // respond with file content if Variant is compatible with the File's MediaType. otherwise, send RDF
        if (getMediaType().isCompatible(variant.getMediaType()))
        {
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
        
                    return super.getResponseBuilder(model, graphUri).
                        status(Status.PARTIAL_CONTENT).
                        entity(rangeOutput).
                        type(variant.getMediaType()).
                        lastModified(getLastModified(file)).
                        header(HttpHeaders.CONTENT_LENGTH, rangeOutput.getLength()). // should override Transfer-Encoding: chunked
                        header(ACCEPT_RANGES, BYTES_RANGE).
                        header(CONTENT_RANGE, contentRangeValue).
                        header("Content-Security-Policy", "default-src 'none'; sandbox"); // LNK-011 fix: prevent XSS in uploaded HTML files
                }
            }

            return super.getResponseBuilder(model, graphUri).
                entity(file).
                type(variant.getMediaType()).
                lastModified(getLastModified(file)).
                header(HttpHeaders.CONTENT_LENGTH, file.length()). // should override Transfer-Encoding: chunked
                header(ACCEPT_RANGES, BYTES_RANGE).
                header("Content-Security-Policy", "default-src 'none'; sandbox"); // LNK-011 fix: prevent XSS in uploaded HTML files
            //header("Content-Disposition", "attachment; filename=\"" + getRequiredProperty(NFO.fileName).getString() + "\"").
        }
        
        return super.getResponseBuilder(model, graphUri);
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
    
    @Override
    public EntityTag getEntityTag(Model model)
    {
        return null; // disable ETag based on Model hash
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
    
    @Override
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
     * Returns RDF resource of this file.
     * 
     * @return RDF resource
     */
    public Resource getResource()
    {
        return resource;
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