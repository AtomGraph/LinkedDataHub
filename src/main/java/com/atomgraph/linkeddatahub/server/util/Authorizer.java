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

import com.atomgraph.linkeddatahub.client.SesameProtocolClient;
import com.atomgraph.linkeddatahub.dataspaces.model.Dataspace;
import com.atomgraph.linkeddatahub.dataspaces.model.EndUserDataspace;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.security.AccessModes;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.spinrdf.vocabulary.SPIN;
import jakarta.ws.rs.core.Response;
import java.net.URI;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.apache.jena.graph.NodeFactory;
import org.apache.jena.query.ParameterizedSparqlString;
import org.apache.jena.query.Query;
import org.apache.jena.query.QuerySolutionMap;
import org.apache.jena.query.ResultSet;
import org.apache.jena.query.ResultSetRewindable;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.sparql.core.Var;
import org.apache.jena.sparql.engine.binding.Binding;
import org.apache.jena.sparql.syntax.ElementData;
import org.apache.jena.sparql.syntax.ElementFilter;
import org.apache.jena.sparql.syntax.ElementGroup;

/**
 * The authorization decision of a dataspace, in both of its directions. For one document it reads the document's
 * context from the dataspace's store (the document context query) and matches the agent's authorizations in the admin
 * dataset against it (the ACL query). For a query it reads the agent's authorizations with the document left open,
 * as {@link Grants}, which the document context query then checks graph by graph inside the query.
 * The two queries are the configuration's (<code>web.xml</code>); nothing here restates what they decide.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see com.atomgraph.linkeddatahub.vocabulary.LDHC#documentContextQuery
 * @see com.atomgraph.linkeddatahub.vocabulary.LDHC#aclQuery
 */
public class Authorizer
{

    /** The access mode variable of the ACL query. */
    public static final String MODE_VAR_NAME = "Mode";

    private final com.atomgraph.linkeddatahub.Application system;
    private final Dataspace dataspace;

    /**
     * Constructs the decision of a dataspace.
     *
     * @param system system application
     * @param dataspace the dataspace whose documents are decided
     */
    public Authorizer(com.atomgraph.linkeddatahub.Application system, Dataspace dataspace)
    {
        if (system == null) throw new IllegalArgumentException("Application cannot be null");
        if (dataspace == null) throw new IllegalArgumentException("Dataspace cannot be null");

        this.system = system;
        this.dataspace = dataspace;
    }

    /**
     * Returns what the dataspace's store says of a document, for the ACL query to match authorizations against.
     *
     * @param document document URI
     * @return document context
     */
    public DocumentContext getDocumentContext(Resource document)
    {
        QuerySolutionMap qsm = new QuerySolutionMap();
        qsm.add(SPIN.THIS_VAR_NAME, document);

        ResultSetRewindable result = loadResultSet(getDataspace().getService(), new ParameterizedSparqlString(getSystem().getDocumentContextQuery().toString()), qsm);
        try
        {
            return new DocumentContext(result);
        }
        finally
        {
            result.close();
        }
    }

    /**
     * Returns all of the agent's authorizations on a document, whatever their modes.
     *
     * @param context what the dataspace's store says of the document
     * @param agent agent resource or null
     * @return authorizations model (can be empty)
     */
    public Model getAuthorizations(DocumentContext context, Resource agent)
    {
        if (context == null) throw new IllegalArgumentException("DocumentContext cannot be null");

        ParameterizedSparqlString pss = new ParameterizedSparqlString(context.applyTo(getSystem().getACLQuery()).toString());
        return loadModel(getAdminService(), pss, new AuthorizationParams(getAdminBase(), agent, context.isOwner(agent)).get());
    }

    /**
     * Returns the agent's authorizations on a document, or null if none of them carries the access mode.
     * The authorizations returned are all of the agent's on the document, whatever their modes, so that the
     * <code>AuthorizationContext</code> knows every mode the agent has.
     *
     * @param context what the dataspace's store says of the document
     * @param agent agent resource or null
     * @param accessMode ACL access mode
     * @return authorizations model or null if access denied
     */
    public Model authorize(DocumentContext context, Resource agent, Resource accessMode)
    {
        Model authorizations = getAuthorizations(context, agent);

        // access denied if the agent has no authorization to the requested document with the requested ACL mode
        if (getAuthorizationByMode(authorizations, accessMode) == null) return null;

        return authorizations;
    }

