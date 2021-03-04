package com.atomgraph.linkeddatahub.client.dydra;

import com.atomgraph.core.MediaTypes;
import javax.ws.rs.client.WebTarget;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.MultivaluedHashMap;
import org.apache.jena.query.Dataset;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
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
    
    public void add(Dataset dataset, DatasetAccessorAsync.Mode mode)
    {
        MultivaluedHashMap headers = new MultivaluedHashMap();
        headers.add(mode.getHeaderName(), mode.getHeaderValue());
        
        post(dataset, getDefaultMediaType(), new MediaType[]{}, new MultivaluedHashMap(), headers).close();
    }

    public void replace(Dataset dataset, DatasetAccessorAsync.Mode mode)
    {
        MultivaluedHashMap headers = new MultivaluedHashMap();
        headers.add(mode.getHeaderName(), mode.getHeaderValue());

        put(dataset, getDefaultMediaType(), new MediaType[]{}, new MultivaluedHashMap(), headers).close();
    }
    
}
