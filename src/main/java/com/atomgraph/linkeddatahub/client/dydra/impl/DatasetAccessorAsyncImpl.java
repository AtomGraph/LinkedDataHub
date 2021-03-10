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
package com.atomgraph.linkeddatahub.client.dydra.impl;

import com.atomgraph.core.exception.BadGatewayException;
import com.atomgraph.core.model.impl.remote.DatasetAccessorImpl;
import com.atomgraph.linkeddatahub.client.dydra.DatasetAccessorAsync;
import com.atomgraph.linkeddatahub.client.dydra.GraphStoreClient;
import javax.ws.rs.ClientErrorException;
import org.apache.jena.rdf.model.Model;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author Martynas Jusevičius <martynas@atomgraph.com>
 */
public class DatasetAccessorAsyncImpl extends DatasetAccessorImpl implements DatasetAccessorAsync
{

    private static final Logger log = LoggerFactory.getLogger(DatasetAccessorAsyncImpl.class);

    private final GraphStoreClient graphStoreClient;

    public DatasetAccessorAsyncImpl(GraphStoreClient graphStoreClient)
    {
        super(graphStoreClient);
        
        this.graphStoreClient = graphStoreClient;
    }

    @Override
    public void add(Model model, Mode mode)
    {
        try
        {
            getGraphStoreClient().add(model, mode);
        }
        catch (ClientErrorException ex)
        {
            if (log.isDebugEnabled()) log.debug("Graph Store backend client error", ex);
            throw new BadGatewayException(ex);
        }
    }

    @Override
    public void putModel(Model model, Mode mode)
    {
        try
        {
            getGraphStoreClient().putModel(model, mode);
        }
        catch (ClientErrorException ex)
        {
            if (log.isDebugEnabled()) log.debug("Graph Store backend client error", ex);
            throw new BadGatewayException(ex);
        }
    }

    @Override
    public void putModel(String uri, Model model, Mode mode)
    {
        try
        {
            getGraphStoreClient().putModel(uri, model, mode);
        }
        catch (ClientErrorException ex)
        {
            if (log.isDebugEnabled()) log.debug("Graph Store backend client error", ex);
            throw new BadGatewayException(ex);
        }
    }
    
    @Override
    public GraphStoreClient getGraphStoreClient()
    {
        return graphStoreClient;
    }

}