    /**
     * Returns what the agent may access with the given mode, for any document of the dataspace.
     * The ACL query runs with the document left open: without the context rows a document would bind, its
     * <code>(?Rel ?Target)</code> are the rows the agent's authorizations name, kept where their mode covers the
     * requested one. It runs once more as the owner, since <code>lacl:OwnerAgent</code> applies only on a document the
     * agent owns: what that adds holds on the condition <code>(acl:owner agent)</code>.
     *
     * @param agent agent resource or null
     * @param accessMode ACL access mode
     * @return grants
     */
    public Grants getGrants(Resource agent, Resource accessMode)
    {
        if (accessMode == null) throw new IllegalArgumentException("Access mode cannot be null");

        Query contextQuery = getSystem().getDocumentContextQuery();
        String base = getDataspace().getBase().getURI();
        // what AuthorizationFilter skips for GET and HEAD, the dataspace's graphs are all readable for
        if (ACL.Read.equals(accessMode) && getDataspace().isReadAllowed()) return new Grants(contextQuery.getQueryPattern(), base, true, List.of(), Map.of());

        List<Grants.Row> rows = getGrantRows(agent, false, accessMode);
        List<Grants.Row> ownerRows = agent != null ? getGrantRows(agent, true, accessMode) : List.of();
        return Grants.of(contextQuery.getQueryPattern(), base, agent, rows, ownerRows);
    }

    /**
     * Returns the <code>(?Rel ?Target)</code> rows the agent's authorizations name with a mode covering the given one.
     * The ACL query's pattern is selected without its <code>VALUES</code> block, the fail-closed default that a
     * document's context replaces: with no document, the rows are what the pattern binds.
     *
     * @param agent agent resource or null
     * @param owner true to read the authorizations of the agent as an owner
     * @param accessMode ACL access mode
     * @return rows
     */
    protected List<Grants.Row> getGrantRows(Resource agent, boolean owner, Resource accessMode)
    {
        ResultSetRewindable result = loadResultSet(getAdminService(), new ParameterizedSparqlString(getGrantQuery(getSystem().getACLQuery(), accessMode).toString()),
            new AuthorizationParams(getAdminBase(), agent, owner).get());
        try
        {
            return Grants.rows(result);
        }
        finally
        {
            result.close();
        }
    }

    /**
     * Returns the query that reads the <code>(?Rel ?Target)</code> rows an agent's authorizations name with a mode
     * covering the given one: the ACL query's pattern, selected without its <code>VALUES</code> block - the fail-closed
     * default that a document's context replaces - so that with no document the rows are what the pattern binds.
     *
     * @param aclQuery the ACL query
     * @param accessMode ACL access mode
     * @return <code>SELECT DISTINCT ?Rel ?Target</code> query
     */
    public static Query getGrantQuery(Query aclQuery, Resource accessMode)
    {
        Var mode = Var.alloc(MODE_VAR_NAME);
        ElementGroup pattern = new ElementGroup();
        pattern.addElement(aclQuery.getQueryPattern());
        pattern.addElement(new ElementData(List.of(mode), AccessModes.covering(accessMode).stream().
            map(covering -> Binding.builder().add(mode, covering.asNode()).build()).
            toList()));

        Query grantQuery = new Query();
        grantQuery.setPrefixMapping(aclQuery.getPrefixMapping());
        grantQuery.setQuerySelectType();
        grantQuery.setDistinct(true);
        grantQuery.addResultVar(DocumentContext.REL_VAR_NAME);
        grantQuery.addResultVar(DocumentContext.TARGET_VAR_NAME);
        grantQuery.setQueryPattern(pattern);
        return grantQuery;
    }

    /**
     * Returns the graphs of the list that the grants reach, asking the dataspace's store once for all of them.
     *
     * @param graphs graph URIs
     * @param grants what the agent may access
     * @return the reachable graph URIs, in the order given
     */
    public List<URI> readable(List<URI> graphs, Grants grants)
    {
        if (graphs == null) throw new IllegalArgumentException("Graph list cannot be null");
        if (grants == null) throw new IllegalArgumentException("Grants cannot be null");
        if (graphs.isEmpty() || grants.isEmpty()) return List.of();

        Var graph = Var.alloc("g");
        Query query = new Query();
        query.setQuerySelectType();
        query.setDistinct(true);
        query.addResultVar(graph);
        ElementGroup pattern = new ElementGroup();
        pattern.addElement(new ElementData(List.of(graph), graphs.stream().
            map(uri -> Binding.builder().add(graph, NodeFactory.createURI(uri.toString())).build()).
            toList()));
        query.setQueryPattern(pattern);
        pattern.addElement(new ElementFilter(grants.guard(graph, ReadableGraphsTransform.prefixes(query))));

        Set<String> reachable = new LinkedHashSet<>();
        ResultSetRewindable result = loadResultSet(getDataspace().getService(), new ParameterizedSparqlString(query.toString()), new QuerySolutionMap());
        try
        {
            result.forEachRemaining(row -> reachable.add(row.getResource(graph.getVarName()).getURI()));
        }
        finally
        {
            result.close();
        }

        return graphs.stream().filter(uri -> reachable.contains(uri.toString())).toList();
    }

