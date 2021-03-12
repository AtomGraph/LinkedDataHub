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
package com.atomgraph.linkeddatahub.client.dydra;

import com.atomgraph.core.MediaTypes;
import static com.atomgraph.core.client.GraphStoreClient.DEFAULT_PARAM_NAME;
import static com.atomgraph.core.client.GraphStoreClient.GRAPH_PARAM_NAME;
import javax.ws.rs.NotFoundException;
import javax.ws.rs.client.WebTarget;
import javax.ws.rs.core.MultivaluedHashMap;
import javax.ws.rs.core.MultivaluedMap;
import javax.ws.rs.core.Response;
import org.apache.jena.rdf.model.Model;

/**
 * This client queues GSP requests so that we can avoid "Graph import failed" error on concurrent updates.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see <a href="https://api.dydra.com/graphstore/asynchronous.html">Asynchronous Processing</a>
 */
public class GraphStoreClient extends com.atomgraph.core.client.GraphStoreClient implements DatasetAccessorAsync
{
    
    protected GraphStoreClient(WebTarget endpoint, MediaTypes mediaTypes)
    {
        super(endpoint, mediaTypes);
    }

    protected GraphStoreClient(WebTarget endpoint)
    {
        this(endpoint, new MediaTypes());
    }

    public static GraphStoreClient create(WebTarget endpoint, MediaTypes mediaTypes)
    {
        return new GraphStoreClient(endpoint, mediaTypes);
    }

    public static GraphStoreClient create(WebTarget endpoint)
    {
        return new GraphStoreClient(endpoint);
    }

    @Override
    public void add(Model model, DatasetAccessorAsync.Mode mode)
    {
        MultivaluedHashMap headers = new MultivaluedHashMap();
        headers.add(mode.getHeaderName(), mode.getHeaderValue());
        
        MultivaluedMap<String, String> params = new MultivaluedHashMap();
        params.putSingle(DEFAULT_PARAM_NAME, Boolean.TRUE.toString());

        try (Response cr = post(model, getDefaultMediaType(), new javax.ws.rs.core.MediaType[]{}, params, headers))
        {
            // some endpoints might include response body which will not cause NotFoundException in Jersey
            if (cr.getStatus() == Response.Status.NOT_FOUND.getStatusCode()) throw new NotFoundException();
        }
    }

    @Override
    public void putModel(Model model, DatasetAccessorAsync.Mode mode)
    {
        MultivaluedHashMap headers = new MultivaluedHashMap();
        headers.add(mode.getHeaderName(), mode.getHeaderValue());

        MultivaluedMap<String, String> params = new MultivaluedHashMap();
        params.putSingle(DEFAULT_PARAM_NAME, Boolean.TRUE.toString());

        try (Response cr = put(model, getDefaultMediaType(), new javax.ws.rs.core.MediaType[]{}, params, headers))
        {
            // some endpoints might include response body which will not cause NotFoundException in Jersey
            if (cr.getStatus() == Response.Status.NOT_FOUND.getStatusCode()) throw new NotFoundException();
        }
    }
    
    public void putModel(String uri, Model model, DatasetAccessorAsync.Mode mode)
    {
        MultivaluedHashMap headers = new MultivaluedHashMap();
        headers.add(mode.getHeaderName(), mode.getHeaderValue());
        
        MultivaluedMap<String, String> params = new MultivaluedHashMap();
        params.putSingle(GRAPH_PARAM_NAME, uri);

        try (Response cr = put(model, getDefaultMediaType(), new javax.ws.rs.core.MediaType[]{}, params, headers))
        {
            // some endpoints might include response body which will not cause NotFoundException in Jersey
            if (cr.getStatus() == Response.Status.NOT_FOUND.getStatusCode()) throw new NotFoundException();
        }
    }
    
}
