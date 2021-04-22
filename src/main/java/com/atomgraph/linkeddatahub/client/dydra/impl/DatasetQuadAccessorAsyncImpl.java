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
import com.atomgraph.core.model.impl.remote.DatasetQuadAccessorImpl;
import com.atomgraph.linkeddatahub.client.dydra.DatasetQuadAccessorAsync;
import com.atomgraph.linkeddatahub.client.dydra.QuadStoreClient;
import javax.ws.rs.ClientErrorException;
import org.apache.jena.query.Dataset;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class DatasetQuadAccessorAsyncImpl extends DatasetQuadAccessorImpl implements DatasetQuadAccessorAsync
{

    private static final Logger log = LoggerFactory.getLogger(DatasetQuadAccessorAsyncImpl.class);

    private final QuadStoreClient quadStoreClient;
    
    public DatasetQuadAccessorAsyncImpl(QuadStoreClient quadStoreClient)
    {
        super(quadStoreClient);
        
        this.quadStoreClient = quadStoreClient;
    }

    @Override
    public void add(Dataset dataset, Mode mode)
    {
        try
        {
            getQuadStoreClient().add(dataset, mode);
        }
        catch (ClientErrorException ex)
        {
            if (log.isDebugEnabled()) log.debug("Graph Store backend client error", ex);
            throw new BadGatewayException(ex);
        }
    }

    @Override
    public void replace(Dataset dataset, Mode mode)
    {
        try
        {
            getQuadStoreClient().replace(dataset, mode);
        }
        catch (ClientErrorException ex)
        {
            if (log.isDebugEnabled()) log.debug("Graph Store backend client error", ex);
            throw new BadGatewayException(ex);
        }
    }
    
    @Override
    public QuadStoreClient getQuadStoreClient()
    {
        return quadStoreClient;
    }
    
}
