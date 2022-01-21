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

import java.util.Iterator;
import org.apache.jena.query.Dataset;
import org.apache.jena.query.ReadWrite;
import org.apache.jena.query.TxnType;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.shared.Lock;
import org.apache.jena.sparql.core.DatasetGraph;
import org.apache.jena.sparql.util.Context;
import org.apache.jena.util.FileManager;

/**
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class FileManagerDataset implements Dataset
{
    
    private final FileManager fileManager;
    
    public FileManagerDataset(FileManager fileManager)
    {
        this.fileManager = fileManager;
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
        return getFileManager().getFromCache(uri);
    }

    @Override
    public Model getNamedModel(Resource resource)
    {
        return getFileManager().getFromCache(resource.getURI());
    }

    @Override
    public boolean containsNamedModel(String uri)
    {
        return getFileManager().getFromCache(uri) != null;
    }

    @Override
    public boolean containsNamedModel(Resource resource)
    {
        return getFileManager().getFromCache(resource.getURI()) != null;
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
        throw new UnsupportedOperationException("Not supported yet.");
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

    public FileManager getFileManager()
    {
        return fileManager;
    }
    
}