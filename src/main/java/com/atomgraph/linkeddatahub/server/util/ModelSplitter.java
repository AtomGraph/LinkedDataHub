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
package com.atomgraph.linkeddatahub.server.util;

import org.apache.jena.query.Dataset;
import org.apache.jena.query.DatasetFactory;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Statement;
import org.apache.jena.rdf.model.StmtIterator;

/**
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class ModelSplitter
{
    
    /**
     * Split's the model into named graphs based on the subject URI (minus the fragment identifier).
     * Blank nodes are ignored.
     * 
     * @param model RDF model
     * @return dataset with named graphs
     */
    public static Dataset split(Model model)
    {
        if (model == null) throw new IllegalArgumentException("Model cannot be null");

        Dataset dataset = DatasetFactory.create();

        StmtIterator it = model.listStatements();
        try
        {
            while (it.hasNext())
            {
                Statement stmt = it.next();
                
                if (stmt.getSubject().isURIResource()) // blank nodes are ignored!!!
                {
                    String docURI = stmt.getSubject().getURI();
                    if (docURI.contains("#")) docURI = docURI.substring(0, docURI.indexOf("#")); // strip the fragment, leaving only document URIs
                    
                    Model namedModel = dataset.getNamedModel(docURI);
                    namedModel.add(stmt);
                }
                else
                    throw new IllegalArgumentException("Blank nodes not supported");
            }
        }
        finally
        {
            it.close();
        }
        
        return dataset;
    }

}
