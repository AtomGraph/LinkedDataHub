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
package com.atomgraph.linkeddatahub.dataspaces.model.end_user.impl;

import com.atomgraph.linkeddatahub.dataspaces.model.AdminDataspace;
import com.atomgraph.linkeddatahub.dataspaces.model.EndUserDataspace;
import java.net.URI;
import org.apache.jena.enhanced.EnhGraph;
import org.apache.jena.graph.Node;
import org.apache.jena.rdf.model.ResIterator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.atomgraph.linkeddatahub.vocabulary.LDS;

/**
 * End-user application implementation.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class EndUserDataspaceImpl extends com.atomgraph.linkeddatahub.dataspaces.model.impl.DataspaceImpl implements EndUserDataspace
{

    private static final Logger log = LoggerFactory.getLogger(EndUserDataspaceImpl.class);

    /**
     * Constructs instance from node and graph.
     * 
     * @param n node
     * @param g graph
     */
    public EndUserDataspaceImpl(Node n, EnhGraph g)
    {
        super(n, g);
    }
    
    @Override
    public AdminDataspace getAdminDataspace()
    {
        URI originURI = getOriginURI();
        if (originURI == null) return null;

        // derive admin origin by prepending "admin." to the host
        String adminHost = "admin." + originURI.getHost();
        URI adminOrigin = URI.create(originURI.getScheme() + "://" + adminHost +
            (originURI.getPort() != -1 ? ":" + originURI.getPort() : ""));

        ResIterator it = getModel().listSubjectsWithProperty(LDS.origin,
            getModel().createResource(adminOrigin.toString()));
        try
        {
            if (it.hasNext()) return it.next().as(AdminDataspace.class);
        }
        finally
        {
            it.close();
        }

        return null;
    }
    
}
