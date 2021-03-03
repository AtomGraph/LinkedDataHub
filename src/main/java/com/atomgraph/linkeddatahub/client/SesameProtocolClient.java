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
import java.util.Iterator;
import javax.ws.rs.client.ClientRequestFilter;
import javax.ws.rs.client.WebTarget;
import javax.ws.rs.core.MultivaluedHashMap;
import javax.ws.rs.core.MultivaluedMap;
import javax.ws.rs.core.Response;
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

    public SesameProtocolClient(WebTarget webResource, MediaTypes mediaTypes, int maxGetRequestSize)
    {
        super(webResource, mediaTypes, maxGetRequestSize);
    }
    
    public SesameProtocolClient(WebTarget webResource, MediaTypes mediaTypes)
    {
        super(webResource, mediaTypes);
    }
    
    @Override
    public SesameProtocolClient register(ClientRequestFilter authFilter)
    {
        if (authFilter == null) throw new IllegalArgumentException("ClientRequestFilter cannot be null");

        super.register(authFilter);

        return this;
    }

    public Response query(final Query query, final Class clazz, final QuerySolutionMap qsm)
    {
        return query(query, clazz, qsm, new MultivaluedHashMap());
    }
    
    public Response query(final Query query, final Class clazz, final QuerySolutionMap qsm, final MultivaluedMap<String, String> params)
    {
        MultivaluedMap<String, String> mergedParams = new MultivaluedHashMap();
        if (qsm != null) mergedParams.putAll(solutionMapToMultivaluedMap(qsm));
        if (params != null) mergedParams.putAll(params);

        return super.query(query, clazz, mergedParams);
    }

    public static MultivaluedMap<String, String> solutionMapToMultivaluedMap(QuerySolutionMap qsm)
    {
        if (qsm == null) throw new IllegalArgumentException("QuerySolutionMap cannot be null");
        
        MultivaluedMap<String, String> params = new MultivaluedHashMap();
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
