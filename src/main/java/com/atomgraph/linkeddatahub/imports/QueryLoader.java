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
package com.atomgraph.linkeddatahub.imports;

import com.atomgraph.client.util.DataManager;
import java.util.function.Supplier;
import javax.ws.rs.core.Response;
import org.apache.jena.query.Query;
import org.apache.jena.query.QueryFactory;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Resource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.spinrdf.vocabulary.SP;

/**
 * SPIN query loader.
 * Loads a query resource from URI and uses it's <code>sp:text</code> property value to construct a query object.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class QueryLoader implements Supplier<Query>
{

    private static final Logger log = LoggerFactory.getLogger(QueryLoader.class);

    private final String uri;
    private final String baseURI;
    private final DataManager dataManager;
    
    public QueryLoader(String uri, String baseURI, DataManager dataManager)
    {
        this.uri = uri;
        this.baseURI = baseURI;
        this.dataManager = dataManager;
    }
    
    @Override
    public Query get()
    {
        try (Response cr = getDataManager().load(getURI()))
        {
            Resource queryRes = cr.readEntity(Model.class).getResource(getURI());
            return QueryFactory.create(queryRes.getRequiredProperty(SP.text).getString(), getBaseURI());
        }
    }

    public String getURI()
    {
        return uri;
    }

    public String getBaseURI()
    {
        return baseURI;
    }

    public DataManager getDataManager()
    {
        return dataManager;
    }
    
}
