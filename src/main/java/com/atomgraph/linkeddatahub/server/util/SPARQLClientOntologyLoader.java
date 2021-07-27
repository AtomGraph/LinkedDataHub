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
package com.atomgraph.linkeddatahub.server.util;

import com.atomgraph.linkeddatahub.model.Service;
import javax.ws.rs.core.Response;
import org.apache.jena.ontology.OntModelSpec;
import org.apache.jena.query.ParameterizedSparqlString;
import org.apache.jena.query.Query;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.vocabulary.RDFS;

/**
 * Ontology loader that uses SPARQL to load the RDF graph of the ontology.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Deprecated
public class SPARQLClientOntologyLoader extends OntologyLoader
{

    private final Query query;
    
    public SPARQLClientOntologyLoader(OntModelSpec ontModelSpec, Query sitemapQuery)
    {
        super(ontModelSpec);
        this.query = sitemapQuery;
    }

    @Override
    public Model getModel(Service service, String ontologyURI)
    {
        ParameterizedSparqlString paramQuery = new ParameterizedSparqlString(getQuery().toString());
        paramQuery.setIri(RDFS.isDefinedBy.getLocalName(), ontologyURI);
        
        try (Response cr = service.getSPARQLClient().// register(new CacheControlFilter(CacheControl.valueOf("no-cache"))). // add Cache-Control: no-cache to request
                query(paramQuery.asQuery(), Model.class))
        {
            return cr.readEntity(Model.class);
        }
    }
    
    public Query getQuery()
    {
        return query;
    }
    
}
