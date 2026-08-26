/*
 * Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.atomgraph.linkeddatahub.cli.http;

import com.atomgraph.core.MediaTypes;
import com.atomgraph.core.client.GraphStoreClient;
import com.atomgraph.linkeddatahub.cli.util.URIRewriter;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.client.WebTarget;
import jakarta.ws.rs.core.Form;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.net.URI;

/**
 * Graph Store Protocol client for LinkedDataHub documents (direct graph identification),
 * extended with SPARQL update over PATCH and form-encoded POST. When a proxy URI is given,
 * every request URI has its origin rewritten to the proxy's origin, matching the
 * <code>--proxy</code> handling of the <code>bin/</code> shell scripts.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class LDHClient extends GraphStoreClient
{

    /** SPARQL update media type */
    public static final MediaType APPLICATION_SPARQL_UPDATE_TYPE = MediaType.valueOf("application/sparql-update");

    private final URI proxy;

    /**
     * Constructs the client.
     *
     * @param client Jersey client with WebID client certificate
     * @param mediaTypes registry of readable/writable media types
     * @param proxy proxy URI whose origin replaces the request URI origin (optional, can be null)
     */
    public LDHClient(Client client, MediaTypes mediaTypes, URI proxy)
    {
        super(client, mediaTypes);
        this.proxy = proxy;
    }

    @Override
    protected WebTarget getWebTarget(URI uri)
    {
        return super.getWebTarget(getProxy() != null ? URIRewriter.rewrite(uri, getProxy()) : uri);
    }

    /**
     * Patches a document with a SPARQL update.
     *
     * @param uri document URI
     * @param update SPARQL update string
     * @return response
     */
    public Response patch(URI uri, String update)
    {
        return getWebTarget(uri).request().method("PATCH", Entity.entity(update, APPLICATION_SPARQL_UPDATE_TYPE));
    }

    /**
     * Posts a form-encoded request.
     *
     * @param uri target URI
     * @param form form params
     * @param acceptedTypes accepted response media types
     * @return response
     */
    public Response postForm(URI uri, Form form, MediaType... acceptedTypes)
    {
        return getWebTarget(uri).request(acceptedTypes).post(Entity.form(form));
    }

    /**
     * Returns the proxy URI, if any.
     *
     * @return proxy URI or null
     */
    public URI getProxy()
    {
        return proxy;
    }

}
