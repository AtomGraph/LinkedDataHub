/**
 *  Copyright 2022 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.resource.admin;

import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import static com.atomgraph.linkeddatahub.server.filter.request.OntologyFilter.addDocumentModel;
import com.atomgraph.linkeddatahub.server.filter.response.CacheInvalidationFilter;
import com.atomgraph.linkeddatahub.server.util.OntologyModelGetter;
import java.net.URI;
import jakarta.inject.Inject;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.FormParam;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriBuilder;
import org.apache.jena.ontology.OntModel;
import org.apache.jena.ontology.OntModelSpec;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.glassfish.jersey.uri.UriComponent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS resource that clears ontology from memory and reloads it.
 * Contains the same ontology loading query as <code>OntologyFilter</code>.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 * @see com.atomgraph.linkeddatahub.server.filter.request.OntologyFilter
 */
public class ClearOntology
{
    
    private static final Logger log = LoggerFactory.getLogger(ClearOntology.class);

    private final com.atomgraph.linkeddatahub.apps.model.Application application;
    private final com.atomgraph.linkeddatahub.Application system;

    /**
     * Constructs endpoint.
     * 
     * @param application matched application
     * @param system system application
     */
    @Inject
    public ClearOntology(com.atomgraph.linkeddatahub.apps.model.Application application, com.atomgraph.linkeddatahub.Application system)
    {
        this.application = application;
        this.system = system;
    }
    
    /**
     * Clears the specified ontology from memory.
     * 
     * @param ontologyURI ontology URI
     * @param referer the referring URL
     * @return JAX-RS response
     */
    @POST
    @Consumes(MediaType.APPLICATION_FORM_URLENCODED)
    public Response post(@FormParam("uri") String ontologyURI, @HeaderParam("Referer") URI referer)
    {
        if (ontologyURI == null) throw new BadRequestException("Ontology URI not specified");

        EndUserApplication endUserApp = getApplication().as(AdminApplication.class).getEndUserApplication(); // we're assuming the current app is admin
        OntModelSpec ontModelSpec = new OntModelSpec(getSystem().getOntModelSpec(endUserApp));
        if (ontModelSpec.getDocumentManager().getFileManager().hasCachedModel(ontologyURI))
        {
            if (log.isDebugEnabled()) log.debug("Clearing ontology with URI '{}' from memory", ontologyURI);
            ontModelSpec.getDocumentManager().getFileManager().removeCacheModel(ontologyURI);

            URI ontologyDocURI = UriBuilder.fromUri(ontologyURI).fragment(null).build(); // skip fragment from the ontology URI to get its graph URI            
            // purge from admin cache
            if (getApplication().getFrontendProxy() != null)
            {
                if (log.isDebugEnabled()) log.debug("Purge ontology document with URI '{}' from frontend proxy cache", ontologyDocURI);
                ban(getApplication().getFrontendProxy(), ontologyDocURI.toString(), false);
            }
            if (getApplication().getService().getBackendProxy() != null)
            {
                if (log.isDebugEnabled()) log.debug("Ban ontology with URI '{}' from backend proxy cache", ontologyURI);
                ban(getApplication().getService().getBackendProxy(), ontologyURI);
            }
            // purge from end-user cache
            if (endUserApp.getFrontendProxy() != null)
            {
                if (log.isDebugEnabled()) log.debug("Purge ontology document with URI '{}' from frontend proxy cache", ontologyDocURI);
                ban(endUserApp.getFrontendProxy(), ontologyDocURI.toString(), false);
            }
            if (endUserApp.getService().getBackendProxy() != null)
            {
                if (log.isDebugEnabled()) log.debug("Ban ontology with URI '{}' from backend proxy cache", ontologyURI);
                ban(endUserApp.getService().getBackendProxy(), ontologyURI);
            }
            
            // !!! we need to reload the ontology model before returning a response, to make sure the next request already gets the new version !!!
            // same logic as in OntologyFilter. TO-DO: encapsulate?
            OntologyModelGetter modelGetter = new OntologyModelGetter(endUserApp, ontModelSpec, getSystem().getOntologyQuery());
            ontModelSpec.setImportModelGetter(modelGetter);
            if (log.isDebugEnabled()) log.debug("Started loading ontology with URI '{}' from the admin dataset", ontologyURI);
            Model baseModel = modelGetter.getModel(ontologyURI);
            OntModel ontModel = ModelFactory.createOntologyModel(ontModelSpec, baseModel);
            // materialize OntModel inferences to avoid invoking rules engine on every request
            OntModel materializedModel = ModelFactory.createOntologyModel(OntModelSpec.OWL_MEM); // no inference
            materializedModel.add(ontModel);
            ontModel.getDocumentManager().addModel(ontologyURI, materializedModel, true); // make immutable and add as OntModel so that imports do not need to be reloaded during retrieval
            // make sure to cache imported models not only by ontology URI but also by document URI
            ontModel.listImportedOntologyURIs(true).forEach((String importURI) -> addDocumentModel(ontModel.getDocumentManager(), importURI));
            if (log.isDebugEnabled()) log.debug("Finished loading ontology with URI '{}' from the admin dataset", ontologyURI);
        }
        
        if (referer != null) return Response.seeOther(referer).build();
        else return Response.ok().build();
    }
    
    public void ban(Resource proxy, String url)
    {
        ban(proxy, url, true);
    }

    /** 
     * Bans URL from the backend proxy cache.
     * 
     * @param proxy proxy server URL
     * @param url banned URL
     * @param urlEncode if true, the banned URL value will be URL-encoded
     */
    public void ban(Resource proxy, String url, boolean urlEncode)
    {
        if (url == null) throw new IllegalArgumentException("Resource cannot be null");

        // Extract path from URL - Varnish req.url only contains the path, not the full URL
        URI uri = URI.create(url);
        String path = uri.getPath();
        if (uri.getQuery() != null) path += "?" + uri.getQuery();

        final String urlValue = urlEncode ? UriComponent.encode(path, UriComponent.Type.UNRESERVED) : path;

        try (Response cr = getSystem().getClient().target(proxy.getURI()).
                request().
                header(CacheInvalidationFilter.HEADER_NAME, urlValue).
                method("BAN", Response.class))
        {
            // Response automatically closed by try-with-resources
        }
    }
    
    /**
     * Returns the current application.
     * 
     * @return application resource
     */
    public com.atomgraph.linkeddatahub.apps.model.Application getApplication()
    {
        return application;
    }
    
    /**
     * Returns the system application.
     * 
     * @return JAX-RS application
     */
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }
    
}
