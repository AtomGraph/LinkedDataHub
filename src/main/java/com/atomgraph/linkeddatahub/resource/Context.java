/**
 *  Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.resource;

import com.atomgraph.client.util.HTMLMediaTypePredicate;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.server.util.EntityTags;
import com.atomgraph.linkeddatahub.server.util.PublicContext;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.core.CacheControl;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import java.util.ArrayList;
import org.apache.jena.rdf.model.Model;

/**
 * JAX-RS resource serving the public dataspace context: every dataspace of this deployment, its type, title, origin,
 * ontology and stylesheet, and the <code>lds:admin</code> pairing of each end-user dataspace.
 * <p>
 * Served at <code>/context</code> on every dataspace and readable by anyone, since {@link PublicContext} withholds the
 * services and credentials the context dataset also holds. The client-side stylesheet preloads it, and HTTP clients
 * dereference it like any other document.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class Context
{

    private final com.atomgraph.linkeddatahub.Application system;
    private final MediaTypes mediaTypes;
    private final Request request;
    private final UriInfo uriInfo;

    /**
     * Constructs the context resource.
     *
     * @param system the system application
     * @param mediaTypes registry of the media types models are written in
     * @param request JAX-RS request context
     * @param uriInfo request URI information
     */
    @Inject
    public Context(com.atomgraph.linkeddatahub.Application system, MediaTypes mediaTypes, @jakarta.ws.rs.core.Context Request request, @jakarta.ws.rs.core.Context UriInfo uriInfo)
    {
        this.system = system;
        this.mediaTypes = mediaTypes;
        this.request = request;
        this.uriInfo = uriInfo;
    }

    /**
     * Returns the public dataspace context.
     * The context changes at runtime (a new dataspace, a settings update), so caches revalidate it on every use.
     *
     * @return the context as RDF
     */
    @GET
    public Response get()
    {
        Model context = PublicContext.of(getSystem().getContextModel(), getSystem().isEnableAssistant());
        CacheControl cacheControl = new CacheControl();
        cacheControl.setNoCache(true);

        // negotiated, conditional and Vary-ing the way the documents' responses are
        return new com.atomgraph.core.model.impl.Response(getRequest(),
                context,
                null,
                EntityTags.entityTag(getUriInfo().getAbsolutePath(), context),
                getMediaTypes().getWritable(Model.class),
                getSystem().getSupportedLanguages(),
                new ArrayList<>(),
                new HTMLMediaTypePredicate()).
            getResponseBuilder().
            cacheControl(cacheControl).
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
     * Returns the registry of the media types models are written in.
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

    /**
     * Returns the request URI information.
     *
     * @return URI info
     */
    public UriInfo getUriInfo()
    {
        return uriInfo;
    }

}