    /**
     * Returns an authorization from the given model whose mode covers the given access mode: the mode itself, or
     * a mode it is a subclass of in the ACL ontology - a grant of <code>acl:Write</code> covers <code>acl:Append</code>.
     *
     * @param authModel model with authorizations
     * @param accessMode ACL access mode
     * @return authorization resource or null
     * @see AccessModes#covering(Resource)
     */
    public static Resource getAuthorizationByMode(Model authModel, Resource accessMode)
    {
        return AccessModes.covering(accessMode).stream().
            flatMap(mode -> authModel.listResourcesWithProperty(ACL.mode, mode).toList().stream()).
            findFirst().
            orElse(null);
    }

    /**
     * Loads RDF graph from a service.
     *
     * @param service SPARQL service
     * @param pss auth query string
     * @param qsm query solution map (applied to the query string or sent as request params, depending on the protocol)
     * @return authorization graph (can be empty)
     * @see com.atomgraph.linkeddatahub.vocabulary.LDHC#aclQuery
     */
    protected Model loadModel(Service service, ParameterizedSparqlString pss, QuerySolutionMap qsm)
    {
        if (service == null) throw new IllegalArgumentException("Service cannot be null");
        if (pss == null) throw new IllegalArgumentException("ParameterizedSparqlString cannot be null");
        if (qsm == null) throw new IllegalArgumentException("QuerySolutionMap cannot be null");

        // send query bindings separately from the query if the service supports the Sesame protocol
        com.atomgraph.linkeddatahub.model.ServiceContext serviceContext = getSystem().getServiceContext(service);
        if (serviceContext.getSPARQLClient() instanceof SesameProtocolClient sesameProtocolClient)
            try (Response cr = sesameProtocolClient.query(pss.asQuery(), Model.class, qsm)) // register(new CacheControlFilter(CacheControl.valueOf("no-cache"))). // add Cache-Control: no-cache to request
            {
                return cr.readEntity(Model.class);
            }
        else
        {
            pss.setParams(qsm);
            try (Response cr = serviceContext.getSPARQLClient(). // register(new CacheControlFilter(CacheControl.valueOf("no-cache"))). // add Cache-Control: no-cache to request
                query(pss.asQuery(), Model.class))
            {
                return cr.readEntity(Model.class);
            }
        }
    }

    /**
     * Loads SPARQL result set from a service.
     *
     * @param service SPARQL service
     * @param pss auth query string
     * @param qsm query solution map (applied to the query string or sent as request params, depending on the protocol)
     * @return result set
     * @see com.atomgraph.linkeddatahub.vocabulary.LDHC#aclQuery
     */
    protected ResultSetRewindable loadResultSet(Service service, ParameterizedSparqlString pss, QuerySolutionMap qsm)
    {
        if (service == null) throw new IllegalArgumentException("Service cannot be null");
        if (pss == null) throw new IllegalArgumentException("ParameterizedSparqlString cannot be null");
        if (qsm == null) throw new IllegalArgumentException("QuerySolutionMap cannot be null");

        // send query bindings separately from the query if the service supports the Sesame protocol
        com.atomgraph.linkeddatahub.model.ServiceContext serviceContext = getSystem().getServiceContext(service);
        if (serviceContext.getSPARQLClient() instanceof SesameProtocolClient sesameProtocolClient)
            try (Response cr = sesameProtocolClient.query(pss.asQuery(), ResultSet.class, qsm)) // register(new CacheControlFilter(CacheControl.valueOf("no-cache"))). // add Cache-Control: no-cache to request
            {
                return cr.readEntity(ResultSetRewindable.class);
            }
        else
        {
            pss.setParams(qsm);
            try (Response cr = serviceContext.getSPARQLClient(). // register(new CacheControlFilter(CacheControl.valueOf("no-cache"))). // add Cache-Control: no-cache to request
                query(pss.asQuery(), ResultSet.class))
            {
                return cr.readEntity(ResultSetRewindable.class);
            }
        }
    }

    /**
     * Returns the SPARQL service for agent data.
     *
     * @return service resource
     */
    public Service getAdminService()
    {
        return getDataspace().canAs(EndUserDataspace.class) ?
            getDataspace().as(EndUserDataspace.class).getAdminDataspace().getService() :
            getDataspace().getService();
    }

    /**
     * Returns the base URI of the admin application.
     * Authorization data is always stored in the admin application's dataspace.
     *
     * @return admin application's base URI
     */
    public Resource getAdminBase()
    {
        return getDataspace().canAs(EndUserDataspace.class) ?
            getDataspace().as(EndUserDataspace.class).getAdminDataspace().getBase() :
            getDataspace().getBase();
    }

    /**
     * Returns the dataspace whose documents are decided.
     *
     * @return dataspace
     */
    public Dataspace getDataspace()
    {
        return dataspace;
    }

    /**
     * Returns system application.
     *
     * @return JAX-RS application
     */
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }

}
