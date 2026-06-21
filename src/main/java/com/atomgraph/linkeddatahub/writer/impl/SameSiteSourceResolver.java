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

import com.atomgraph.client.util.RDFSourceResolver;
import com.atomgraph.core.client.GraphStoreClient;
import com.atomgraph.client.util.jena.PrefixGraphRepository;
import com.google.common.net.InternetDomainName;
import java.net.URI;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * XSLT source resolver that restricts dereferencing of uncached URIs to the same site as the
 * application. Mapped (bundled) and same-site URIs resolve; arbitrary external URIs do not.
 * Backed by a {@link PrefixGraphRepository}; authenticated delegation is handled by the supplied
 * {@link GraphStoreClient}.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class SameSiteSourceResolver extends RDFSourceResolver
{
    private static final Logger log = LoggerFactory.getLogger(SameSiteSourceResolver.class);

    private final URI rootContextURI;

    /**
     * Constructs the resolver.
     *
     * @param repository graph repository (bundled/cached graphs + URI→location mapping)
     * @param gsc Graph Store client (with delegation)
     * @param resolvingUncached true if uncached URLs are resolved
     * @param rootContextURI the root URI of the JAX-RS application
     */
    public SameSiteSourceResolver(PrefixGraphRepository repository, GraphStoreClient gsc, boolean resolvingUncached, URI rootContextURI)
    {
        super(repository, gsc, resolvingUncached);
        this.rootContextURI = rootContextURI;
    }

    @Override
    protected boolean resolvingUncached(String filenameOrURI)
    {
        if (super.resolvingUncached(filenameOrURI) && !getRepository().isMapped(filenameOrURI))
        {
            // Allow resolving URIs from the same site (e.g., localhost:4443/static/..., admin.localhost:4443/ns)
            return isSameSite(getRootContextURI(), URI.create(filenameOrURI));
        }

        return false;
    }

    /**
     * Checks if two URIs are from the same site (schemeful same-site).
     * Allows subdomains like admin.localhost and localhost to be considered part of the same instance.
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

            if (host1.equals("localhost") || host1.endsWith(".localhost"))
                return host2.equals("localhost") || host2.endsWith(".localhost");

            if (domain1.isTopPrivateDomain() && domain2.isTopPrivateDomain())
                return domain1.equals(domain2);
            if (domain1.hasPublicSuffix() && domain2.hasPublicSuffix())
                return domain1.topPrivateDomain().equals(domain2.topPrivateDomain());

            return false;
        }
        catch (IllegalArgumentException ex)
        {
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

}
