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
import org.apache.jena.rdf.model.Model;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.client.WebTarget;
import jakarta.ws.rs.core.EntityTag;
import jakarta.ws.rs.core.Form;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.MultivaluedHashMap;
import jakarta.ws.rs.core.MultivaluedMap;
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
        MediaType[] acceptedTypes = getReadableMediaTypes(Model.class);

        return applyHeaders(getWebTarget(uri).request(acceptedTypes), ifMatch(uri, acceptedTypes, new MultivaluedHashMap())).
            method("PATCH", Entity.entity(update, APPLICATION_SPARQL_UPDATE_TYPE));
    }

    @Override
    public Response post(URI uri, Entity entity, MediaType[] acceptedTypes, MultivaluedMap<String, Object> headers)
    {
        MediaType[] negotiated = negotiated(acceptedTypes);

        return super.post(uri, entity, negotiated, ifMatch(uri, negotiated, headers));
    }

    @Override
    public Response put(URI uri, Entity entity, MediaType[] acceptedTypes, MultivaluedMap<String, Object> headers)
    {
        MediaType[] negotiated = negotiated(acceptedTypes);

        return super.put(uri, entity, negotiated, ifMatch(uri, negotiated, headers));
    }

    @Override
    public Response delete(URI uri, MediaType[] acceptedTypes, MultivaluedMap<String, String> params, MultivaluedMap<String, Object> headers)
    {
        MediaType[] negotiated = negotiated(acceptedTypes);

        return super.delete(uri, negotiated, params, ifMatch(uri, negotiated, headers));
    }

    /**
     * The media types a write negotiates, which is never "whatever the server prefers". Asking for nothing in
     * particular gets the HTML shell, whose entity tag is a different variant's and which no write will match;
     * an RDF client wants RDF back in any case.
     *
     * @param acceptedTypes the types the caller asked for, possibly none
     * @return those types, or the readable RDF ones when the caller named none
     */
    protected MediaType[] negotiated(MediaType[] acceptedTypes)
    {
        return acceptedTypes.length > 0 ? acceptedTypes : getReadableMediaTypes(Model.class);
    }

    /**
     * Adds <code>If-Match</code> for the document's current state, so a write says which state it was written
     * against. The server requires it of any write to a document that already exists, because it applies one by
     * reading the graph, changing it in memory and writing the whole thing back - two unconditional writers
     * overwrite each other with nothing to show for it. A document that does not exist yet has no validator and
     * is left unconditional, which is what creating one is.
     *
     * The entity tag is read with the same accepted types the write will send, because it identifies a
     * negotiated variant rather than the graph alone: the same document answers a different tag as RDF/XML
     * than as Turtle, and a write quoting the wrong one is refused with 412.
     *
     * @param uri document URI
     * @param acceptedTypes the media types the write itself accepts
     * @param headers headers to extend
     * @return the same headers, carrying If-Match where the document has an entity tag
     */
    protected MultivaluedMap<String, Object> ifMatch(URI uri, MediaType[] acceptedTypes, MultivaluedMap<String, Object> headers)
    {
        if (headers.containsKey(HttpHeaders.IF_MATCH)) return headers;

        final EntityTag entityTag;
        try (Response response = head(uri, acceptedTypes))
        {
            entityTag = response.getStatusInfo().getFamily() == Response.Status.Family.SUCCESSFUL ? response.getEntityTag() : null;
        }
        catch (Exception ex) // a document that cannot be read cannot be matched against; let the write answer
        {
            return headers;
        }

        if (entityTag != null) headers.putSingle(HttpHeaders.IF_MATCH, entityTag.toString());

        return headers;
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
