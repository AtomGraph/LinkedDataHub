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
package com.atomgraph.linkeddatahub.server.provider;

import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.client.filter.CacheControlFilter;
import com.atomgraph.linkeddatahub.model.Service;
import javax.ws.rs.client.Client;
import javax.ws.rs.core.CacheControl;
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
public class SPARQLClientOntologyLoader extends OntologyLoader
{

    private final Query query;
    private final Client client;
    private final MediaTypes mediaTypes;
    private final Integer maxGetRequestSize;
    private final boolean remoteBindings;
    
    public SPARQLClientOntologyLoader(OntModelSpec ontModelSpec, Query sitemapQuery,
            Client client, MediaTypes mediaTypes, Integer maxGetRequestSize, boolean remoteBindings)
    {
        super(ontModelSpec);
        this.query = sitemapQuery;
        this.client = client;
        this.mediaTypes = mediaTypes;
        this.maxGetRequestSize = maxGetRequestSize;
        this.remoteBindings = remoteBindings;
    }

    @Override
    public Model getModel(Service service, String ontologyURI)
    {
        ParameterizedSparqlString paramQuery = new ParameterizedSparqlString(getQuery().toString());
        paramQuery.setIri(RDFS.isDefinedBy.getLocalName(), ontologyURI);
        
        try (Response cr = service.getSPARQLClient().register(new CacheControlFilter(CacheControl.valueOf("no-cache"))). // add Cache-Control: no-cache to request
                query(paramQuery.asQuery(), Model.class, null))
        {
            return cr.readEntity(Model.class);
        }
    }
    
    public Query getQuery()
    {
        return query;
    }
    
    public Client getClient()
    {
        return client;
    }
    
    public MediaTypes getMediaTypes()
    {
        return mediaTypes;
    }
    
    public Integer getMaxGetRequestSize()
    {
        return maxGetRequestSize;
    }
    
    public boolean isRemoteBindings()
    {
        return remoteBindings;
    }
    
}
