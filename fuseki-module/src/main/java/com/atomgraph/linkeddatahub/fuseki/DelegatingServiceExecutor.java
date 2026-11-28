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
package com.atomgraph.linkeddatahub.fuseki;

import java.net.URI;
import java.security.PublicKey;
import java.time.Clock;
import java.util.Optional;
import java.util.function.Supplier;
import org.apache.jena.atlas.logging.Log;
import org.apache.jena.graph.NodeFactory;
import org.apache.jena.query.ARQ;
import org.apache.jena.query.QueryExecException;
import org.apache.jena.sparql.algebra.op.OpService;
import org.apache.jena.sparql.engine.ExecutionContext;
import org.apache.jena.sparql.engine.QueryIterator;
import org.apache.jena.sparql.engine.binding.Binding;
import org.apache.jena.sparql.engine.iterator.QueryIter;
import org.apache.jena.sparql.engine.iterator.QueryIterCommonParent;
import org.apache.jena.sparql.engine.iterator.QueryIterSingleton;
import org.apache.jena.sparql.exec.http.Service;
import org.apache.jena.sparql.service.single.ChainingServiceExecutor;
import org.apache.jena.sparql.service.single.ServiceExecutor;
import org.apache.jena.sparql.util.Context;

/**
 * Executes a <code>SERVICE</code> call the platform marked ({@link ServiceDelegation}) on behalf of the agent who asked
 * the query; passes every other call on unchanged.
 * <p>
 * For a marked call: the marker is checked against the secretary's certificate and refused if forged, partial or
 * expired - the query fails, <code>SILENT</code> or not, since a forged marker is an attack and not a failed call. Then
 * the target, without the marker, is asked whether it wants a client certificate ({@link Routes#asksForCertificate}):
 * <ul>
 *   <li>if it does, the call is made as the secretary with <code>On-Behalf-Of</code> naming the agent, the identity
 *       the platform's Linked Data proxy already sends a write with; the target's own access control decides, as for
 *       any request, and a refusal there fails the call as a refused call fails (<code>SILENT</code> applies);</li>
 *   <li>if it does not, the call is made anonymously, as before the marker: the agent is not announced to an endpoint
 *       that does not ask who is calling.</li>
 * </ul>
 * The call itself is Jena's own (<code>Service.exec</code>), given the route's client and a request modifier that
 * adds the headers, through a copy of the query's context; the result is tracked and joined with the incoming binding
 * as Jena's HTTP executor does it.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class DelegatingServiceExecutor implements ChainingServiceExecutor
{

    /** The header naming the agent the secretary acts for, as LinkedDataHub's <code>WebIDFilter</code> reads it */
    public static final String ON_BEHALF_OF = "On-Behalf-Of";

    /**
     * What the executor delegates with: the secretary's public key, which the markers are signed with, and how calls
     * reach their targets.
     *
     * @param secretary the secretary's public key
     * @param routes the routes
     */
    public record Delegation(PublicKey secretary, Routes routes) { }

    private final Supplier<Delegation> delegation;
    private final Clock clock;

    /**
     * Constructs the executor.
     *
     * @param delegation what to delegate with, asked for at the first marked call (the secretary's keystore may not
     *        exist yet when the store starts); null from it means no key is configured and every marker is dropped, an
     *        exception that it is configured but not ready, which fails the call
     * @param clock the clock the markers' expiry is checked against
     */
    public DelegatingServiceExecutor(Supplier<Delegation> delegation, Clock clock)
    {
        this.delegation = delegation;
        this.clock = clock;
    }

    @Override
    public QueryIterator createExecution(OpService opExecute, OpService opOriginal, Binding binding, ExecutionContext execCxt, ServiceExecutor chain)
    {
        if (!opExecute.getService().isURI()) return chain.createExecution(opExecute, opOriginal, binding, execCxt);

        Optional<ServiceDelegation.Marked> marker;
        try
        {
            marker = ServiceDelegation.parse(opExecute.getService().getURI());
        }
        catch (IllegalArgumentException ex)
        {
            throw new QueryExecException(ex.getMessage());
        }
        if (marker.isEmpty()) return chain.createExecution(opExecute, opOriginal, binding, execCxt);

        ServiceDelegation.Marked marked = marker.get();
        Delegation with;
        try
        {
            with = delegation.get();
        }
        catch (RuntimeException ex)
        {
            throw new QueryExecException("SERVICE <" + marked.target() + "> cannot be called on behalf of its agent yet: " + ex.getMessage());
        }
        if (with == null) // not configured: the marker is dropped, never sent on
            return chain.createExecution(withTarget(opExecute, marked.target()), opOriginal, binding, execCxt);
        Routes routes = with.routes();
        if (!ServiceDelegation.verify(marked, with.secretary(), clock.instant()))
            throw new QueryExecException("The delegation marker on SERVICE <" + marked.target() + "> is not valid: forged or expired");

        Routes.Route route = routes.route(marked.target());
        if (!routes.asksForCertificate(route)) return chain.createExecution(withTarget(opExecute, marked.target()), opOriginal, binding, execCxt);

        Context context = execCxt.getContext().copy();
        context.set(Service.httpQueryClient, routes.client(route));
        context.set(ARQ.httpRequestModifer, (org.apache.jena.http.sys.HttpRequestModifier)(params, headers) ->
        {
            headers.put(ON_BEHALF_OF, marked.agent().toString());
            if (route.host() != null) headers.put("Host", route.host());
        });
        OpService delegated = withTarget(opExecute, route.url());
        try
        {
            QueryIterator qIter = Service.exec(delegated, context);
            if (qIter == null) throw new QueryExecException("No SERVICE handler");
            return new QueryIterCommonParent(QueryIter.makeTracked(qIter, execCxt), binding, execCxt);
        }
        catch (RuntimeException ex)
        {
            if (opExecute.getSilent())
            {
                Log.warn(this, "SERVICE <" + marked.target() + "> on behalf of <" + marked.agent() + ">: " + ex.getMessage());
                return QueryIterSingleton.create(binding, execCxt);
            }
            throw ex;
        }
    }

    private static OpService withTarget(OpService op, URI target)
    {
        return new OpService(NodeFactory.createURI(target.toString()), op.getSubOp(), op.getServiceElement(), op.getSilent());
    }

}
