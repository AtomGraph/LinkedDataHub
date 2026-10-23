/**
 *  Copyright 2025 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.server.util;

import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.linkeddatahub.vocabulary.LACL;
import com.atomgraph.linkeddatahub.vocabulary.LDS;
import com.atomgraph.spinrdf.vocabulary.SPIN;
import java.util.function.Supplier;
import org.apache.jena.query.QuerySolutionMap;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.RDFS;

/**
 * Authorization query solution supplier.
 * 
 * @author Martynas.Jusevicius
 */
public class AuthorizationParams implements Supplier<QuerySolutionMap>
{

    private final Resource base, absolutePath, agent;
    private final boolean owner;
    
    /**
     * Constructs authorization query solution supplier.
     * <em>Does not set <samp>$mode</samp> value intentionally as we want to provide the {@link com.atomgraph.linkeddatahub.server.security.AuthorizationContext} with all of the agent's authorizations.</em>
     * 
     * @param base application's base URI
     * @param absolutePath request URL without query string
     * @param agent agent resource or null
     * @param owner whether the agent owns the document the decision is about, which makes it a <code>lacl:OwnerAgent</code>
     */
    public AuthorizationParams(Resource base, Resource absolutePath, Resource agent, boolean owner)
    {
        this.base = base;
        this.absolutePath = absolutePath;
        this.agent = agent;
        this.owner = agent != null && owner;
    }

     /**
     * Builds solution map for the authorization query.
     * 
     * @return solution map
     */
    @Override
    public QuerySolutionMap get()
    {
        QuerySolutionMap qsm = new QuerySolutionMap();
        qsm.add(SPIN.THIS_VAR_NAME, getAbsolutePath());
        qsm.add(LDS.base.getLocalName(), getBase());
        
        if (getAgent() != null)
        {
            qsm.add("AuthenticatedAgentClass", ACL.AuthenticatedAgent); // enable AuthenticatedAgent UNION branch
            qsm.add("agent", getAgent());
        }
        else
        {
            qsm.add("AuthenticatedAgentClass", RDFS.Resource); // disable AuthenticatedAgent UNION branch
            qsm.add("agent", RDFS.Resource); // disables UNION branch with $agent
        }
        qsm.add("OwnerAgentClass", isOwner() ? LACL.OwnerAgent : RDFS.Resource); // enable lacl:OwnerAgent UNION branch for the owner only
        
        return qsm;
    }

    /**
     * Gets the base resource for authorization.
     * 
     * @return the base resource
     */
    public Resource getBase()
    {
        return base;
    }

    /**
     * Gets the absolute path resource for authorization.
     * 
     * @return the absolute path resource
     */
    public Resource getAbsolutePath()
    {
        return absolutePath;
    }

    /**
     * Gets the agent resource for authorization.
     * 
     * @return the agent resource
     */
    public Resource getAgent()
    {
        return agent;
    }

    /**
     * Returns true if the agent owns the document the decision is about.
     * 
     * @return true for the owner
     */
    public boolean isOwner()
    {
        return owner;
    }
    
    
}
