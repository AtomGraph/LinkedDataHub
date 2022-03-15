/**
 *  Copyright 2020 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.client;

import com.atomgraph.core.MediaTypes;
import static com.atomgraph.linkeddatahub.client.GraphStoreClient.GRAPH_PARAM_NAME;
import javax.ws.rs.NotFoundException;
import javax.ws.rs.client.WebTarget;
import javax.ws.rs.core.MultivaluedHashMap;
import javax.ws.rs.core.MultivaluedMap;
import javax.ws.rs.core.Response;
import org.apache.jena.rdf.model.Model;

/**
 * SPARQL Graph Store Protocol client.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class GraphStoreClient extends com.atomgraph.core.client.GraphStoreClient
{
    
    protected GraphStoreClient(WebTarget endpoint, MediaTypes mediaTypes)
    {
        super(endpoint, mediaTypes);
    }

    protected GraphStoreClient(WebTarget endpoint)
    {
        this(endpoint, new MediaTypes());
    }

    /**
     * Creates client from the specified endpoint URI and media types.
     * 
     * @param endpoint target endpoint URI
     * @param mediaTypes registry of readable/writable media types
     * @return client
     */
    public static GraphStoreClient create(WebTarget endpoint, MediaTypes mediaTypes)
    {
        return new GraphStoreClient(endpoint, mediaTypes);
    }

    /**
     * Creates client from the specified endpoint.
     * 
     * @param endpoint target endpoint URI
     * @return client
     */
    public static GraphStoreClient create(WebTarget endpoint)
    {
        return new GraphStoreClient(endpoint);
    }

    @Override
    public void add(String uri, Model model)
    {
        MultivaluedMap<String, String> params = new MultivaluedHashMap();
        if (uri != null) params.putSingle(GRAPH_PARAM_NAME, uri); // graph name is optional during POST

        try (Response cr = post(model, getDefaultMediaType(), new javax.ws.rs.core.MediaType[]{}, params))
        {
            // some endpoints might include response body which will not cause NotFoundException in Jersey
            if (cr.getStatus() == Response.Status.NOT_FOUND.getStatusCode()) throw new NotFoundException();
        }
    }
    
}
