/**
 *  Copyright 2022 Martynas Jusevičius <martynas@atomgraph.com>
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

import com.atomgraph.core.util.jena.DataManager;
import java.util.Iterator;
import org.apache.jena.graph.NodeFactory;
import org.apache.jena.query.Dataset;
import org.apache.jena.query.ReadWrite;
import org.apache.jena.query.TxnType;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.shared.Lock;
import org.apache.jena.sparql.core.DatasetGraph;
import org.apache.jena.sparql.core.DatasetGraphFactory;
import org.apache.jena.sparql.util.Context;

/**
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class DataManagerDataset implements Dataset
{
    
    private final DataManager dataManager;
    private final DatasetGraph datasetGraph;
    
    public DataManagerDataset(DataManager dataManager)
    {
        this.dataManager = dataManager;
        this.datasetGraph = DatasetGraphFactory.createGeneral();
        // add models to the dataset from the cache map
        dataManager.getModelCache().entrySet().forEach(entry -> {
            this.datasetGraph.addGraph(NodeFactory.createURI(entry.getKey()), entry.getValue().getGraph());
        });
    }

    @Override
    public Model getDefaultModel()
    {
        return ModelFactory.createDefaultModel();
    }

    @Override
    public Model getUnionModel()
    {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public Dataset setDefaultModel(Model arg0)
    {
        return this;
    }

    @Override
    public Model getNamedModel(String uri)
    {
        return getDataManager().getModelCache().get(uri);
    }

    @Override
    public Model getNamedModel(Resource resource)
    {
        return getDataManager().getModelCache().get(resource.getURI());
    }

    @Override
    public boolean containsNamedModel(String uri)
    {
        return getDataManager().getModelCache().get(uri) != null;
    }

    @Override
    public boolean containsNamedModel(Resource resource)
    {
        return getDataManager().getModelCache().get(resource.getURI()) != null;
    }

    @Override
    public Dataset addNamedModel(String arg0, Model arg1)
    {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public Dataset addNamedModel(Resource arg0, Model arg1)
    {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public Dataset removeNamedModel(String arg0)
    {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public Dataset removeNamedModel(Resource arg0)
    {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public Dataset replaceNamedModel(String arg0, Model arg1)
    {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public Dataset replaceNamedModel(Resource arg0, Model arg1)
    {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public Iterator<String> listNames()
    {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public Iterator<Resource> listModelNames()
    {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public Lock getLock()
    {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public Context getContext()
    {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public boolean supportsTransactions()
    {
        return false;
    }

    @Override
    public boolean supportsTransactionAbort()
    {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public void begin(ReadWrite arg0)
    {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public void commit()
    {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public void abort()
    {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public boolean isInTransaction()
    {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public void end()
    {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public DatasetGraph asDatasetGraph()
    {
        return datasetGraph;
    }

    @Override
    public void close()
    {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public boolean isEmpty()
    {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public void begin(TxnType arg0)
    {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public boolean promote(Promote arg0)
    {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public ReadWrite transactionMode()
    {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public TxnType transactionType()
    {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    public DataManager getDataManager()
    {
        return dataManager;
    }
    
}