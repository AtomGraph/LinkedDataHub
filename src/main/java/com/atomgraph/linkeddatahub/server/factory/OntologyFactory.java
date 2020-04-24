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
package com.atomgraph.linkeddatahub.server.factory;

import com.atomgraph.client.MediaTypes;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import javax.inject.Inject;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.Request;
import javax.ws.rs.ext.Provider;
import javax.ws.rs.ext.Providers;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.query.ParameterizedSparqlString;
import org.apache.jena.query.Query;
import org.apache.jena.query.QuerySolutionMap;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.vocabulary.OWL;
import org.apache.jena.vocabulary.RDFS;
import org.glassfish.hk2.api.Factory;
import org.glassfish.hk2.api.ServiceLocator;

/**
 * JAX-RS provider of application ontology .
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Provider
public class OntologyFactory implements Factory<Ontology> // extends OntologyLoader 
{

    @Context private ServiceLocator serviceLocator;

//    private final com.atomgraph.linkeddatahub.Application system;
    
//    @Context Request request;
    @Context Providers providers;
    
//    @Inject MediaTypes mediaTypes;
    @Inject Application application;
    
//    @Inject
//    public OntologyFactory(com.atomgraph.linkeddatahub.Application system)
//    {
//        super(system.getOntModelSpec());
//        this.system = system;
//    }

    @Override
    public Ontology provide()
    {
        return getOntology(getContainerRequestContext());
    }

    @Override
    public void dispose(Ontology t)
    {
    }
    
    public Ontology getOntology(ContainerRequestContext crc)
    {
        return (Ontology)crc.getProperty(OWL.Ontology.getURI());
    }
    
    public ContainerRequestContext getContainerRequestContext()
    {
        return serviceLocator.getService(ContainerRequestContext.class);
    }
    
//    public Ontology getOntology()
//    {
//        Application app = getApplication();
//        if (app == null) return null; // throw exception instead?
//        
//        return getOntology(app);
//    }
//    
//    @Override
//    public Model getModel(Service service, String ontologyURI)
//    {
//        QuerySolutionMap qsm = new QuerySolutionMap();
//        qsm.add(RDFS.isDefinedBy.getLocalName(), ResourceFactory.createResource(ontologyURI));
//                
//        return service.getSPARQLClient().loadModel(new ParameterizedSparqlString(getQuery().toString(), qsm).asQuery());
//    }
//    
//    public Query getQuery()
//    {
//        return system.getSitemapQuery();
//    }
//    
//    public Application getApplication()
//    {
//        return application;
//    }
    
//    public MediaTypes getMediaTypes()
//    {
//        return mediaTypes;
//    }
    
//    public Request getRequest()
//    {
//        return request;
//    }
    
}
