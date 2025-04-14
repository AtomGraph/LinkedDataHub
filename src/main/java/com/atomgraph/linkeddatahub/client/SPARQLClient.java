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
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.client.Invocation;
import jakarta.ws.rs.client.WebTarget;
import jakarta.ws.rs.core.MultivaluedHashMap;
import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.core.Response;
import org.apache.jena.query.Query;
import org.apache.jena.update.UpdateRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


public class SPARQLClient extends com.atomgraph.core.client.SPARQLClient {

    private static final Logger log = LoggerFactory.getLogger(SPARQLClient.class);

    private final long defaultDelayMillis; // = 1000L;
    private final int maxRetryCount; // = 3;

    protected SPARQLClient(MediaTypes mediaTypes, WebTarget endpoint, int maxGetRequestSize, long defaultDelayMillis, int maxRetryCount) {
        super(mediaTypes, endpoint, maxGetRequestSize);
        this.defaultDelayMillis = defaultDelayMillis;
        this.maxRetryCount = maxRetryCount;
    }

    protected SPARQLClient(MediaTypes mediaTypes, WebTarget endpoint, long defaultDelayMillis, int maxRetryCount) {
        super(mediaTypes, endpoint);
        this.defaultDelayMillis = defaultDelayMillis;
        this.maxRetryCount = maxRetryCount;
    }

    public static SPARQLClient create(MediaTypes mediaTypes, WebTarget endpoint, int maxGetRequestSize, long defaultDelayMillis, int maxRetryCount) {
        return new SPARQLClient(mediaTypes, endpoint, maxGetRequestSize, defaultDelayMillis, maxRetryCount);
    }

    public static SPARQLClient create(MediaTypes mediaTypes, WebTarget endpoint, long defaultDelayMillis, int maxRetryCount) {
        return new SPARQLClient(mediaTypes, endpoint, defaultDelayMillis, maxRetryCount);
    }

    @Override
    public Response query(Query query, Class clazz, MultivaluedMap<String, String> params, MultivaluedMap<String, Object> headers) {
        if (params == null) {
            throw new IllegalArgumentException("params cannot be null");
        }
        if (headers == null) {
            throw new IllegalArgumentException("headers cannot be null");
        }

        MultivaluedMap<String, String> mergedParams = new MultivaluedHashMap<>();
        mergedParams.putAll(params);
        mergedParams.putSingle(QUERY_PARAM_NAME, query.toString());

        Invocation.Builder builder;
        if (getQueryURLLength(params) > getMaxGetRequestSize()) {
            builder = new RetryingInvocationBuilder(
                applyHeaders(getEndpoint().request(getReadableMediaTypes(clazz)), headers),
                defaultDelayMillis,
                maxRetryCount
            );
            return builder.post(Entity.form(mergedParams));
        } else {
            builder = new RetryingInvocationBuilder(
                applyHeaders(applyParams(mergedParams).request(getReadableMediaTypes(clazz)), headers),
                defaultDelayMillis,
                maxRetryCount
            );
            return builder.get();
        }
    }

    @Override
    public void update(UpdateRequest updateRequest, MultivaluedMap<String, String> params) {
        MultivaluedMap<String, String> formData = new MultivaluedHashMap<>();
        if (params != null) {
            formData.putAll(params);
        }
        formData.putSingle(UPDATE_PARAM_NAME, updateRequest.toString());

        new RetryingInvocationBuilder(
            getEndpoint().request(),
            defaultDelayMillis,
            maxRetryCount
        ).post(Entity.form(formData)).close();
    }

} 
