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
package com.atomgraph.linkeddatahub.apps.model.admin.impl;

import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.vocabulary.Admin;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import org.apache.jena.enhanced.EnhGraph;
import org.apache.jena.graph.Node;
import org.apache.jena.rdf.model.Resource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Administrative application implementation.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ApplicationImpl extends com.atomgraph.linkeddatahub.apps.model.impl.ApplicationImpl implements AdminApplication
{

    private static final Logger log = LoggerFactory.getLogger(ApplicationImpl.class);
    
    /**
     * Constructs instance from node and graph.
     * 
     * @param n node
     * @param g graph
     */
    public ApplicationImpl(Node n, EnhGraph g)
    {
        super(n, g);
    }

    @Override
    public EndUserApplication getEndUserApplication()
    {
        Resource app = getPropertyResourceValue(LAPP.endUserApplication);
        if (app != null) return app.as(EndUserApplication.class);
        
        return null;
    }
    
    @Override
    public Resource getOntology()
    {
        return Admin.NAMESPACE;
    }
    
}
