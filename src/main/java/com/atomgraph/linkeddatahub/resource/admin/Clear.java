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
import com.atomgraph.linkeddatahub.server.util.OntologyModelGetter;
import java.net.URI;
import javax.ws.rs.FormParam;
import javax.ws.rs.HeaderParam;
import javax.ws.rs.POST;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.ResponseBuilder;
import org.apache.jena.ontology.OntModel;
import org.apache.jena.ontology.OntModelSpec;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class Clear
{
    
    private static final Logger log = LoggerFactory.getLogger(Clear.class);

    private final com.atomgraph.linkeddatahub.apps.model.Application application;
    private final com.atomgraph.linkeddatahub.Application system;

    public Clear(com.atomgraph.linkeddatahub.apps.model.Application application, com.atomgraph.linkeddatahub.Application system)
    {
        this.application = application;
        this.system = system;
    }
    
    @POST
    public Response post(@FormParam("uri") URI clearURI, @HeaderParam("Referer") URI referer)
    {
        String ontologyURI = clearURI.toString();
        EndUserApplication app = getApplication().as(AdminApplication.class).getEndUserApplication(); // we're assuming the current app is admin
        OntModelSpec ontModelSpec = new OntModelSpec(getSystem().getOntModelSpec(app));
        if (ontModelSpec.getDocumentManager().getFileManager().hasCachedModel(ontologyURI))
        {
            ontModelSpec.getDocumentManager().getFileManager().removeCacheModel(ontologyURI);

            // !!! we need to reload the ontology model before returning a response, to make sure the next request already gets the new version !!!
            // same logic as in OntologyFilter. TO-DO: encapsulate?
            OntologyModelGetter modelGetter = new OntologyModelGetter(app,
                    ontModelSpec, getSystem().getOntologyQuery(), getSystem().getNoCertClient(), getSystem().getMediaTypes());
            ontModelSpec.setImportModelGetter(modelGetter);
            Model baseModel = modelGetter.getModel(ontologyURI);
            OntModel ontModel = ModelFactory.createOntologyModel(ontModelSpec, baseModel);
            ontModel.getDocumentManager().addModel(ontologyURI, ontModel, true);
            // make sure to cache imported models not only by ontology URI but also by document URI
            ontModel.listImportedOntologyURIs(true).forEach((String importURI) -> addDocumentModel(ontModel.getDocumentManager(), importURI));
        }
        
        ResponseBuilder builder = Response.ok();
        if (referer != null) builder.location(referer);
        
        return builder.build();
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
