/**
 *  Copyright 2022 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.apps.model.impl;

import com.atomgraph.linkeddatahub.apps.model.Dataset;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import com.atomgraph.processor.vocabulary.LDT;
import java.net.URI;
import javax.ws.rs.core.UriBuilder;
import org.apache.jena.enhanced.EnhGraph;
import org.apache.jena.graph.Node;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.impl.ResourceImpl;

/**
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class DatasetImpl extends ResourceImpl implements Dataset
{

    public DatasetImpl(Node n, EnhGraph g)
    {
        super(n, g);
    }
        
    @Override
    public Resource getBase()
    {
        return getPropertyResourceValue(LDT.base);
    }
    
    @Override
    public URI getBaseURI()
    {
        if (getBase() != null) return URI.create(getBase().getURI());
        
        return null;
    }

    @Override
    public Resource getPrefix()
    {
        return getPropertyResourceValue(LAPP.prefix);
    }

    @Override
    public Resource getProxy()
    {
        return getPropertyResourceValue(LAPP.proxy);
    }

    public URI getProxyURI()
    {
        if (getProxy() != null) return URI.create(getProxy().getURI());
        
        return null;
    }
    
    @Override
    public URI getProxied(URI uri)
    {
        return UriBuilder.fromUri(uri).
            scheme(getProxyURI().getScheme()).
            host(getProxyURI().getHost()).
            port(getProxyURI().getPort()).
            build();
    }
    
}
