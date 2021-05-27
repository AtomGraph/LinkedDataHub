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
package com.atomgraph.linkeddatahub.imports.stream.csv;

import com.atomgraph.core.client.GraphStoreClient;
import com.atomgraph.etl.csv.ModelTransformer;
import com.atomgraph.linkeddatahub.server.util.ModelSplitter;
import com.univocity.parsers.common.ParsingContext;
import com.univocity.parsers.common.processor.RowProcessor;
import java.util.Iterator;
import java.util.function.BiFunction;
import org.apache.jena.atlas.lib.IRILib;
import org.apache.jena.query.Dataset;
import org.apache.jena.query.Query;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Property;
import org.apache.jena.rdf.model.Resource;

/**
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class CSVGraphStoreRowProcessor implements RowProcessor // extends com.atomgraph.etl.csv.stream.CSVStreamRDFProcessor
{

//    private final WebTarget webTarget;
    private final GraphStoreClient graphStoreClient;
    private final String base;
    private final BiFunction<Query, Model, Model> function = new ModelTransformer();
    private final Query query;
    private int subjectCount, tripleCount;

    public CSVGraphStoreRowProcessor(GraphStoreClient graphStoreClient, String base, Query query)
    {
        this.graphStoreClient = graphStoreClient;
        this.base = base;
        this.query = query;
    }

    @Override
    public void processStarted(ParsingContext context)
    {
        subjectCount = tripleCount = 0;
    }

    @Override
    public void rowProcessed(String[] row, ParsingContext context)
    {
        Model rowModel = transformRow(row, context);
        Dataset rowDataset = ModelSplitter.split(rowModel);
        
        Iterator<String> names = rowDataset.listNames();
        while (names.hasNext())
        {
            String graphUri = names.next();
            getGraphStoreClient().add(graphUri, rowDataset.getNamedModel(graphUri)); // exceptions get swallowed by the client!
        }
    }
    
    public Model transformRow(String[] row, ParsingContext context)
    {
        Model rowModel = ModelFactory.createDefaultModel();
        Resource subject = rowModel.createResource();
        subjectCount++;
        
        int cellNo = 0;
        for (String cell : row)
        {
            if (cell != null && context.headers()[cellNo] != null)
            {
                String fragmentId = IRILib.encodeUriComponent(context.headers()[cellNo]);
                Property property = rowModel.createProperty(getBase(), "#" + fragmentId);
                subject.addProperty(property, cell);
                tripleCount++;
            }
            cellNo++;
        }

        return getFunction().apply(getQuery(), rowModel); // transform row
    }
    
    @Override
    public void processEnded(ParsingContext context)
    {
    }
    
//    public WebTarget getWebTarget()
//    {
//        return webTarget;
//    }
    
    public GraphStoreClient getGraphStoreClient()
    {
        return graphStoreClient;
    }
    
    public String getBase()
    {
        return base;
    }
    
    public BiFunction<Query, Model, Model> getFunction()
    {
        return function;
    }
    
    public Query getQuery()
    {
        return query;
    }
    
    public int getSubjectCount()
    {
        return subjectCount;
    }
    
    public int getTripleCount()
    {
        return tripleCount;
    }
    
}
