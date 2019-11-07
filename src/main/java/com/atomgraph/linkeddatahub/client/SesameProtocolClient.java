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
package com.atomgraph.linkeddatahub.client;

import com.atomgraph.core.MediaTypes;
import com.atomgraph.core.client.SPARQLClient;
import com.sun.jersey.api.client.ClientResponse;
import com.sun.jersey.api.client.WebResource;
import com.sun.jersey.api.client.filter.ClientFilter;
import com.sun.jersey.core.util.MultivaluedMapImpl;
import java.util.Iterator;
import javax.ws.rs.core.MultivaluedMap;
import org.apache.jena.query.Query;
import org.apache.jena.query.QuerySolutionMap;
import org.apache.jena.rdf.model.RDFNode;
import org.apache.jena.riot.out.NodeFmtLib;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * RDF4J REST API ("Sesame HTTP protocol") client. Supports query variable binding passing as request parameters.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see <a href="https://rdf4j.eclipse.org/documentation/rest-api/#repository-queries">The rdf4j server REST API</a>
 */
public class SesameProtocolClient extends SPARQLClient
{
    
    private static final Logger log = LoggerFactory.getLogger(SesameProtocolClient.class);

    public SesameProtocolClient(WebResource webResource, MediaTypes mediaTypes, int maxGetRequestSize)
    {
        super(webResource, mediaTypes, maxGetRequestSize);
    }
    
    public SesameProtocolClient(WebResource webResource, MediaTypes mediaTypes)
    {
        super(webResource, mediaTypes);
    }
    
    @Override
    public SesameProtocolClient addFilter(ClientFilter authFilter)
    {
        if (authFilter == null) throw new IllegalArgumentException("ClientFilter cannot be null");

        super.addFilter(authFilter);

        return this;
    }

    public ClientResponse query(final Query query, final Class clazz, final QuerySolutionMap qsm, final MultivaluedMap<String, String> params)
    {
        MultivaluedMap<String, String> mergedParams = new MultivaluedMapImpl();
        if (qsm != null) mergedParams.putAll(solutionMapToMultivaluedMap(qsm));
        if (params != null) mergedParams.putAll(params);

        return super.query(query, clazz, mergedParams);
    }

    /*
    public void post(UpdateRequest updateRequest, QuerySolutionMap qsm)
    {
        if (log.isDebugEnabled()) log.debug("Executing post on SPARQL endpoint: {} using UpdateRequest: {}", getOrigin().getURI(), updateRequest);

        MultivaluedMap<String, String> mvm = solutionMapToMultivaluedMap(qsm);
        mvm.add("user_id", String.valueOf(updateRequest.hashCode()));

        getDataManager().executeUpdateRequest(getOrigin().getURI(), updateRequest, mvm);
    }
    */
    
    public static MultivaluedMap<String, String> solutionMapToMultivaluedMap(QuerySolutionMap qsm)
    {
        if (qsm == null) throw new IllegalArgumentException("QuerySolutionMap cannot be null");
        
        MultivaluedMap<String, String> params = new MultivaluedMapImpl();
        Iterator<String> it = qsm.varNames();
        while (it.hasNext())
        {
            String varName = it.next();
            RDFNode node = qsm.get(varName);
            params.add("$" + varName, NodeFmtLib.str(node.asNode()));
        }
        
        return params;
    }
    
}
