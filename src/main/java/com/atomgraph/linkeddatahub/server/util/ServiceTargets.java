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
package com.atomgraph.linkeddatahub.server.util;

import com.atomgraph.linkeddatahub.dataspaces.model.Dataspace;
import jakarta.ws.rs.BadRequestException;
import java.net.URI;
import java.security.PrivateKey;
import java.time.Clock;
import java.time.Duration;
import java.util.function.Function;
import org.apache.jena.graph.Node;
import org.apache.jena.graph.NodeFactory;
import org.apache.jena.query.Query;
import org.apache.jena.sparql.syntax.Element;
import org.apache.jena.sparql.syntax.ElementService;
import org.apache.jena.sparql.syntax.syntaxtransform.ElementTransform;
import org.apache.jena.sparql.syntax.syntaxtransform.ElementTransformCopyBase;
import org.apache.jena.sparql.syntax.syntaxtransform.ExprTransformApplyElementTransform;
import org.apache.jena.sparql.syntax.syntaxtransform.QueryTransformOps;

/**
 * Decides, before the store runs a query, which <code>SERVICE</code> targets it may call, and marks each with the
 * agent who asked so the call can be made on their behalf.
 * <p>
 * The store executes <code>SERVICE</code> itself, and knows nobody. So the platform:
 * <ul>
 *   <li>refuses a target on the deployment's own network - a dataset of the store, the admin store through its cache,
 *       anything on loopback, which is the store's own JVM there - with <code>400</code>, <code>SILENT</code> or not,
 *       whether or not the deployment allows internal URLs elsewhere ({@link URLValidator#validateRemote(URI)}), since
 *       the store would read it past every ACL; and a target that is a variable, which cannot be decided before the query
 *       runs; a dataspace of this deployment is called through its SPARQL endpoint (<code>&lt;base&gt;sparql</code>),
 *       the door that guards it, and named any other way is <code>400</code>;</li>
 *   <li>removes any marker a query author wrote ({@link ServiceDelegation#strip}), and, with delegation on and an agent
 *       authenticated, writes its own on every <code>https</code> target ({@link ServiceDelegation#mark}): the agent's
 *       WebID, an expiry and the secretary's signature. The store's Fuseki module checks it and, where the target asks
 *       for a client certificate, calls it as the secretary with <code>On-Behalf-Of</code> naming the agent - so the
 *       target's own access control decides, as it does for a direct request; where it does not ask, the call stays
 *       anonymous. The same holds for a dataspace of another deployment.</li>
 * </ul>
 * Sub-queries and <code>EXISTS</code> patterns are rewritten too.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ServiceTargets
{

    /** The path of a dataspace's SPARQL endpoint under its base */
    public static final String SPARQL_PATH = "sparql";
    /** How long a marker holds: past the store's query timeout, which bounds every call a query makes */
    public static final Duration MARKER_TTL = Duration.ofMinutes(5);

    private final Function<URI, Dataspace> dataspaces;
    private final URLValidator validator;
    private final String host;
    private final String agent;
    private final PrivateKey key;
    private final Clock clock;

    /**
     * Constructs the decision for one query.
     *
     * @param dataspaces the dataspace of this deployment a URI belongs to, or <code>null</code> for none
     * @param validator the deployment's URL validator
     * @param host the deployment's host: a target on it or its subdomains is reached through the deployment's front door
     * @param agent the WebID of the agent who asked, or <code>null</code> for an anonymous query or delegation off
     * @param key the secretary's private key, or <code>null</code> for delegation off
     * @param clock the clock the markers expire by
     */
    public ServiceTargets(Function<URI, Dataspace> dataspaces, URLValidator validator, String host, String agent, PrivateKey key, Clock clock)
    {
        if (dataspaces == null) throw new IllegalArgumentException("Dataspace lookup cannot be null");
        if (validator == null) throw new IllegalArgumentException("URLValidator cannot be null");

        this.dataspaces = dataspaces;
        this.validator = validator;
        this.host = host;
        this.agent = agent;
        this.key = key;
        this.clock = clock;
    }

    /**
     * Returns the query with every <code>SERVICE</code> target decided and marked.
     *
     * @param query query as the client sent it
     * @return the query the store runs
     * @throws BadRequestException if a target is a variable, or a dataspace not named by its endpoint
     * @throws com.atomgraph.linkeddatahub.server.exception.InternalURLException if a target is an internal address
     */
    public Query rewrite(Query query)
    {
        if (query == null) throw new IllegalArgumentException("Query cannot be null");

        ElementTransform transform = new ElementTransformCopyBase()
        {

            @Override
            public Element transform(ElementService el, Node service, Element subElt)
            {
                Node target = target(service);
                if (target.equals(service) && subElt == el.getElement()) return el;
                return new ElementService(target, subElt, el.getSilent());
            }

        };

        return QueryTransformOps.transform(query, transform, new ExprTransformApplyElementTransform(transform));
    }

    /**
     * Decides one <code>SERVICE</code> target and returns what the store is to call.
     *
     * @param service the target as the query names it
     * @return the target without an author's marker, with the platform's when delegating
     */
    public Node target(Node service)
    {
        if (!service.isURI()) throw new BadRequestException("A SERVICE target must be an IRI: " + service + " cannot be decided before the query runs");

        String stripped = ServiceDelegation.strip(service.getURI());
        URI target = URI.create(stripped);
        Dataspace dataspace = getDataspaces().apply(target);
        if (dataspace != null)
        {
            URI endpoint = dataspace.getBaseURI().resolve(SPARQL_PATH);
            URI withoutQuery = URI.create(target.getScheme() + "://" + target.getRawAuthority() + target.getRawPath());
            if (!endpoint.equals(withoutQuery)) throw new BadRequestException("A dataspace is federated through its SPARQL endpoint <" + endpoint + ">, not <" + target + ">");
        }
        // an https target on the deployment's domain - its own origins, or another deployment under it - is reached through the
        // front door, as the platform's own requests are (ClientUriRewriteFilter) and the store's module routes them, never at
        // the address the name has on the internal network; a plain http one the store would call there itself
        else if (!(isOnDomain(target) && "https".equalsIgnoreCase(target.getScheme()))) getValidator().validateRemote(target);

        if (agent != null && key != null && "https".equalsIgnoreCase(target.getScheme()))
            return NodeFactory.createURI(ServiceDelegation.mark(stripped, agent, clock.instant().plus(MARKER_TTL), key));
        return stripped.equals(service.getURI()) ? service : NodeFactory.createURI(stripped);
    }

    /**
     * Returns true if the URI's host is the deployment's host or a subdomain of it.
     *
     * @param uri URI
     * @return true if on the deployment's domain
     */
    protected boolean isOnDomain(URI uri)
    {
        if (host == null || uri.getHost() == null) return false;
        return uri.getHost().equals(host) || uri.getHost().endsWith("." + host);
    }

    /**
     * Returns the lookup of a URI's dataspace.
     *
     * @return lookup function
     */
    public Function<URI, Dataspace> getDataspaces()
    {
        return dataspaces;
    }

    /**
     * Returns the URL validator.
     *
     * @return validator
     */
    public URLValidator getValidator()
    {
        return validator;
    }

}
