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
package com.atomgraph.linkeddatahub.client;

import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.client.util.RetryingInvocationBuilder;
import jakarta.ws.rs.NotFoundException;
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.client.WebTarget;
import jakarta.ws.rs.core.MultivaluedHashMap;
import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.Response.Status;
import org.apache.jena.rdf.model.Model;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author Martynas.Jusevicius
 */
public class GraphStoreClient extends com.atomgraph.core.client.GraphStoreClient {

    private static final Logger log = LoggerFactory.getLogger(GraphStoreClient.class);

    private final long defaultDelayMillis = 5000L;
    private final int maxRetryCount = 3;

    protected GraphStoreClient(MediaTypes mediaTypes, WebTarget endpoint) {
        super(mediaTypes, endpoint);
    }

    protected GraphStoreClient(WebTarget endpoint) {
        this(new MediaTypes(), endpoint);
    }

    public static GraphStoreClient create(MediaTypes mediaTypes, WebTarget endpoint) {
        return new GraphStoreClient(mediaTypes, endpoint);
    }

    public static GraphStoreClient create(WebTarget endpoint) {
        return new GraphStoreClient(endpoint);
    }

    @Override
    public boolean containsModel(String uri) {
        MultivaluedMap<String, String> params = new MultivaluedHashMap<>();
        params.putSingle(GRAPH_PARAM_NAME, uri);

        try (Response cr = new RetryingInvocationBuilder(
                applyParams(params).request(getReadableMediaTypes(Model.class)),
                defaultDelayMillis,
                maxRetryCount
        ).head()) {
            return cr.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL);
        }
    }

    @Override
    public Model getModel() {
        MultivaluedMap<String, String> params = new MultivaluedHashMap<>();
        params.putSingle(DEFAULT_PARAM_NAME, Boolean.TRUE.toString());

        try (Response cr = new RetryingInvocationBuilder(
                applyParams(params).request(getReadableMediaTypes(Model.class)),
                defaultDelayMillis,
                maxRetryCount
        ).get()) {
            if (cr.getStatus() == Status.NOT_FOUND.getStatusCode()) {
                throw new NotFoundException();
            }
            return cr.readEntity(Model.class);
        }
    }

    @Override
    public Model getModel(String uri) {
        MultivaluedMap<String, String> params = new MultivaluedHashMap<>();
        params.putSingle(GRAPH_PARAM_NAME, uri);

        try (Response cr = new RetryingInvocationBuilder(
                applyParams(params).request(getReadableMediaTypes(Model.class)),
                defaultDelayMillis,
                maxRetryCount
        ).get()) {
            if (cr.getStatus() == Status.NOT_FOUND.getStatusCode()) {
                throw new NotFoundException();
            }
            return cr.readEntity(Model.class);
        }
    }

    @Override
    public void add(Model model) {
        MultivaluedMap<String, String> params = new MultivaluedHashMap<>();
        params.putSingle(DEFAULT_PARAM_NAME, Boolean.TRUE.toString());

        try (Response cr = new RetryingInvocationBuilder(
                applyParams(params).request(),
                defaultDelayMillis,
                maxRetryCount
        ).post(Entity.entity(model, getDefaultMediaType()))) {
            if (cr.getStatus() == Status.NOT_FOUND.getStatusCode()) {
                throw new NotFoundException();
            }
        }
    }

    @Override
    public void add(String uri, Model model) {
        MultivaluedMap<String, String> params = new MultivaluedHashMap<>();
        params.putSingle(GRAPH_PARAM_NAME, uri);

        try (Response cr = new RetryingInvocationBuilder(
                applyParams(params).request(),
                defaultDelayMillis,
                maxRetryCount
        ).post(Entity.entity(model, getDefaultMediaType()))) {
            if (cr.getStatus() == Status.NOT_FOUND.getStatusCode()) {
                throw new NotFoundException();
            }
        }
    }

    @Override
    public void putModel(Model model) {
        MultivaluedMap<String, String> params = new MultivaluedHashMap<>();
        params.putSingle(DEFAULT_PARAM_NAME, Boolean.TRUE.toString());

        try (Response cr = new RetryingInvocationBuilder(
                applyParams(params).request(),
                defaultDelayMillis,
                maxRetryCount
        ).put(Entity.entity(model, getDefaultMediaType()))) {
            if (cr.getStatus() == Status.NOT_FOUND.getStatusCode()) {
                throw new NotFoundException();
            }
        }
    }

    @Override
    public void putModel(String uri, Model model) {
        MultivaluedMap<String, String> params = new MultivaluedHashMap<>();
        params.putSingle(GRAPH_PARAM_NAME, uri);

        try (Response cr = new RetryingInvocationBuilder(
                applyParams(params).request(),
                defaultDelayMillis,
                maxRetryCount
        ).put(Entity.entity(model, getDefaultMediaType()))) {
            if (cr.getStatus() == Status.NOT_FOUND.getStatusCode()) {
                throw new NotFoundException();
            }
        }
    }

    @Override
    public void deleteDefault() {
        MultivaluedMap<String, String> params = new MultivaluedHashMap<>();
        params.putSingle(DEFAULT_PARAM_NAME, Boolean.TRUE.toString());

        try (Response cr = new RetryingInvocationBuilder(
                applyParams(params).request(),
                defaultDelayMillis,
                maxRetryCount
        ).delete()) {
            if (cr.getStatus() == Status.NOT_FOUND.getStatusCode()) {
                throw new NotFoundException();
            }
        }
    }

    @Override
    public void deleteModel(String uri) {
        MultivaluedMap<String, String> params = new MultivaluedHashMap<>();
        params.putSingle(GRAPH_PARAM_NAME, uri);

        try (Response cr = new RetryingInvocationBuilder(
                applyParams(params).request(),
                defaultDelayMillis,
                maxRetryCount
        ).delete()) {
            if (cr.getStatus() == Status.NOT_FOUND.getStatusCode()) {
                throw new NotFoundException();
            }
        }
    }
    
}
