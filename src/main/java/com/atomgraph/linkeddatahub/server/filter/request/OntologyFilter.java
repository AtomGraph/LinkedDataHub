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

import com.atomgraph.client.locator.PrefixMapper;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.core.io.ModelProvider;
import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import com.atomgraph.processor.exception.OntologyException;
import com.atomgraph.client.vocabulary.LDT;
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
import org.apache.jena.util.FileManager;
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
        
        private final Application app;
        private final OntModelSpec ontModelSpec;
        
        public ModelGetter(Application app, OntModelSpec ontModelSpec)
        {
            this.app = app;
            this.ontModelSpec = ontModelSpec;
        }

        @Override
        public Model getModel(String uri)
        {
            FileManager fileManager = getOntModelSpec().getDocumentManager().getFileManager();
            // read cached ontology or mapped ontology from file
            String mappedURI = getOntModelSpec().getDocumentManager().getFileManager().mapURI(uri);
            if (fileManager.hasCachedModel(uri) || !(mappedURI.startsWith("http") || mappedURI.startsWith("https"))) // ontology URI mapped to a local file resource
                return fileManager.loadModel(uri, getApplication().getBase().getURI(), null);
            else
            {
                // TO-DO: use LinkedDataClient
                if (log.isDebugEnabled()) log.debug("Loading end-user Ontology '{}'", uri);
                try (Response cr = getClient().target(uri).
                        request(getAcceptableMediaTypes()).
                        get())
                {
                    if (!cr.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
                    {
                        if (log.isErrorEnabled()) log.error("Could not load ontology from URI: {}", uri);
                        // TO-DO: replace with Jena's OntologyException
                        throw new OntologyException("Could not load ontology from URI '" + uri + "'");
                    }
                    cr.getHeaders().putSingle(ModelProvider.REQUEST_URI_HEADER, uri); // provide a base URI hint to ModelProvider
                    return cr.readEntity(Model.class);
                }
                catch (Exception ex)
                {
                    if (log.isErrorEnabled()) log.error("Could not load ontology from URI: {}", uri);
                    // TO-DO: replace with Jena's OntologyException
                    throw new OntologyException("Could not load ontology from URI '" + uri + "'");
                }
            }
        }
        
        @Override
        public Model getModel(String uri, ModelReader loadIfAbsent) 
        {
            try
            {
                return getModel(uri);
            }
            catch (OntologyException ex)
            {
                return loadIfAbsent.readModel(ModelFactory.createDefaultModel(), uri);
            }
        }

        public Application getApplication()
        {
            return app;
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
        
        try
        {
            return Optional.ofNullable(getOntology(app.get()));
        }
        catch (OntologyException ex)
        {
            return Optional.empty();
        }
    }
    
    public Ontology getOntology(Application app)
    {
        if (app.getPropertyResourceValue(LDT.ontology) == null) return null;
        
        final OntModel schema;
        
        if (app.canAs(EndUserApplication.class)) // load admin ontology since end-user ontology imports it
        {
            AdminApplication adminApp = app.as(EndUserApplication.class).getAdminApplication();
            schema = getOntology(adminApp).getOntModel();
        }
        else
        {
            schema = null;
            
            String uriPrefix = app.getBase() + "ns";
            
            if (((PrefixMapper)getSystem().getOntModelSpec().getDocumentManager().getFileManager().getLocationMapper()).getPrefixAltEntry(uriPrefix) == null)
                ((PrefixMapper)getSystem().
                    getOntModelSpec().
                    getDocumentManager().
                    getFileManager().
                    getLocationMapper()).
                    addAltPrefixEntry(uriPrefix, "com/atomgraph/linkeddatahub/app/admin/adm.ttl");
        }

        return getOntology(app, app.getPropertyResourceValue(LDT.ontology).getURI(), getSystem().getOntModelSpec(), schema);
    }
    
    public Ontology getOntology(Application app, String uri, OntModelSpec ontModelSpec, OntModel schema)
    {
        if (app == null) throw new IllegalArgumentException("Application string cannot be null");
        if (uri == null) throw new IllegalArgumentException("Ontology URI string cannot be null");
        if (ontModelSpec == null) throw new IllegalArgumentException("OntModelSpec cannot be null");

        ModelGetter modelGetter = new ModelGetter(app, ontModelSpec);
        Model model = modelGetter.getModel(uri);

        final InfModel infModel;
        if (schema != null) infModel = ModelFactory.createInfModel(ontModelSpec.getReasoner(), schema, model);
        else infModel = ModelFactory.createInfModel(ontModelSpec.getReasoner(), model);

        ontModelSpec.getDocumentManager().addModel(uri, infModel);
        ontModelSpec.setImportModelGetter(modelGetter);

        try
        {
            // construct system provider to materialize inferenced model
            return new com.atomgraph.server.util.OntologyLoader(ontModelSpec.getDocumentManager(), uri, ontModelSpec, true).getOntology();
        }
        catch (IllegalArgumentException ex)
        {
            // ontology resource was not found
        }
        
        if (log.isErrorEnabled()) log.error("Ontology resource '{}' not found", uri);
        // TO-DO: replace with Jena's OntologyException
        throw new OntologyException("Ontology resource '" + uri + "' not found");
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
