/**
 *  Copyright 2025 Martynas Jusevičius <martynas@atomgraph.com>
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

import com.atomgraph.linkeddatahub.apps.model.Application;
import jakarta.inject.Inject;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.core.Response;
import java.io.IOException;
import org.apache.jena.rdf.model.Model;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS resource for updating dataspace settings.
 * Handles POST requests with RDF data representing the updated dataspace configuration.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class Settings
{
    private static final Logger log = LoggerFactory.getLogger(Settings.class);

    private final Application application;
    private final com.atomgraph.linkeddatahub.Application system;

    /**
     * Constructs the Settings endpoint.
     *
     * @param application the current dataspace application
     * @param system the system application
     */
    @Inject
    public Settings(Application application, com.atomgraph.linkeddatahub.Application system)
    {
        this.application = application;
        this.system = system;
    }

    /**
     * Updates the dataspace settings by accepting RDF data representing the new configuration.
     *
     * @param model the RDF model containing the updated dataspace configuration
     * @return response indicating success or failure
     * @throws java.io.IOException
     */
    @POST
    public Response post(Model model) throws IOException
    {
        if (model == null || model.isEmpty()) throw new BadRequestException("Model cannot be empty");
       
        // Update the dataspace configuration
        getSystem().updateDataspace(getApplication(), model);

        if (log.isInfoEnabled()) log.info("Updated settings for dataspace <{}>", getApplication().getURI());

        return Response.ok().build();
    }

    /**
     * Returns the current dataspace application.
     *
     * @return the application
     */
    public Application getApplication()
    {
        return application;
    }

    /**
     * Returns the system application.
     *
     * @return the system application
     */
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }

}
