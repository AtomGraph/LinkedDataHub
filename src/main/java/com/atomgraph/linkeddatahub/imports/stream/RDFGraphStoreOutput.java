/**
 *  Copyright 2021 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.imports.stream;

import com.atomgraph.core.client.GraphStoreClient;
import java.io.InputStream;
import java.util.Iterator;
import org.apache.jena.query.Dataset;
import org.apache.jena.query.Query;
import org.apache.jena.query.QueryExecution;
import org.apache.jena.query.Syntax;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFDataMgr;

/**
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class RDFGraphStoreOutput
{

    private final GraphStoreClient graphStoreClient;
    private final String base;
    private final InputStream is;
    private final Query query;
    private final Lang lang;
    private final String graphURI;
    
    public RDFGraphStoreOutput(GraphStoreClient graphStoreClient, InputStream is, String base, Query query, Lang lang, String graphURI)
    {
        this.graphStoreClient = graphStoreClient;
        this.is = is;
        this.base = base;
        this.query = query;
        this.lang = lang;
        this.graphURI = graphURI;
    }
    
    public void write()
    {
        Model model = ModelFactory.createDefaultModel();
        RDFDataMgr.read(model, getInputStream(), getBase(), getLang());

        if (getQuery() != null)
        {
            // use extended SPARQL syntax to allow CONSTRUCT GRAPH form
            try (QueryExecution qex = QueryExecution.create().query(getQuery().toString(), Syntax.syntaxARQ).model(model).build())
            {
                Dataset dataset = qex.execConstructDataset();

                Iterator<String> names = dataset.listNames();
                while (names.hasNext())
                {
                    String graphUri = names.next();
                    getGraphStoreClient().add(graphUri, dataset.getNamedModel(graphUri)); // exceptions get swallowed by the client! TO-DO: wait for completion
                }
            }
        }
        else
        {
            if (getGraphURI() == null) throw new IllegalStateException("Neither RDFImport query nor graph name is specified");
            
            getGraphStoreClient().add(getGraphURI(), model); // exceptions get swallowed by the client! TO-DO: wait for completion
        }
    }
    
    public GraphStoreClient getGraphStoreClient()
    {
        return graphStoreClient;
    }
    
    public InputStream getInputStream()
    {
        return is;
    }
    
    public String getBase()
    {
        return base;
    }
       
    public Query getQuery()
    {
        return query;
    }
    
    public Lang getLang()
    {
        return lang;
    }
    
    public String getGraphURI()
    {
        return graphURI;
    }
    
}
