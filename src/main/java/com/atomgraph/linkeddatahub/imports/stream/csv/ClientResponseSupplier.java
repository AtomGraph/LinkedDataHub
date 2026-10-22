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
package com.atomgraph.linkeddatahub.imports.stream.csv;

import com.atomgraph.linkeddatahub.client.GraphStoreClient;
import com.atomgraph.linkeddatahub.client.RedirectingClient;
import java.net.URI;
import java.util.function.Supplier;
import jakarta.ws.rs.core.Response;
import org.apache.jena.rdf.model.Model;

/**
 * Client response supplier.
 * Used when composing asynchronous data import.
 * Follows redirects, validating every hop.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see com.atomgraph.linkeddatahub.listener.ImportListener
 */
public class ClientResponseSupplier implements Supplier<Response>
{

    private final GraphStoreClient gsc;
    private final RedirectingClient redirectingClient;
    private final jakarta.ws.rs.core.MediaType[] mediaTypes;
    private final URI uri;

    /**
     * Constructs supplier from request URI and media types.
     *
     * @param gsc Graph Store client
     * @param redirectingClient follows and validates redirects
     * @param mediaTypes accepted media types
     * @param uri request URI, validated by the caller
     */
    public ClientResponseSupplier(GraphStoreClient gsc, RedirectingClient redirectingClient, jakarta.ws.rs.core.MediaType[] mediaTypes, URI uri)
    {
        this.gsc = gsc;
        this.redirectingClient = redirectingClient;
        this.mediaTypes = mediaTypes;
        this.uri = uri;
    }

    /**
     * Constructs supplier from request URI.
     *
     * @param gsc Graph Store client
     * @param redirectingClient follows and validates redirects
     * @param uri request URI, validated by the caller
     */
    public ClientResponseSupplier(GraphStoreClient gsc, RedirectingClient redirectingClient, URI uri)
    {
        this(gsc, redirectingClient, null, uri);
    }

    @Override
    public Response get()
    {
        jakarta.ws.rs.core.MediaType[] acceptedTypes = getMediaTypes() != null ? getMediaTypes() : getGraphStoreClient().getReadableMediaTypes(Model.class);

        return getGraphStoreClient().get(getRedirectingClient(), getURI(), acceptedTypes).response();
    }

    /**
     * Returns request URI.
     *
     * @return URI
     */
    public URI getURI()
    {
        return uri;
    }

    /**
     * Returns readable/writable media types or null.
     *
     * @return media type array or null
     */
    public jakarta.ws.rs.core.MediaType[] getMediaTypes()
    {
        return mediaTypes;
    }

    /**
     * Returns Graph Store client.
     *
     * @return manager instance
     */
    public GraphStoreClient getGraphStoreClient()
    {
        return gsc;
    }

    /**
     * Returns the client that follows redirects.
     *
     * @return redirecting client
     */
    public RedirectingClient getRedirectingClient()
    {
        return redirectingClient;
    }

}
