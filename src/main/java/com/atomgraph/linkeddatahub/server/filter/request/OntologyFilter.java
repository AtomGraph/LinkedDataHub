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

import com.atomgraph.core.MediaTypes;
import com.atomgraph.core.io.ModelProvider;
import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import com.atomgraph.processor.exception.OntologyException;
import com.atomgraph.processor.vocabulary.LDT;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import javax.annotation.Priority;
import javax.inject.Inject;
import javax.ws.rs.client.Client;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.ContainerRequestFilter;
import javax.ws.rs.container.PreMatching;
import javax.ws.rs.core.Response;
import org.apache.jena.ontology.OntModel;
import org.apache.jena.ontology.OntModelSpec;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.rdf.model.InfModel;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.ModelReader;
import org.apache.jena.vocabulary.OWL;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@PreMatching
@Priority(800)
public class OntologyFilter implements ContainerRequestFilter
{
    
    private static final Logger log = LoggerFactory.getLogger(OntologyFilter.class);

    private final MediaTypes mediaTypes = new MediaTypes();
    private final javax.ws.rs.core.MediaType[] acceptedTypes;

    @Inject com.atomgraph.linkeddatahub.Application system;

    protected class ModelGetter implements org.apache.jena.rdf.model.ModelGetter
    {
        
        private final OntModelSpec ontModelSpec;
        
        public ModelGetter(OntModelSpec ontModelSpec)
        {
            this.ontModelSpec = ontModelSpec;
        }

        @Override
        public Model getModel(String uri)
        {
            return OntologyFilter.this.getOntology(uri, getOntModelSpec(), null).getModel();
        }
        
        @Override
        public Model getModel(String uri, ModelReader loadIfAbsent) 
        {
            return getModel(uri);
            //return loadIfAbsent.readModel(ModelFactory.createDefaultModel(), uri);
        }

        public OntModelSpec getOntModelSpec()
        {
            return ontModelSpec;
        }
        
    }

    public OntologyFilter()
    {
        List<javax.ws.rs.core.MediaType> acceptedTypeList = new ArrayList();
        acceptedTypeList.addAll(mediaTypes.getReadable(Model.class));
        acceptedTypes = acceptedTypeList.toArray(new javax.ws.rs.core.MediaType[acceptedTypeList.size()]); 
    }
    
    @Override
    public void filter(ContainerRequestContext crc) throws IOException
    {
        crc.setProperty(OWL.Ontology.getURI(), getOntology(crc));
    }
    
    public Optional<Ontology> getOntology(ContainerRequestContext crc)
    {
        Optional<Application> app = getApplication(crc);
        if (app.isEmpty()) return Optional.empty();
        
        return Optional.ofNullable(getOntology(app.get()));
    }
    
    public Ontology getOntology(Application app)
    {
        if (app.getPropertyResourceValue(LDT.ontology) == null) return null;

        OntModel schema;
        if (app.canAs(EndUserApplication.class)) // load admin ontology since end-user ontology imports it
        {
            AdminApplication adminApp = app.as(EndUserApplication.class).getAdminApplication();
            schema = getOntology(adminApp).getOntModel();
        }
        else
            schema = null;

        return getOntology(app.getPropertyResourceValue(LDT.ontology).getURI(), getSystem().getOntModelSpec(), schema);
    }
    
    public Ontology getOntology(String ontologyURI, OntModelSpec ontModelSpec, OntModel schema)
    {
        if (ontologyURI == null) throw new IllegalArgumentException("Ontology URI string cannot be null");
        if (ontModelSpec == null) throw new IllegalArgumentException("OntModelSpec cannot be null");

        final Model model;

            // read mapped ontologies from file
        String mappedURI = ontModelSpec.getDocumentManager().getFileManager().mapURI(ontologyURI);
        if (!(mappedURI.startsWith("http") || mappedURI.startsWith("https"))) // ontology URI mapped to a local file resource
            model = ontModelSpec.getDocumentManager().getFileManager().loadModel(ontologyURI);
        else
        {
            if (log.isDebugEnabled()) log.debug("Loading end-user Ontology '{}'", ontologyURI);
            try (Response cr = getClient().target(ontologyURI).
                    request(getAcceptableMediaTypes()).
                    get())
            {
                if (!cr.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
                {
                    if (log.isErrorEnabled()) log.error("Could not load ontology from URI: {}", ontologyURI);
                    throw new OntologyException("Could not load ontology from URI");
                }
                cr.getHeaders().putSingle(ModelProvider.REQUEST_URI_HEADER, ontologyURI); // provide a base URI hint to ModelProvider
                model = cr.readEntity(Model.class);
            }
        }

        final InfModel infModel;
        if (schema != null) infModel = ModelFactory.createInfModel(ontModelSpec.getReasoner(), schema, model);
        else infModel = ModelFactory.createInfModel(ontModelSpec.getReasoner(), model);

        ontModelSpec.getDocumentManager().addModel(ontologyURI, infModel);
        ontModelSpec.setImportModelGetter(new ModelGetter(ontModelSpec));

        // construct system provider to materialize inferenced model
        return new com.atomgraph.server.util.OntologyLoader(ontModelSpec.getDocumentManager(), ontologyURI, ontModelSpec, true).getOntology();
    }

    public Optional<Application> getApplication(ContainerRequestContext crc)
    {
        return ((Optional<Application>)crc.getProperty(LAPP.Application.getURI()));
    }
    
    public Client getClient()
    {
        return getSystem().getNoCertClient();
    }
    
    public javax.ws.rs.core.MediaType[] getAcceptableMediaTypes()
    {
        return acceptedTypes;
    }

    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }
    
}
