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

import com.atomgraph.client.util.DataManager;
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
   
    private final String uri;
    private final javax.ws.rs.core.MediaType[] mediaTypes;
    private final DataManager dataManager;
    
    public ClientResponseSupplier(String uri, javax.ws.rs.core.MediaType[] mediaTypes, DataManager dataManager)
    {
        this.uri = uri;
        this.mediaTypes = mediaTypes;
        this.dataManager = dataManager;
    }

    @Override
    public Response get()
    {
        return getDataManager().get(getURI(), getMediaTypes());
    }

    public String getURI()
    {
        return uri;
    }

    public javax.ws.rs.core.MediaType[] getMediaTypes()
    {
        return mediaTypes;
    }

    public DataManager getDataManager()
    {
        return dataManager;
    }
    
}
