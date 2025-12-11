/**
 *  Copyright 2019 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.writer.impl;

import org.apache.jena.util.LocationMapper;
import java.net.URI;
import com.atomgraph.core.client.LinkedDataClient;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.google.common.net.InternetDomainName;
import java.util.Map;
import org.apache.jena.rdf.model.Model;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Manager for remote RDF dataset access.
 * Documents can be mapped to local copies.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class DataManagerImpl extends com.atomgraph.client.util.DataManagerImpl
{
    private static final Logger log = LoggerFactory.getLogger(DataManagerImpl.class);
    
    private final URI rootContextURI;
    private final AgentContext agentContext;

    /**
     * Constructs RDF data manager.
     * 
     * @param mapper location mapper
     * @param modelCache model cache
     * @param ldc Linked Data client
     * @param cacheModelLoads true if loaded RDF models are cached
     * @param preemptiveAuth true if HTTP basic auth is sent preemptively
     * @param resolvingUncached true if uncached URLs are resolved
     * @param rootContextURI the root URI of the JAX-RS application
     * @param agentContext agent context
     */
    public DataManagerImpl(LocationMapper mapper, Map<String, Model> modelCache,
            LinkedDataClient ldc,
            boolean cacheModelLoads, boolean preemptiveAuth, boolean resolvingUncached,
            URI rootContextURI,
            AgentContext agentContext)
    {
        super(mapper, modelCache, ldc, cacheModelLoads, preemptiveAuth, resolvingUncached);
        this.rootContextURI = rootContextURI;
        this.agentContext = agentContext;
    }
    
    @Override
    public boolean resolvingUncached(String filenameOrURI)
    {
        if (super.resolvingUncached(filenameOrURI) && !isMapped(filenameOrURI))
        {
            // Allow resolving URIs from the same site (e.g., localhost:4443/static/..., admin.localhost:4443/ns)
            return isSameSite(getRootContextURI(), URI.create(filenameOrURI));
        }

        return false; // super.resolvingUncached(filenameOrURI); // configured in web.xml
    }

    /**
     * Checks if two URIs are from the same site (schemeful same-site).
     * This allows subdomains like admin.localhost and localhost to be considered part of the same LinkedDataHub instance.
     * Ports are ignored per the same-site definition.
     *
     * @param uri1 first URI
     * @param uri2 second URI
     * @return true if both URIs are from the same site
     */
    private boolean isSameSite(URI uri1, URI uri2)
    {
        if (uri1 == null || uri2 == null) return false;
        if (!uri1.getScheme().equals(uri2.getScheme())) return false;

        String host1 = uri1.getHost();
        String host2 = uri2.getHost();

        if (host1 == null || host2 == null) return false;
        if (host1.equals(host2)) return true;

        try
        {
            InternetDomainName domain1 = InternetDomainName.from(host1);
            InternetDomainName domain2 = InternetDomainName.from(host2);

            // For localhost domains, compare the full host (localhost == localhost, admin.localhost != localhost at domain level)
            // But we want to treat them as same root domain, so just check if both end with "localhost"
            if (host1.equals("localhost") || host1.endsWith(".localhost"))
                return host2.equals("localhost") || host2.endsWith(".localhost");

            // For regular domains, compare top private domains
            if (domain1.isTopPrivateDomain() && domain2.isTopPrivateDomain())
                return domain1.equals(domain2);
            if (domain1.hasPublicSuffix() && domain2.hasPublicSuffix())
                return domain1.topPrivateDomain().equals(domain2.topPrivateDomain());

            return false;
        }
        catch (IllegalArgumentException ex)
        {
            // Invalid domain name, fall back to simple equality check
            if (log.isDebugEnabled()) log.debug("Could not parse domain names for comparison: {} and {}", host1, host2);
            return false;
        }
    }

    /**
     * Returns the root URI of the JAX-RS application.
     * 
     * @return root URI
     */
    public URI getRootContextURI()
    {
        return rootContextURI;
    }

    /**
     * Returns the agent context.
     * 
     * @return agent context or null
     */
    public AgentContext getAgentContext()
    {
        return agentContext;
    }
    
}