/**
 *  Copyright 2020 Martynas Jusevičius <martynas@atomgraph.com>
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
 */package com.atomgraph.linkeddatahub.imports;

import com.atomgraph.linkeddatahub.model.Import;
import org.apache.jena.query.DatasetAccessor;
import org.apache.jena.rdf.model.Resource;

/**
 *
 * @author Martynas Jusevičius <martynas@atomgraph.com>
 */
public class ImportMetadata
{
    
    private final Import imp;
    private final Resource provGraph;
    private final DatasetAccessor accessor;
    
    public ImportMetadata(Import imp, Resource provGraph, DatasetAccessor accessor)
    {
        this.imp = imp;
        this.provGraph = provGraph;
        this.accessor = accessor;
    }
    
    public Import getImport()
    {
        return imp;
    }
    
    public Resource getProvenanceGraph()
    {
        return provGraph;
    }
    
    public DatasetAccessor getDatasetAccessor()
    {
        return accessor;
    }
    
}
