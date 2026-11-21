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
package com.atomgraph.linkeddatahub.server.security;

import com.atomgraph.linkeddatahub.client.SesameProtocolClient;
import com.atomgraph.linkeddatahub.dataspaces.model.Dataspace;
import com.atomgraph.linkeddatahub.dataspaces.model.EndUserDataspace;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.util.AuthorizationParams;
import com.atomgraph.linkeddatahub.server.util.DocumentContext;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.spinrdf.vocabulary.SPIN;
import jakarta.ws.rs.core.Response;
import org.apache.jena.query.ParameterizedSparqlString;
import org.apache.jena.query.QuerySolutionMap;
import org.apache.jena.query.ResultSet;
import org.apache.jena.query.ResultSetRewindable;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Resource;

/**
 * The access control decision for a resource of any dataspace of this deployment.
 * One decision serves both dataspaces of a pair: the document context query reads what the dataspace's store says of
 * the resource - itself, its ancestors, its types and its owner, each from the resource's own graph - and the ACL
 * query matches the authorizations in the pair's admin store against it. The
 * {@link com.atomgraph.linkeddatahub.server.filter.request.AuthorizationFilter} decides this way for the request's
 * dataspace; a query that federates to another dataspace of this deployment
 * ({@link com.atomgraph.linkeddatahub.server.util.ServiceRewriter}) decides it for the dataspace each
 * <code>SERVICE</code> clause names, since the store the clause reaches holds no notion of the agent.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class DataspaceAuthorization
{

    private final com.atomgraph.linkeddatahub.Application system;
    private final ParameterizedSparqlString documentContextQuery, aclQuery;

    /**
     * Constructs the decision over the system's queries.
     *
     * @param system system application
     */
    public DataspaceAuthorization(com.atomgraph.linkeddatahub.Application system)
    {
        if (system == null) throw new IllegalArgumentException("Application cannot be null");

        this.system = system;
        documentContextQuery = new ParameterizedSparqlString(system.getDocumentContextQuery().toString());
        aclQuery = new ParameterizedSparqlString(system.getACLQuery().toString());
    }

    /**
     * Returns the agent's authorizations granting the access mode on a resource of a dataspace, or <code>null</code>
     * if none does.
     *
     * @param dataspace the dataspace the resource belongs to
     * @param accessTo resource URI
     * @param agent agent resource or null
     * @param accessMode ACL access mode
     * @return authorizations model or null if access denied
     */
    public Model authorize(Dataspace dataspace, Resource accessTo, Resource agent, Resource accessMode)
    {
        return authorize(dataspace, accessTo, getDocumentContext(dataspace, accessTo), agent, accessMode);
    }

    /**
     * Returns the agent's authorizations granting the access mode on a resource of a dataspace, given what the
     * dataspace's store says of it, or <code>null</code> if none does.
     * The authorizations of every mode the agent holds are returned, so a caller can tell every mode the agent has.
     *
     * @param dataspace the dataspace the resource belongs to
     * @param accessTo resource URI
     * @param context what the dataspace's store says of the resource
     * @param agent agent resource or null
     * @param accessMode ACL access mode
     * @return authorizations model or null if access denied
     */
    public Model authorize(Dataspace dataspace, Resource accessTo, DocumentContext context, Resource agent, Resource accessMode)
    {
        if (dataspace == null) throw new IllegalArgumentException("Dataspace cannot be null");
        if (accessTo == null) throw new IllegalArgumentException("Resource cannot be null");
        if (context == null) throw new IllegalArgumentException("DocumentContext cannot be null");
        if (accessMode == null) throw new IllegalArgumentException("Access mode cannot be null");

        ParameterizedSparqlString pss = new ParameterizedSparqlString(context.applyTo(getACLQuery().asQuery()).toString());
        Model authorizations = loadModel(getAdminService(dataspace), pss, new AuthorizationParams(getAdminBase(dataspace), accessTo, agent, context.isOwner(agent)).get());

        // access denied if the agent has no authorization to the requested document with the requested ACL mode
        if (getAuthorizationByMode(authorizations, accessMode) == null) return null;

        return authorizations;
    }

    /**
     * Returns what a dataspace's store says of a document, for the ACL query to match authorizations against.
     *
     * @param dataspace the dataspace the document belongs to
     * @param document document URI
     * @return document context
     */
    public DocumentContext getDocumentContext(Dataspace dataspace, Resource document)
    {
        if (dataspace == null) throw new IllegalArgumentException("Dataspace cannot be null");
        if (document == null) throw new IllegalArgumentException("Resource cannot be null");

        QuerySolutionMap qsm = new QuerySolutionMap();
        qsm.add(SPIN.THIS_VAR_NAME, document);

        ResultSetRewindable result = loadResultSet(dataspace.getService(), getDocumentContextQuery(), qsm);
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
     * Returns an authorization that grants the access mode, or <code>null</code> if none in the model does.
     * A grant of a mode covers the modes it covers ({@link AccessModes#covering(Resource)}).
     *
     * @param authModel model with authorizations
     * @param accessMode ACL access mode
     * @return authorization resource or null
     */
    public static Resource getAuthorizationByMode(Model authModel, Resource accessMode)
    {
        return AccessModes.covering(accessMode).stream().
            flatMap(mode -> authModel.listResourcesWithProperty(ACL.mode, mode).toList().stream()).
            findFirst().
            orElse(null);
    }

    /**
     * Returns the SPARQL service holding a dataspace's authorizations: its admin dataspace's, or its own when it is
     * the admin dataspace.
     *
     * @param dataspace dataspace
     * @return service resource
     */
    public static Service getAdminService(Dataspace dataspace)
    {
        return dataspace.canAs(EndUserDataspace.class) ?
            dataspace.as(EndUserDataspace.class).getAdminDataspace().getService() :
            dataspace.getService();
    }

    /**
     * Returns the base URI of the dataspace holding a dataspace's authorizations.
     *
     * @param dataspace dataspace
     * @return admin dataspace's base URI
     */
    public static Resource getAdminBase(Dataspace dataspace)
    {
        return dataspace.canAs(EndUserDataspace.class) ?
            dataspace.as(EndUserDataspace.class).getAdminDataspace().getBase() :
            dataspace.getBase();
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
    public Model loadModel(Service service, ParameterizedSparqlString pss, QuerySolutionMap qsm)
    {
        if (service == null) throw new IllegalArgumentException("Service cannot be null");
        if (pss == null) throw new IllegalArgumentException("ParameterizedSparqlString cannot be null");
        if (qsm == null) throw new IllegalArgumentException("QuerySolutionMap cannot be null");

        // send query bindings separately from the query if the service supports the Sesame protocol
        com.atomgraph.linkeddatahub.model.ServiceContext serviceContext = getSystem().getServiceContext(service);
        if (serviceContext.getSPARQLClient() instanceof SesameProtocolClient sesameProtocolClient)
            try (Response cr = sesameProtocolClient.query(pss.asQuery(), Model.class, qsm))
            {
                return cr.readEntity(Model.class);
            }
        else
        {
            pss.setParams(qsm);
            try (Response cr = serviceContext.getSPARQLClient().query(pss.asQuery(), Model.class))
            {
                return cr.readEntity(Model.class);
            }
        }
    }

    /**
     * Loads SPARQL result set from a service.
     *
     * @param service SPARQL service
     * @param pss query string
     * @param qsm query solution map (applied to the query string or sent as request params, depending on the protocol)
     * @return result set
     */
    public ResultSetRewindable loadResultSet(Service service, ParameterizedSparqlString pss, QuerySolutionMap qsm)
    {
        if (service == null) throw new IllegalArgumentException("Service cannot be null");
        if (pss == null) throw new IllegalArgumentException("ParameterizedSparqlString cannot be null");
        if (qsm == null) throw new IllegalArgumentException("QuerySolutionMap cannot be null");

        // send query bindings separately from the query if the service supports the Sesame protocol
        com.atomgraph.linkeddatahub.model.ServiceContext serviceContext = getSystem().getServiceContext(service);
        if (serviceContext.getSPARQLClient() instanceof SesameProtocolClient sesameProtocolClient)
            try (Response cr = sesameProtocolClient.query(pss.asQuery(), ResultSet.class, qsm))
            {
                return cr.readEntity(ResultSetRewindable.class);
            }
        else
        {
            pss.setParams(qsm);
            try (Response cr = serviceContext.getSPARQLClient().query(pss.asQuery(), ResultSet.class))
            {
                return cr.readEntity(ResultSetRewindable.class);
            }
        }
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

    /**
     * Returns a query that loads what a dataspace's store says of a document.
     *
     * @return SPARQL string
     */
    public ParameterizedSparqlString getDocumentContextQuery()
    {
        return documentContextQuery.copy();
    }

    /**
     * Returns authorization query.
     * Used on the documents of either dataspace.
     *
     * @return SPARQL string
     */
    public ParameterizedSparqlString getACLQuery()
    {
        return aclQuery.copy();
    }

}
