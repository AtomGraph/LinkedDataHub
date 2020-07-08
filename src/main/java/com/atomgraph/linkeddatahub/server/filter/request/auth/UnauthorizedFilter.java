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
package com.atomgraph.linkeddatahub.server.filter.request.auth;

import com.atomgraph.linkeddatahub.exception.auth.AuthorizationException;
import com.atomgraph.linkeddatahub.model.UserAccount;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.processor.vocabulary.LDT;
import com.atomgraph.spinrdf.vocabulary.SPIN;
import java.net.URI;
import javax.annotation.Priority;
import javax.ws.rs.Priorities;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.PreMatching;
import org.apache.jena.query.QuerySolutionMap;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.vocabulary.RDFS;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS request filter that handles unauthorized requests.
 * It handles requests that were not successfully authorized by previous filters.
 * It should be the last one in the filter queue.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@PreMatching
@Priority(Priorities.USER + 100) // has to execute after WebIDFilter
public class UnauthorizedFilter extends AuthFilter
{
    private static final Logger log = LoggerFactory.getLogger(UnauthorizedFilter.class);

    @Override
    public String getScheme()
    {
        return null;
    }
    
    @Override
    public boolean isApplied(Application application, String realm, ContainerRequestContext request)
    {
        return true;
    }
    
    public QuerySolutionMap getQuerySolutionMap(Application app, ContainerRequestContext request, Resource accessMode)
    {
        QuerySolutionMap qsm = new QuerySolutionMap();
        qsm.add("AuthenticatedAgentClass", RDFS.Resource); // disable AuthenticatedAgent UNION branch
        qsm.add("agent", RDFS.Resource); // non-matching value that disables the branch of UNION with ?agent
        qsm.add(SPIN.THIS_VAR_NAME, ResourceFactory.createResource(request.getUriInfo().getAbsolutePath().toString()));
        qsm.add("Mode", accessMode);
        qsm.add(LDT.Ontology.getLocalName(), app.getOntology());

        return qsm;
    }

    @Override
    public void authorize(ContainerRequestContext request, URI absolutePath, Resource accessMode, Application app)
    {
        if (isApplied(app, null, request) || isLoginForced(request, getScheme())) // checks if this filter should be applied
        {
            //if (isLogoutForced(request, getScheme())) logout(app, realm, request);
            
            QuerySolutionMap qsm = getQuerySolutionMap(app, request, accessMode);
            //if (qsm == null && isLoginForced(request, getScheme())) login(app, realm, request); // no credentials
            
            Model authModel = loadAuth(qsm, app);
            // RDFS inference is too slow (takes ~2.5 seconds)
            //InfModel authModel = ModelFactory.createRDFSModel(getOntology().getOntModel(), rawModel);
            
            // type check will not work on LACL subclasses without InfModel
            Resource authorization = getResourceByPropertyValue(authModel, ACL.mode, null);
            if (authorization == null)
            {
                if (log.isTraceEnabled()) log.trace("Access not authorized for request URI: {}", request.getUriInfo().getAbsolutePath());
                throw new AuthorizationException("Access not authorized", request.getUriInfo().getAbsolutePath(), accessMode, null);
            }
        }
        
        //return request;
    }

    @Override
    public void login(Application application, String realm, ContainerRequestContext request)
    {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    @Override
    public void logout(Application application, String realm, ContainerRequestContext request)
    {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    @Override
    public QuerySolutionMap getQuerySolutionMap(String realm, ContainerRequestContext request, URI absolutePath, Resource accessMode) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    @Override
    public ContainerRequestContext authenticate(String realm, ContainerRequestContext request, Resource accessMode, UserAccount account, Resource agent) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }
    
}
