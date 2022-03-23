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
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import com.atomgraph.processor.exception.OntologyException;
import com.atomgraph.linkeddatahub.server.util.OntologyModelGetter;
import com.atomgraph.server.util.OntologyLoader;
import java.io.IOException;
import java.util.Optional;
import javax.annotation.Priority;
import javax.inject.Inject;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.ContainerRequestFilter;
import javax.ws.rs.container.PreMatching;
import org.apache.jena.ontology.OntModelSpec;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.rdf.model.InfModel;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.shared.NotFoundException;
import org.apache.jena.util.FileManager;
import org.apache.jena.vocabulary.OWL;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Request filter that retrieves the application ontology.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@PreMatching
@Priority(800)
public class OntologyFilter implements ContainerRequestFilter
{
    
    private static final Logger log = LoggerFactory.getLogger(OntologyFilter.class);

    @Inject com.atomgraph.linkeddatahub.Application system;

    
    @Override
    public void filter(ContainerRequestContext crc) throws IOException
    {
        crc.setProperty(OWL.Ontology.getURI(), getOntology(crc));
    }
    
    /**
     * Retrieves (optional) ontology from the container request context.
     * 
     * @param crc request context
     * @return optional ontology
     */
    public Optional<Ontology> getOntology(ContainerRequestContext crc)
    {
        Application app = getApplication(crc);
        
        try
        {
            return Optional.ofNullable(getOntology(app));
        }
        catch (OntologyException ex)
        {
            return Optional.empty();
        }
    }
    
    /**
     * Gets ontology of the specified application.
     * 
     * @param app application resource
     * @return ontology resource
     */
    public Ontology getOntology(Application app)
    {
        if (app.getOntology() == null) return null;

        return getOntology(app, app.getOntology().getURI());
    }
    
    /**
     * Loads ontology using the specified ontology URI.
     * 
     * @param app application resource
     * @param uri ontology URI
     * @return ontology resource
     */
    public Ontology getOntology(Application app, String uri)
    {
        if (app == null) throw new IllegalArgumentException("Application string cannot be null");
        if (uri == null) throw new IllegalArgumentException("Ontology URI string cannot be null");

        final OntModelSpec ontModelSpec;
//        final OntModelSpec loadSpec = new OntModelSpec(OntModelSpec.OWL_MEM);
        if (app.canAs(EndUserApplication.class))
        {
            ontModelSpec = new OntModelSpec(getSystem().getEndUserOntModelSpec(app.getURI()));
            // only create InfModel if ontology is not already cached
            if (!ontModelSpec.getDocumentManager().getFileManager().hasCachedModel(uri))
            {
                OntologyModelGetter modelGetter = new OntologyModelGetter(app.as(EndUserApplication.class),
                        ontModelSpec, getSystem().getOntologyQuery(), getSystem().getNoCertClient(), getSystem().getMediaTypes());
                Model model = modelGetter.getModel(uri);

                final InfModel infModel = ModelFactory.createInfModel(ontModelSpec.getReasoner(), model);

                ontModelSpec.getDocumentManager().addModel(uri, infModel);
                ontModelSpec.setImportModelGetter(modelGetter);
//                loadSpec.getDocumentManager().addModel(uri, infModel);
//                loadSpec.setImportModelGetter(modelGetter);
            }
        }
        else
        {
            ontModelSpec = new OntModelSpec(getSystem().getOntModelSpec());
            FileManager fileManager = ontModelSpec.getDocumentManager().getFileManager();
            if (!fileManager.hasCachedModel(uri))
            {
                Model model = fileManager.loadModel(uri, app.getBase().getURI(), null);
                final InfModel infModel = ModelFactory.createInfModel(ontModelSpec.getReasoner(), model);
                ontModelSpec.getDocumentManager().addModel(uri, infModel);
            }
        }
        
        try
        {
            // construct system provider to materialize inferenced model
            OntologyLoader ontologyLoader = new com.atomgraph.server.util.OntologyLoader(ontModelSpec.getDocumentManager(), uri, ontModelSpec, true);
            // bypass Processor's getOntology() because it overrides the ModelGetter TO-DO: fix!
            return ontModelSpec.getDocumentManager().getOntology(uri, ontModelSpec).getOntology(uri); // reloads the imports using ModelGetter. TO-DO: optimize?
        }
        catch (IllegalArgumentException ex)
        {
            // ontology resource was not found
        }
            
        if (log.isErrorEnabled()) log.error("Ontology resource '{}' not found", uri);
        // TO-DO: replace with Jena's OntologyException
        throw new NotFoundException("Ontology resource '" + uri + "' not found");
    }

    /**
     * Retrieves application from the container request context.
     * 
     * @param crc request context
     * @return application resource
     */
    public Application getApplication(ContainerRequestContext crc)
    {
        return ((Application)crc.getProperty(LAPP.Application.getURI()));
    }

    /**
     * Returns system application.
     * 
     * @return JAX-RS application.
     */
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }
    
}
