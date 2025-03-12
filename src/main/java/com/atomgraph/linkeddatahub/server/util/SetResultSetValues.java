/**
 *  Copyright 2025 Martynas Jusevičius <martynas@atomgraph.com>
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

import java.util.ArrayList;
import java.util.List;
import java.util.function.BiFunction;
import org.apache.jena.query.Query;
import org.apache.jena.query.ResultSet;
import org.apache.jena.sparql.core.Var;
import org.apache.jena.sparql.engine.binding.Binding;

/**
 *
 * @author Martynas.Jusevicius
 */
public class SetResultSetValues implements BiFunction<Query, ResultSet, Query>
{

     /**
     * Converts a SPARQL result set into a <code>VALUES</code> block and appends it to the given query.
     * 
     * @param query SPARQL query
     * @param resultSet result set
     * @return query with appended values
     */
    @Override
    public Query apply(Query query, ResultSet resultSet)
    {
        if (query == null) throw new IllegalArgumentException("Query cannot be null");
        if (resultSet == null) throw new IllegalArgumentException("ResultSet cannot be null");
        
        List<Var> vars = resultSet.getResultVars().stream().map(Var::alloc).toList();
        List<Binding> values = new ArrayList<>();
        while (resultSet.hasNext())
            values.add(resultSet.nextBinding());

        query.setValuesDataBlock(vars, values);
        return query;
    }
    
}
