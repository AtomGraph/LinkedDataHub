/*
 * Copyright 2025 Martynas Jusevičius <martynas@atomgraph.com>.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.atomgraph.linkeddatahub.server.util;

import java.util.HashSet;
import java.util.Set;
import org.apache.jena.sparql.modify.request.UpdateModify;
import org.apache.jena.sparql.modify.request.UpdateVisitorBase;

/**
 * Visitor for SPARQL UPDATE operations to extract graph URIs from WITH clauses.
 * Used to validate batched SPARQL UPDATE requests and extract graph URIs for authorization checks.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class WithGraphVisitor extends UpdateVisitorBase
{

    private final Set<String> graphURIs = new HashSet<>();

    @Override
    public void visit(UpdateModify update)
    {
        if (update.getWithIRI() != null)
        {
            graphURIs.add(update.getWithIRI().toString());
        }
    }

    /**
     * Returns the set of graph URIs found in WITH clauses.
     *
     * @return set of graph URI strings
     */
    public Set<String> getGraphURIs()
    {
        return graphURIs;
    }

    /**
     * Returns true if all visited operations have WITH clauses.
     *
     * @param operationCount total number of operations that were visited
     * @return true if all operations have WITH clauses
     */
    public boolean allHaveWithClause(int operationCount)
    {
        return graphURIs.size() == operationCount;
    }

}
