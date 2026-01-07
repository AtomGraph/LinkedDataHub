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
package com.atomgraph.linkeddatahub.resource;

import com.atomgraph.linkeddatahub.apps.model.Application;
import jakarta.inject.Inject;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.NotFoundException;
import jakarta.ws.rs.PATCH;
import jakarta.ws.rs.core.Response;
import java.io.IOException;
import org.apache.jena.query.Dataset;
import org.apache.jena.query.DatasetFactory;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.update.UpdateAction;
import org.apache.jena.update.UpdateRequest;
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
     * Retrieves the dataspace settings from the context dataset.
     *
     * @return the dataspace resource as RDF
     */
    @GET
    public Response get()
    {
        Model dataspaceModel = getSystem().getDataspaceModel(getApplication());

        if (dataspaceModel == null || dataspaceModel.isEmpty())
        {
            if (log.isWarnEnabled()) log.warn("No settings found for dataspace <{}> in context dataset", getApplication().getURI());
            return Response.status(Response.Status.NOT_FOUND).build();
        }

        if (log.isDebugEnabled()) log.debug("Retrieved settings for dataspace <{}>", getApplication().getURI());

        return Response.ok(dataspaceModel).build();
    }

    /**
     * Updates the dataspace settings by executing a SPARQL UPDATE request.
     * Accepts SPARQL update as the request body which is executed in the context of the dataspace named graph.
     *
     * @param updateRequest SPARQL update
     * @return response indicating success or failure
     * @throws java.io.IOException
     */
    @PATCH
    public Response patch(UpdateRequest updateRequest) throws IOException
    {
        if (updateRequest == null) throw new BadRequestException("SPARQL update not specified");

        if (log.isDebugEnabled()) log.debug("PATCH request for dataspace <{}>", getApplication().getURI());
        if (log.isDebugEnabled()) log.debug("PATCH update string: {}", updateRequest.toString());

        Model dataspaceModel = getSystem().getDataspaceModel(getApplication());
        if (dataspaceModel == null || dataspaceModel.isEmpty())
            throw new NotFoundException("No settings found for dataspace <" + getApplication().getURI() + "> in context dataset");

        // Execute the SPARQL UPDATE on the dataspace model in memory
        Dataset dataset = DatasetFactory.wrap(dataspaceModel);
        UpdateAction.execute(updateRequest, dataset);

        // Write the updated model back to the context dataset file
        getSystem().updateDataspace(getApplication(), dataspaceModel);

        if (log.isInfoEnabled()) log.info("Updated settings for dataspace <{}> via PATCH", getApplication().getURI());

        return Response.noContent().build();
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
