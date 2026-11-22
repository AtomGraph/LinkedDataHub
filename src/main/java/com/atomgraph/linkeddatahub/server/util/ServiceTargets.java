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
import java.util.function.Function;
import org.apache.jena.graph.Node;
import org.apache.jena.query.Query;
import org.apache.jena.sparql.syntax.Element;
import org.apache.jena.sparql.syntax.ElementService;
import org.apache.jena.sparql.syntax.syntaxtransform.ElementTransform;
import org.apache.jena.sparql.syntax.syntaxtransform.ElementTransformCopyBase;
import org.apache.jena.sparql.syntax.syntaxtransform.ExprTransformApplyElementTransform;
import org.apache.jena.sparql.syntax.syntaxtransform.QueryTransformOps;

/**
 * Decides, before the store runs a query, which <code>SERVICE</code> targets it may call at all.
 * <p>
 * The store executes <code>SERVICE</code> as an anonymous client, so a target on the deployment's own network - a
 * dataset of the store itself, the admin store through its cache, anything on loopback, which is the store's own
 * JVM there - would read what the ACL never granted. The platform refuses such a target with <code>400</code> before
 * the query goes out, <code>SILENT</code> or not (<code>SILENT</code> suppresses a failed call, not whether the call may
 * be made), and whether or not the deployment allows internal URLs elsewhere ({@link URLValidator#validateRemote(URI)}).
 * A target that is a variable is refused too: it cannot be decided before the query runs.
 * <p>
 * A target that is one of this deployment's dataspaces, named by its SPARQL endpoint (<code>&lt;base&gt;sparql</code>),
 * is the platform's own door and is left to it: that door authenticates the caller and applies the dataspace's ACL,
 * as to any request. A dataspace named by anything else is <code>400</code>, since documents are read through the
 * endpoint's query. Today the call arrives there anonymous, so it succeeds only where the dataspace allows public
 * read; carrying the asking agent's identity through the store to that door, and to a dataspace of another
 * deployment, is designed and not built (OpsGraph, "federated dataspaces"). Any other target is left as it is and the
 * store calls it through its egress proxy. Sub-queries and <code>EXISTS</code> patterns are walked too.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ServiceTargets
{

    /** The path of a dataspace's SPARQL endpoint under its base */
    public static final String SPARQL_PATH = "sparql";

    private final Function<URI, Dataspace> dataspaces;
    private final URLValidator validator;

    /**
     * Constructs the decision.
     *
     * @param dataspaces the dataspace of this deployment a URI belongs to, or <code>null</code> for none
     * @param validator the deployment's URL validator
     */
    public ServiceTargets(Function<URI, Dataspace> dataspaces, URLValidator validator)
    {
        if (dataspaces == null) throw new IllegalArgumentException("Dataspace lookup cannot be null");
        if (validator == null) throw new IllegalArgumentException("URLValidator cannot be null");

        this.dataspaces = dataspaces;
        this.validator = validator;
    }

    /**
     * Returns the query, every <code>SERVICE</code> target of it decided.
     *
     * @param query query as the client sent it
     * @return the same query
     * @throws BadRequestException if a target is a variable, or a dataspace not named by its endpoint
     * @throws com.atomgraph.linkeddatahub.server.exception.InternalURLException if a target is an internal address
     */
    public Query check(Query query)
    {
        if (query == null) throw new IllegalArgumentException("Query cannot be null");

        ElementTransform transform = new ElementTransformCopyBase()
        {

            @Override
            public Element transform(ElementService el, Node service, Element subElt)
            {
                check(service);
                return el;
            }

        };

        QueryTransformOps.transform(query, transform, new ExprTransformApplyElementTransform(transform));
        return query;
    }

    /**
     * Decides one <code>SERVICE</code> target.
     *
     * @param service the target as the query names it
     */
    public void check(Node service)
    {
        if (!service.isURI()) throw new BadRequestException("A SERVICE target must be an IRI: " + service + " cannot be decided before the query runs");

        URI target = URI.create(service.getURI());
        Dataspace dataspace = getDataspaces().apply(target);
        if (dataspace != null)
        {
            URI endpoint = dataspace.getBaseURI().resolve(SPARQL_PATH);
            if (!endpoint.equals(target)) throw new BadRequestException("A dataspace is federated through its SPARQL endpoint <" + endpoint + ">, not <" + target + ">");
            return; // the platform's own door decides
        }

        getValidator().validateRemote(target);
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
