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
import com.atomgraph.linkeddatahub.server.filter.response.CacheInvalidationFilter;
import com.atomgraph.linkeddatahub.server.util.OntologyRepository;
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
import com.atomgraph.linkeddatahub.server.filter.request.OntologyFilter;
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
        OntologyRepository repository = getSystem().getRepository(endUserApp);
        if (repository.isCached(ontologyURI))
        {
            if (log.isDebugEnabled()) log.debug("Clearing ontology with URI '{}' from memory", ontologyURI);
            repository.remove(ontologyURI);

            URI ontologyDocURI = UriBuilder.fromUri(ontologyURI).fragment(null).build(); // skip fragment from the ontology URI to get its graph URI
            // frontend proxy still uses URL-pattern BAN for direct document GETs (until Stage 3 brings xkey tagging to varnish-frontend).
            // xkey purge covers proxied SPARQL CONSTRUCT/SELECT responses tagged by their backend (varnish-admin / varnish-end-user).
            URI frontendProxy = getSystem().getFrontendProxy();
            if (frontendProxy != null)
            {
                if (log.isDebugEnabled()) log.debug("Purge ontology document with URI '{}' from frontend proxy cache", ontologyDocURI);
                ban(frontendProxy, ontologyDocURI.toString(), false);
            }
            URI adminBackendProxy = getSystem().getServiceContext(getApplication().getService()).getBackendProxy();
            if (adminBackendProxy != null)
            {
                // URL-pattern BAN of the ontology URI is a no-op on the SPARQL proxy (its req.url namespace is /ds/?query=...,
                // never containing the ontology URI as path), which is exactly why ontology reloads were getting stale CONSTRUCTs.
                // xkey-purge of the same tag set by OntologyModelGetter's X-Xkey-Promote is what actually invalidates here.
                if (log.isDebugEnabled()) log.debug("XKEY-PURGE ontology with URI '{}' from admin backend proxy cache", ontologyURI);
                xkeyPurge(adminBackendProxy, ontologyURI);
            }
            URI endUserBackendProxy = getSystem().getServiceContext(endUserApp.getService()).getBackendProxy();
            if (endUserBackendProxy != null)
            {
                // same reasoning as adminBackendProxy above. End-user proxy xkey-purge is no-op until Stage 2 lights up its VCL.
                if (log.isDebugEnabled()) log.debug("XKEY-PURGE ontology with URI '{}' from end-user backend proxy cache", ontologyURI);
                xkeyPurge(endUserBackendProxy, ontologyURI);
            }
            
            // !!! we need to reload the ontology model before returning a response, to make sure the next request already gets the new version !!!
            OntologyFilter.loadOntology(repository, ontologyURI);
        }
        
        if (referer != null) return Response.seeOther(referer).build();
        else return Response.ok().build();
    }
    
    public void ban(URI proxyURI, String url)
    {
        ban(proxyURI, url, true);
    }

    /**
     * Bans URL from the backend proxy cache.
     *
     * @param proxyURI proxy server URI
     * @param url banned URL
     * @param urlEncode if true, the banned URL value will be URL-encoded
     */
    public void ban(URI proxyURI, String url, boolean urlEncode)
    {
        if (url == null) throw new IllegalArgumentException("URL cannot be null");

        // Extract path from URL - Varnish req.url only contains the path, not the full URL
        URI uri = URI.create(url);
        String path = uri.getPath();
        if (uri.getQuery() != null) path += "?" + uri.getQuery();

        final String urlValue = urlEncode ? UriComponent.encode(path, UriComponent.Type.UNRESERVED) : path;

        try (Response cr = getSystem().getClient().target(proxyURI).
                request().
                header(CacheInvalidationFilter.HEADER_NAME, urlValue).
                method("BAN", Response.class))
        {
            // Response automatically closed by try-with-resources
        }
    }

    /**
     * Surrogate-key purge: surgically evicts every cached object the proxy indexed with the given xkey tag.
     * No URL parsing — xkey matches the tag byte-for-byte against {@code beresp.http.xkey} set in VCL.
     *
     * @param proxyURI proxy server URI
     * @param tag xkey tag to purge (typically an absolute resource/graph URI)
     */
    public void xkeyPurge(URI proxyURI, String tag)
    {
        if (proxyURI == null) throw new IllegalArgumentException("Proxy URI cannot be null");
        if (tag == null) throw new IllegalArgumentException("Tag cannot be null");

        try (Response cr = getSystem().getClient().target(proxyURI).
                request().
                header("xkey-purge", tag).
                method("XKEY-PURGE", Response.class))
        {
            if (log.isDebugEnabled()) log.debug("XKEY-PURGE on {} for tag '{}' returned status {}", proxyURI, tag, cr.getStatus());
        }
        catch (Exception ex)
        {
            if (log.isErrorEnabled()) log.error("XKEY-PURGE failed for tag: " + tag, ex);
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
