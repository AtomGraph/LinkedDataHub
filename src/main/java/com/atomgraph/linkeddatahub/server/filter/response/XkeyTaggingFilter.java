/**
 *  Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.server.filter.response;

import com.atomgraph.linkeddatahub.dataspaces.model.AdminDataspace;
import com.atomgraph.linkeddatahub.dataspaces.model.Dataspace;
import com.atomgraph.linkeddatahub.dataspaces.model.EndUserDataspace;
import java.io.IOException;
import java.net.URI;
import java.util.LinkedHashSet;
import java.util.Optional;
import java.util.Set;
import jakarta.annotation.Priority;
import jakarta.inject.Inject;
import jakarta.ws.rs.HttpMethod;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerResponseContext;
import jakarta.ws.rs.container.ContainerResponseFilter;

/**
 * Tags responses with surrogate keys for the frontend cache (Varnish <code>vmod_xkey</code>), so that a write can evict
 * them by what they are rather than by URL. The frontend cache knows a response only by its path and
 * <code>Host</code>; the platform knows a document by its absolute URI, and an access-control change does not name the
 * documents it affects at all. Tagging is what lets {@link CacheInvalidationFilter} and the ontology clear purge them.
 * <p>
 * A response carries three keys: the absolute URI of the document requested (query string excluded, so every view of a
 * document shares it), the URI of its parent container, and the access-control scope of its dataspace (see
 * {@link #getAccessControlScope(Dataspace)}). The keys are opaque to the cache; tagger and purger only have to agree on
 * the strings, which is why both build them with the methods here.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
@Priority(Priorities.USER + 350)
public class XkeyTaggingFilter implements ContainerResponseFilter
{

    /**
     * Name of the response header <code>vmod_xkey</code> indexes. The frontend cache removes it on delivery.
     */
    public static final String HEADER_NAME = "xkey";

    @Inject com.atomgraph.linkeddatahub.Application system;
    @Inject jakarta.inject.Provider<Optional<Dataspace>> app;

    @Override
    public void filter(ContainerRequestContext request, ContainerResponseContext response) throws IOException
    {
        if (getSystem().getFrontendProxy() == null) return; // no frontend cache to index the tags
        if (!HttpMethod.GET.equals(request.getMethod()) && !HttpMethod.HEAD.equals(request.getMethod())) return; // only reads are cached

        Optional<Dataspace> dataspace = getDataspace();
        if (dataspace == null || !dataspace.isPresent()) return;

        Set<String> tags = getTags(request.getUriInfo().getAbsolutePath(), dataspace.get().getBaseURI(), getAccessControlScope(dataspace.get()));
        response.getHeaders().putSingle(HEADER_NAME, String.join(" ", tags));
    }

    /**
     * Returns the surrogate keys of a response.
     *
     * @param documentURI absolute URI of the requested document, without the query string
     * @param baseURI base URI of the dataspace
     * @param accessControlScope the dataspace's access-control scope, or null
     * @return ordered set of keys
     */
    public static Set<String> getTags(URI documentURI, URI baseURI, String accessControlScope)
    {
        if (documentURI == null) throw new IllegalArgumentException("Document URI cannot be null");

        Set<String> tags = new LinkedHashSet<>();
        tags.add(documentURI.toString());
        URI parentURI = getParent(documentURI, baseURI);
        if (parentURI != null) tags.add(parentURI.toString());
        if (accessControlScope != null) tags.add(accessControlScope);

        return tags;
    }

    /**
     * Returns the parent container of a document: the URI one path segment up. The dataspace's root has none.
     *
     * @param documentURI absolute document URI
     * @param baseURI base URI of the dataspace, or null
     * @return parent URI, or null for the root
     */
    public static URI getParent(URI documentURI, URI baseURI)
    {
        if (documentURI.equals(baseURI) || documentURI.getPath() == null || documentURI.getPath().isEmpty() || documentURI.getPath().equals("/")) return null;

        return documentURI.resolve(documentURI.getPath().endsWith("/") ? ".." : ".").normalize();
    }

    /**
     * Returns the key every response of a dataspace pair carries, so that a change to the pair's access control can evict
     * all of them at once: authorizations, agents and groups live in the admin dataspace and decide who may read any
     * document of its end-user dataspace. The key is the admin dataspace's URI, for the end-user dataspace and the admin
     * one alike.
     *
     * @param dataspace end-user or admin dataspace
     * @return the scope key, or null when the dataspace has no admin pairing
     */
    public static String getAccessControlScope(Dataspace dataspace)
    {
        if (dataspace.canAs(EndUserDataspace.class))
        {
            AdminDataspace admin = dataspace.as(EndUserDataspace.class).getAdminDataspace();
            return admin != null ? admin.getURI() : null;
        }
        if (dataspace.canAs(AdminDataspace.class)) return dataspace.getURI();

        return null;
    }

    /**
     * Returns the current dataspace.
     *
     * @return optional dataspace
     */
    public Optional<Dataspace> getDataspace()
    {
        return app.get();
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
