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
import com.atomgraph.linkeddatahub.model.auth.Agent;
import com.atomgraph.linkeddatahub.server.exception.auth.AuthorizationException;
import com.atomgraph.linkeddatahub.server.security.DataspaceAuthorization;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import jakarta.ws.rs.BadRequestException;
import java.net.URI;
import java.util.function.Function;
import org.apache.jena.graph.Node;
import org.apache.jena.graph.NodeFactory;
import org.apache.jena.query.Query;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.sparql.syntax.Element;
import org.apache.jena.sparql.syntax.ElementService;
import org.apache.jena.sparql.syntax.syntaxtransform.ElementTransform;
import org.apache.jena.sparql.syntax.syntaxtransform.ElementTransformCopyBase;
import org.apache.jena.sparql.syntax.syntaxtransform.ExprTransformApplyElementTransform;
import org.apache.jena.sparql.syntax.syntaxtransform.QueryTransformOps;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Rewrites the <code>SERVICE</code> clauses of a query before the store runs it, so that a query federates across the
 * dataspaces of this deployment under the agent's own access rights.
 * <p>
 * A query names another dataspace by its public SPARQL endpoint, <code>SERVICE &lt;https://people.example/sparql&gt;</code>,
 * the address a person would also query directly. The store that runs the query knows no agent, so left as it is the
 * clause would either fail (the store reaches public addresses only, through the egress proxy) or, pointed at the
 * sibling dataset's own address, read what the ACL never granted. So the platform decides for each clause before the
 * query goes out:
 * <ul>
 *   <li>a target that is a dataspace of this deployment is authorized for the agent as a <code>GET</code> of that
 *       endpoint would be - public read, or <code>acl:Read</code> on the endpoint in that dataspace's admin store - and
 *       the target becomes the dataspace's store, the address the platform itself queries it at; a refusal is a
 *       <code>403</code> naming the endpoint, for the whole query;</li>
 *   <li>a dataspace named by anything but its SPARQL endpoint is refused with <code>400</code>: documents are read
 *       through the endpoint's query, not reached by <code>SERVICE</code>;</li>
 *   <li>any other target is validated as a remote address ({@link URLValidator#validateRemote(URI)}): an internal or
 *       loopback address is refused with <code>400</code>, whether or not the deployment allows internal URLs
 *       elsewhere, a public one is left as it is and the store calls it through its egress proxy, as before;</li>
 *   <li>a target that is a variable is refused with <code>400</code>: it cannot be authorized before the query runs.</li>
 * </ul>
 * <code>SILENT</code> is kept: it suppresses a failure of the call, not the decision whether the call may be made.
 * Sub-queries and <code>EXISTS</code> patterns are rewritten too.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ServiceRewriter
{

    private static final Logger log = LoggerFactory.getLogger(ServiceRewriter.class);

    /** The path of a dataspace's SPARQL endpoint under its base */
    public static final String SPARQL_PATH = "sparql";

    private final Function<URI, Dataspace> dataspaces;
    private final DataspaceAuthorization authorization;
    private final URLValidator validator;
    private final Agent agent;

    /**
     * Constructs the rewriter for one agent.
     *
     * @param dataspaces the dataspace a URI belongs to, or <code>null</code> for none of this deployment's
     * @param authorization the access control decision
     * @param validator the deployment's URL validator
     * @param agent the agent the query is run for, or <code>null</code> for an anonymous one
     */
    public ServiceRewriter(Function<URI, Dataspace> dataspaces, DataspaceAuthorization authorization, URLValidator validator, Agent agent)
    {
        if (dataspaces == null) throw new IllegalArgumentException("Dataspace lookup cannot be null");
        if (authorization == null) throw new IllegalArgumentException("DataspaceAuthorization cannot be null");
        if (validator == null) throw new IllegalArgumentException("URLValidator cannot be null");

        this.dataspaces = dataspaces;
        this.authorization = authorization;
        this.validator = validator;
        this.agent = agent;
    }

    /**
     * Returns the query with every <code>SERVICE</code> target decided.
     * A query without <code>SERVICE</code> comes back as it is.
     *
     * @param query query as the client sent it
     * @return query for the store
     * @throws AuthorizationException if the agent may not read a dataspace a clause names
     * @throws BadRequestException if a target cannot be decided
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
                return new ElementService(target(service), subElt, el.getSilent());
            }

        };

        return QueryTransformOps.transform(query, transform, new ExprTransformApplyElementTransform(transform));
    }

    /**
     * Returns the node the store is to call for a <code>SERVICE</code> target.
     *
     * @param service the target as the query names it
     * @return the target for the store
     */
    public Node target(Node service)
    {
        if (!service.isURI()) throw new BadRequestException("A SERVICE target must be an IRI: " + service + " cannot be authorized before the query runs");

        URI target = URI.create(service.getURI());
        Dataspace dataspace = getDataspaces().apply(target);
        if (dataspace != null)
        {
            URI endpoint = dataspace.getBaseURI().resolve(SPARQL_PATH);
            if (!endpoint.equals(target)) throw new BadRequestException("A dataspace is federated through its SPARQL endpoint <" + endpoint + ">, not <" + target + ">");

            if (!dataspace.isReadAllowed() &&
                    getAuthorization().authorize(dataspace, ResourceFactory.createResource(endpoint.toString()), getAgent(), ACL.Read) == null)
            {
                if (log.isDebugEnabled()) log.debug("SERVICE <{}> not authorized for agent {}", target, getAgent());
                throw new AuthorizationException("Access to the SERVICE endpoint not authorized", target, ACL.Read, getAgent());
            }

            Node store = NodeFactory.createURI(dataspace.getService().getSPARQLEndpoint().getURI());
            if (log.isDebugEnabled()) log.debug("SERVICE <{}> authorized for agent {}, rewritten to <{}>", target, getAgent(), store);
            return store;
        }

        getValidator().validateRemote(target);
        return service;
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
     * Returns the access control decision.
     *
     * @return authorization
     */
    public DataspaceAuthorization getAuthorization()
    {
        return authorization;
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

    /**
     * Returns the agent the query runs for.
     *
     * @return agent or null
     */
    public Agent getAgent()
    {
        return agent;
    }

}
