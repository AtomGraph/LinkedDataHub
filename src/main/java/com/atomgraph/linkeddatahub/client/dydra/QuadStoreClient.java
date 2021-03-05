package com.atomgraph.linkeddatahub.client.dydra;

import com.atomgraph.core.MediaTypes;
import javax.ws.rs.client.WebTarget;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.MultivaluedHashMap;
import org.apache.jena.query.Dataset;

/**
 * This client queues GSP requests so that we can avoid "Graph import failed" error on concurrent updates.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see <a href="https://api.dydra.com/graphstore/asynchronous.html">Asynchronous Processing</a>
 */
public class QuadStoreClient extends com.atomgraph.core.client.QuadStoreClient implements DatasetAccessorAsync
{

    public QuadStoreClient(WebTarget endpoint, MediaTypes mediaTypes)
    {
        super(endpoint, mediaTypes);
    }

    public QuadStoreClient(WebTarget endpoint)
    {
        this(endpoint, new MediaTypes());
    }

    public static QuadStoreClient create(WebTarget endpoint, MediaTypes mediaTypes)
    {
        return new QuadStoreClient(endpoint, mediaTypes);
    }

    public static QuadStoreClient create(WebTarget endpoint)
    {
        return new QuadStoreClient(endpoint);
    }
    
//    @Override
//    public void add(Dataset dataset)
//    {
//        add(dataset, DatasetAccessorAsync.Mode.NOTIFY);
//    }
    ;
    public void add(Dataset dataset, DatasetAccessorAsync.Mode mode)
    {
        MultivaluedHashMap headers = new MultivaluedHashMap();
        headers.add(mode.getHeaderName(), mode.getHeaderValue());
        
        post(dataset, getDefaultMediaType(), new MediaType[]{}, new MultivaluedHashMap(), headers).close();
    }

//    @Override
//    public void replace(Dataset dataset)
//    {
//        replace(dataset, DatasetAccessorAsync.Mode.NOTIFY);
//    }

    public void replace(Dataset dataset, DatasetAccessorAsync.Mode mode)
    {
        MultivaluedHashMap headers = new MultivaluedHashMap();
        headers.add(mode.getHeaderName(), mode.getHeaderValue());

        put(dataset, getDefaultMediaType(), new MediaType[]{}, new MultivaluedHashMap(), headers).close();
    }

}
