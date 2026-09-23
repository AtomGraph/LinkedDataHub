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
     * Clears this application's cached graphs and every assembled imports closure from memory.
     *
     * With an ontology URI, the proxy caches for it are purged as well and its closure is reassembled
     * before the response returns, so the next request already reads the new version. Without one,
     * nothing is reassembled and the closures rebuild lazily - which is what a caller wanting only a
     * cold cache, such as a test harness, should ask for.
     *
     * @param ontologyURI ontology URI, or null to clear without reloading anything
     * @param referer the referring URL
     * @return JAX-RS response
     */
    @POST
    @Consumes(MediaType.APPLICATION_FORM_URLENCODED)
    public Response post(@FormParam("uri") String ontologyURI, @HeaderParam("Referer") URI referer)
    {
        // resolve both apps regardless of which one the request matched: /clear is admin, but Settings
        // delegates here on the end-user app (its PATCH origin), and both backends need purging either way
        final EndUserApplication endUserApp;
        final AdminApplication adminApp;
        if (getApplication().canAs(AdminApplication.class))
        {
            adminApp = getApplication().as(AdminApplication.class);
            endUserApp = adminApp.getEndUserApplication();
        }
        else
        {
            endUserApp = getApplication().as(EndUserApplication.class);
            adminApp = endUserApp.getAdminApplication();
        }
        OntologyRepository repository = getSystem().getRepository(endUserApp);

        // The request-scoped app is a snapshot ApplicationFilter captured before Settings.updateApp swapped
        // the context dataset copy-on-write, so on a PATCH /settings that just added an ldh:import its import
        // set is stale. Re-read from the current dataspace model, which reads the volatile contextDataset fresh
        com.atomgraph.linkeddatahub.apps.model.Application currentApp = getSystem().getDataspaceModel(endUserApp).getResource(endUserApp.getURI()).as(com.atomgraph.linkeddatahub.apps.model.Application.class);

        // A package's ontology becomes editable by being copied into this application's own ontologies
        // container. Above the cache guard on purpose: the guard skips everything when the ontology was never
        // loaded, which is every cold start, and materializing has to happen there too. Idempotent, and a
        // failure leaves the package resolving to its bundled copy read-only, as before this existed
        getSystem().getPackageService().materialize(currentApp, endUserApp);

        // Everything cached goes, not the keys derived from this one URI. Assembling a closure resolves and
        // caches every URI it imports - vocabularies, package ontologies - and those were evicted by nothing,
        // so a graph outlived the document it came from and kept answering until the JVM restarted. A tracked
        // set of what a closure resolved would be correct only as far as the set is, and an incomplete one
        // fails silently, which is the failure this replaces. A clear is explicit, owner-only and rare
        if (log.isDebugEnabled()) log.debug("Clearing the graph cache of application <{}>", endUserApp.getURI());
        repository.clear();
        // the union graphs are keyed by ontology URI in a map the whole webapp shares, and an application
        // contributes more than one: ClearOntology caches a union under whatever URI was posted, and the
        // constructor editor posts a document URI. So there is no key that means "this application's union",
        // and the unions built over the graphs just discarded have to go with them. Other dataspaces rebuild
        // on their next request from a repository still warm, which is wasted work rather than staleness
        getSystem().getOntologyGraphs().clear();

        // Emptying the JVM caches is only half a clear: the closures rebuild by re-querying the admin SPARQL
        // endpoint, and that read goes through the backend proxy, which was left holding everything it had, so
        // the rebuild pulls the discarded graphs straight back in. Purging the key of the one ontology named
        // here would not cover it, for the same reason the graph cache above is emptied wholesale rather than
        // by key: assembling a closure resolves every URI it imports, each cached under its own graph URI.
        // Hence the shared key every ontology response also carries - one purge, every ontology response, and
        // nothing else, which a URL ban of this proxy could not manage since it fronts the store itself and
        // holds every other read the platform makes. Measured: a vocabulary's document deleted and /clear
        // posted, and the closure came back still holding the deleted graph, served by the proxy rather than
        // by the store. Unconditional, because the reload below re-reads every import too, and refilling a
        // warm JVM with a stale answer is worse than rebuilding lazily from a cold one
        URI adminBackendProxy = getSystem().getServiceContext(adminApp.getService()).getBackendProxy();
        if (adminBackendProxy != null)
        {
            // A URL-pattern BAN cannot single these out: on a SPARQL proxy every req.url is /ds/?query=...,
            // which never contains the ontology URI, and that is why ontology reloads were reading stale
            // CONSTRUCTs before any of this existed. The xkey index is the only handle on them
            if (log.isDebugEnabled()) log.debug("XKEY-PURGE every ontology response from the admin backend proxy cache");
            xkeyPurge(adminBackendProxy, OntologyRepository.ONTOLOGY_XKEY);
        }

        if (ontologyURI != null)
        {
            URI ontologyDocURI = UriBuilder.fromUri(ontologyURI).fragment(null).build(); // skip fragment from the ontology URI to get its graph URI
            // the frontend caches whole documents rather than SPARQL responses and carries no xkey tags, so the
            // ontology document is evicted there by URL pattern (until Stage 3 brings xkey tagging to varnish-frontend)
            URI frontendProxy = getSystem().getFrontendProxy();
            if (frontendProxy != null)
            {
                if (log.isDebugEnabled()) log.debug("Purge ontology document with URI '{}' from frontend proxy cache", ontologyDocURI);
                ban(frontendProxy, ontologyDocURI.toString(), false);
            }

            // !!! we need to reload the ontology model before returning a response, to make sure the next request already gets the new version !!!
            // The request-scoped endUserApp is a snapshot ApplicationFilter captured before Settings.updateApp
            // swapped the context dataset copy-on-write, so on a PATCH /settings that just added an ldh:import
            // its import set is stale. Re-read the app from the current (post-write) dataspace model -
            // getDataspaceModel reads the volatile contextDataset fresh, keyed by URI - so the rebuilt closure
            // reflects the persisted import set rather than the pre-write snapshot.
            getSystem().getOntologyGraphs().put(ontologyURI, OntologyFilter.loadOntology(repository, ontologyURI, getSystem().getPackageService().getOntologies(currentApp)));
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
