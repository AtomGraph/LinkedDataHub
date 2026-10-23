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

import com.atomgraph.linkeddatahub.vocabulary.ACL;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import org.apache.jena.query.Query;
import org.apache.jena.query.QuerySolution;
import org.apache.jena.query.ResultSet;
import org.apache.jena.rdf.model.RDFNode;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.sparql.core.Var;
import org.apache.jena.sparql.engine.binding.Binding;

/**
 * What the authorization decision knows of a document: the rows of the document context query.
 * The <code>acl:owner</code> rows name the agents that are <code>lacl:OwnerAgent</code> on the document; every other row
 * is a <code>(?Rel ?Target)</code> pair the ACL query matches authorizations against.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see com.atomgraph.linkeddatahub.vocabulary.LDHC#documentContextQuery
 */
public class DocumentContext
{

    /** The tag variable of a row. */
    public static final String REL_VAR_NAME = "Rel";
    /** The node variable of a row. */
    public static final String TARGET_VAR_NAME = "Target";

    private final List<Binding> targets;
    private final Set<Resource> types, owners;

    /**
     * Constructs the context from the result of the document context query.
     *
     * @param resultSet rows of the document context query
     */
    public DocumentContext(ResultSet resultSet)
    {
        if (resultSet == null) throw new IllegalArgumentException("ResultSet cannot be null");

        List<Binding> targets = new ArrayList<>();
        Set<Resource> types = new HashSet<>(), owners = new HashSet<>();
        while (resultSet.hasNext())
        {
            QuerySolution row = resultSet.next();
            Resource rel = row.getResource(REL_VAR_NAME);
            RDFNode target = row.get(TARGET_VAR_NAME);
            if (rel == null || target == null || !target.isResource()) continue;

            if (rel.equals(ACL.owner)) owners.add(target.asResource());
            else
            {
                if (rel.equals(ACL.accessToClass)) types.add(target.asResource());
                targets.add(Binding.builder().
                    add(Var.alloc(REL_VAR_NAME), rel.asNode()).
                    add(Var.alloc(TARGET_VAR_NAME), target.asNode()).
                    build());
            }
        }

        this.targets = Collections.unmodifiableList(targets);
        this.types = Collections.unmodifiableSet(types);
        this.owners = Collections.unmodifiableSet(owners);
    }

    /**
     * Sets the document's <code>(?Rel ?Target)</code> rows as the <code>VALUES</code> block of the ACL query. A document
     * with no rows leaves the query's fail-closed default in place.
     *
     * @param query ACL query
     * @return the query
     */
    public Query applyTo(Query query)
    {
        if (query == null) throw new IllegalArgumentException("Query cannot be null");

        if (!getTargets().isEmpty())
            query.setValuesDataBlock(List.of(Var.alloc(REL_VAR_NAME), Var.alloc(TARGET_VAR_NAME)), getTargets());

        return query;
    }

    /**
     * Returns the <code>(?Rel ?Target)</code> rows, without the owners.
     *
     * @return rows
     */
    public List<Binding> getTargets()
    {
        return targets;
    }

    /**
     * Returns the document's types, as its own graph states them.
     *
     * @return types
     */
    public Set<Resource> getTypes()
    {
        return types;
    }

    /**
     * Returns the document's owners, as its own graph states them.
     *
     * @return owners
     */
    public Set<Resource> getOwners()
    {
        return owners;
    }

    /**
     * Returns true if the agent is an owner of the document.
     *
     * @param agent agent, or null for an anonymous one
     * @return true if it owns the document
     */
    public boolean isOwner(Resource agent)
    {
        return agent != null && getOwners().contains(agent);
    }

}
