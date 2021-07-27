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

import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import org.apache.jena.ontology.OntModel;
import org.apache.jena.ontology.OntModelSpec;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.processor.exception.OntologyException;
import com.atomgraph.processor.vocabulary.LDT;
import java.net.URI;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.rdf.model.InfModel;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.ModelReader;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Abstract base class for application ontology loaders.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Deprecated
public abstract class OntologyLoader
{
    private static final Logger log = LoggerFactory.getLogger(OntologyLoader.class);
    
    private final OntModelSpec ontModelSpec;
    
    protected class ServiceModelGetter implements org.apache.jena.rdf.model.ModelGetter
    {
        
        private final Application app;
        private final Service service;
        private final OntModelSpec ontModelSpec;
        
        public ServiceModelGetter(Application app, Service service, OntModelSpec ontModelSpec)
        {
            this.app = app;
            this.service = service;
            this.ontModelSpec = ontModelSpec;
        }
        
        @Override
        public Model getModel(String uri)
        {
            return OntologyLoader.this.getModel(getService(), uri);
        }

        @Override
        public Model getModel(String uri, ModelReader loadIfAbsent)
        {
            // read mapped ontologies from file
            String mappedURI = getOntModelSpec().getDocumentManager().getFileManager().mapURI(uri);
            if (!(mappedURI.startsWith("http") || mappedURI.startsWith("https"))) // ontology URI mapped to a local file resource
                return getOntModelSpec().getDocumentManager().getFileManager().loadModel(uri);
            
            URI ontURI = URI.create(uri);
            if (getApplication().getBaseURI().relativize(ontURI).equals(ontURI)) // external ontology URI (not relative to the base of this app)
                return getOntModelSpec().getDocumentManager().getOntology(uri, getOntModelSpec());
                
            // attempt to load unmapped ontologies from SPARQL service
            Model model = getModel(uri);
            if (model.isEmpty()) model = null;
            
            // as a last resort, fallback to reading ontology from its URI
            if (model == null) return loadIfAbsent.readModel(ModelFactory.createDefaultModel(), uri);

            return model;
        }

        public Application getApplication()
        {
            return app;
        }
        
        public Service getService()
        {
            return service;
        }
        
        public OntModelSpec getOntModelSpec()
        {
            return ontModelSpec;
        }
        
    }
    
    public OntologyLoader(final OntModelSpec ontModelSpec)
    {       
        if (ontModelSpec == null) throw new IllegalArgumentException("OntModelSpec cannot be null");
        
        this.ontModelSpec = ontModelSpec;
    }
    
    public Ontology getOntology(final Application app)
    {
        if (app == null) throw new IllegalArgumentException("Application cannot be null");

        if (app.getPropertyResourceValue(LDT.ontology) == null) return null;
//        {
//            if (log.isErrorEnabled()) log.error("Application '{}' does not have an ontology", app);
//            throw new IllegalStateException("Application '" + app + "' does not have an ontology");
//        }

        //String ontologyURI = app.getOntology().getURI();
        String ontologyURI = app.getPropertyResourceValue(LDT.ontology).getURI();
        String mappedURI = getOntModelSpec().getDocumentManager().getFileManager().mapURI(ontologyURI);
        // if ontology is not cached, load it from admin service
        if (!getOntModelSpec().getDocumentManager().getFileManager().hasCachedModel(ontologyURI) && mappedURI.equals(ontologyURI))
        {
            Service service;
            OntModel schema;

            // always load end-user ontologies from admin service
            if (app.canAs(EndUserApplication.class)) // load admin ontology since end-user ontology imports it
            {
                AdminApplication adminApp = app.as(EndUserApplication.class).getAdminApplication();
                service = adminApp.getService();
                schema = getOntology(adminApp).getOntModel();
            }
            else
            {
                service = app.getService();
                schema = null;
            }

            // load ontology from admin service
            return getOntology(app, service, app.getPropertyResourceValue(LDT.ontology).getURI(), getOntModelSpec(), schema); // app.getOntology().getURI()
        }
        
        return new com.atomgraph.server.util.OntologyLoader(getOntModelSpec().getDocumentManager(), ontologyURI,
                    getOntModelSpec(), false). // do not materialize on subsequent requests
                getOntology();
    }
    
    public Ontology getOntology(Application app, Service service, String ontologyURI, OntModelSpec ontModelSpec, OntModel schema)
    {
        if (service == null) throw new IllegalArgumentException("Service cannot be null");
        if (app == null) throw new IllegalArgumentException("Application cannot be null");
        if (ontologyURI == null) throw new IllegalArgumentException("Ontology URI string cannot be null");
        if (ontModelSpec == null) throw new IllegalArgumentException("OntModelSpec cannot be null");

        if (log.isDebugEnabled()) log.debug("Loading end-user Ontology '{}' from Service: {}", ontologyURI, service);
        Model model = getModel(service, ontologyURI);

        InfModel infModel;
        if (schema != null) infModel = ModelFactory.createInfModel(ontModelSpec.getReasoner(), schema, model);
        else infModel = ModelFactory.createInfModel(ontModelSpec.getReasoner(), model);

        if (infModel.isEmpty())
        {
            if (log.isErrorEnabled()) log.error("Ontology '{}' loaded from Service '{}' is empty", ontologyURI, service);
            throw new OntologyException("Ontology '" + ontologyURI + "' loaded from Service '" + service + "' is empty");
        }
        
        ontModelSpec.getDocumentManager().addModel(ontologyURI, infModel);
        ontModelSpec.setImportModelGetter(new ServiceModelGetter(app, service, ontModelSpec));

        // construct system provider to materialize inferenced model
        return new com.atomgraph.server.util.OntologyLoader(ontModelSpec.getDocumentManager(), ontologyURI, ontModelSpec, true).getOntology();
    }
    
    public abstract Model getModel(Service service, String ontologyURI);
    
    public OntModelSpec getOntModelSpec()
    {
        // create a deep copy so we don't affect the system OntModelSpec
        OntModelSpec newOntModelSpec = new OntModelSpec(ontModelSpec);
        newOntModelSpec.setReasoner(ontModelSpec.getReasoner());
        newOntModelSpec.setDocumentManager(ontModelSpec.getDocumentManager());
        newOntModelSpec.setImportModelGetter(ontModelSpec.getImportModelGetter());

        return newOntModelSpec;
    }
    
}