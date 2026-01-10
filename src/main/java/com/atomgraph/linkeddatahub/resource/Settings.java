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

import com.atomgraph.core.util.ModelUtils;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.server.io.ValidatingModelProvider;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import jakarta.inject.Inject;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.InternalServerErrorException;
import jakarta.ws.rs.NotFoundException;
import jakarta.ws.rs.PATCH;
import jakarta.ws.rs.WebApplicationException;
import static com.atomgraph.server.status.UnprocessableEntityStatus.UNPROCESSABLE_ENTITY;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.EntityTag;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.MessageBodyReader;
import jakarta.ws.rs.ext.Providers;
import java.io.IOException;
import org.apache.jena.query.Dataset;
import org.apache.jena.query.DatasetFactory;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.update.UpdateAction;
import org.apache.jena.update.UpdateRequest;
import org.apache.jena.vocabulary.RDF;
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
    private final Providers providers;
    private final Request request;

    /**
     * Constructs the Settings endpoint.
     *
     * @param application the current dataspace application
     * @param system the system application
     * @param providers JAX-RS provider registry
     * @param request JAX-RS request context
     */
    @Inject
    public Settings(Application application, com.atomgraph.linkeddatahub.Application system, @Context Providers providers, @Context Request request)
    {
        this.application = application;
        this.system = system;
        this.providers = providers;
        this.request = request;
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

        EntityTag entityTag = getEntityTag(dataspaceModel);
        Response.ResponseBuilder rb = getRequest().evaluatePreconditions(entityTag);
        if (rb != null) return rb.build();

        return Response.ok(dataspaceModel).
            tag(entityTag).
            build();
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

        // Create a mutable copy since getDataspaceModel() returns a read-only view
        Model mutableModel = ModelFactory.createDefaultModel().add(dataspaceModel);

        // Execute the SPARQL UPDATE on the dataspace model in memory
        Dataset dataset = DatasetFactory.wrap(mutableModel);
        UpdateAction.execute(updateRequest, dataset);

        // Verify the application resource still exists with correct type after PATCH
        Resource appResource = ResourceFactory.createResource(getApplication().getURI());
        if (!mutableModel.contains(appResource, RDF.type, LAPP.EndUserApplication))
        {
            if (log.isWarnEnabled()) log.warn("PATCH removed application resource or its type for <{}>", getApplication().getURI());
            throw new WebApplicationException("PATCH cannot remove the application resource or its type", UNPROCESSABLE_ENTITY.getStatusCode()); // 422 Unprocessable Entity
        }

        // validate the updated model
        validate(mutableModel);

        // Write the updated model back to the context dataset file
        getSystem().updateApp(getApplication(), mutableModel);

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

    /**
     * Returns the JAX-RS providers registry.
     *
     * @return the providers
     */
    public Providers getProviders()
    {
        return providers;
    }

    /**
     * Validates model against SPIN and SHACL constraints.
     *
     * @param model RDF model
     * @return validated model
     */
    public Model validate(Model model)
    {
        MessageBodyReader<Model> reader = getProviders().getMessageBodyReader(Model.class, null, null, com.atomgraph.core.MediaType.APPLICATION_NTRIPLES_TYPE);
        if (reader instanceof ValidatingModelProvider validatingModelProvider) return validatingModelProvider.processRead(model);

        throw new InternalServerErrorException("Could not obtain ValidatingModelProvider instance");
    }

    /**
     * Returns the JAX-RS request context.
     *
     * @return the request
     */
    public Request getRequest()
    {
        return request;
    }

    /**
     * Generates an ETag for the given model.
     *
     * @param model RDF model
     * @return entity tag
     */
    public EntityTag getEntityTag(Model model)
    {
        return new EntityTag(Long.toHexString(ModelUtils.hashModel(model)));
    }

}
