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

import com.atomgraph.core.client.LinkedDataClient;
import java.net.URI;
import java.util.function.Supplier;
import javax.ws.rs.core.Response;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Client response supplier.
 * Used when composing asynchronous data import.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see com.atomgraph.linkeddatahub.listener.ImportListener
 */
public class ClientResponseSupplier implements Supplier<Response>
{

    private static final Logger log = LoggerFactory.getLogger(ClientResponseSupplier.class);
   
    private final LinkedDataClient ldc;
    private final javax.ws.rs.core.MediaType[] mediaTypes;
    private final URI uri;

    /**
     * Constructs supplier from request URI and media types.
     * 
     * @param uri request URI
     * @param mediaTypes registry of media types
     * @param ldc Linked Data client
     */
    public ClientResponseSupplier(LinkedDataClient ldc, javax.ws.rs.core.MediaType[] mediaTypes, URI uri)
    {
        this.ldc = ldc;
        this.mediaTypes = mediaTypes;
        this.uri = uri;
    }

    /**
     * Constructs supplier from request URI.
     * 
     * @param uri request URI
     * @param ldc Linked Data client
     */
    public ClientResponseSupplier(LinkedDataClient ldc, URI uri)
    {
        this(ldc, null, uri);
    }
    
    @Override
    public Response get()
    {
        if (getMediaTypes() != null) return getLinkedDataClient().get(getURI(), getMediaTypes());
        
        return getLinkedDataClient().get(getURI());
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
    public javax.ws.rs.core.MediaType[] getMediaTypes()
    {
        return mediaTypes;
    }

    /**
     * Returns Linked Data client.
     * 
     * @return manager instance
     */
    public LinkedDataClient getLinkedDataClient()
    {
        return ldc;
    }
    
}
