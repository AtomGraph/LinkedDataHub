/**
 *  Copyright 2020 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.server.filter.request;

import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.util.OntologyLoader;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import java.io.IOException;
import javax.annotation.Priority;
import javax.inject.Inject;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.ContainerRequestFilter;
import javax.ws.rs.container.PreMatching;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.query.ParameterizedSparqlString;
import org.apache.jena.query.Query;
import org.apache.jena.query.QuerySolutionMap;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.vocabulary.OWL;
import org.apache.jena.vocabulary.RDFS;

/**
 *
 * @author Martynas Jusevičius <martynas@atomgraph.com>
 */
@PreMatching
@Priority(800)
public class OntologyFilter extends OntologyLoader implements ContainerRequestFilter
{
    
    private final com.atomgraph.linkeddatahub.Application system;

    @Inject
    public OntologyFilter(com.atomgraph.linkeddatahub.Application system)
    {
        super(system.getOntModelSpec());
        this.system = system;
    }
    
    @Override
    public void filter(ContainerRequestContext crc) throws IOException
    {
        crc.setProperty(OWL.Ontology.getURI(), getOntology(crc));
    }
    
    public Ontology getOntology(ContainerRequestContext crc)
    {
        Application app = getApplication(crc);
        if (app == null) return null; // throw exception instead?
        
        return getOntology(app);
    }
    
    public Application getApplication(ContainerRequestContext crc)
    {
        return (Application)crc.getProperty(LAPP.Application.getURI());
    }

    @Override
    public Model getModel(Service service, String ontologyURI)
    {
        QuerySolutionMap qsm = new QuerySolutionMap();
        qsm.add(RDFS.isDefinedBy.getLocalName(), ResourceFactory.createResource(ontologyURI));
                
        return service.getSPARQLClient().loadModel(new ParameterizedSparqlString(getQuery().toString(), qsm).asQuery());
    }
    
    public Query getQuery()
    {
        return system.getSitemapQuery();
    }
    
}
