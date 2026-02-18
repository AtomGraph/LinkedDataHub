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
package com.atomgraph.linkeddatahub.model.impl;

import com.atomgraph.core.vocabulary.A;
import com.atomgraph.core.vocabulary.SD;
import com.atomgraph.linkeddatahub.model.Service;
import org.apache.jena.enhanced.EnhGraph;
import org.apache.jena.graph.Node;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.Statement;
import org.apache.jena.rdf.model.impl.ResourceImpl;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * SPARQL service implementation.
 * Pure data accessor — describes what a service is (endpoints, credentials) without
 * any infrastructure concerns (HTTP clients, proxy routing).
 * Use {@link com.atomgraph.linkeddatahub.model.ServiceContext} to build clients.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ServiceImpl extends ResourceImpl implements Service
{

    private static final Logger log = LoggerFactory.getLogger(ServiceImpl.class);

    /**
     * Constructs instance from node and graph.
     *
     * @param n node
     * @param g graph
     */
    public ServiceImpl(Node n, EnhGraph g)
    {
        super(n, g);
    }

    @Override
    public Resource getSPARQLEndpoint()
    {
        return getPropertyResourceValue(SD.endpoint);
    }

    @Override
    public Resource getGraphStore()
    {
        return getPropertyResourceValue(A.graphStore);
    }

    @Override
    public Resource getQuadStore()
    {
        return getPropertyResourceValue(A.quadStore);
    }

    @Override
    public String getAuthUser()
    {
        Statement authUser = getProperty(A.authUser);
        if (authUser != null) return authUser.getString();

        return null;
    }

    @Override
    public String getAuthPwd()
    {
        Statement authPwd = getProperty(A.authPwd);
        if (authPwd != null) return authPwd.getString();

        return null;
    }

}
