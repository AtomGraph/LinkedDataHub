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
package com.atomgraph.linkeddatahub.imports.stream.csv;

import java.io.InputStreamReader;
import javax.ws.rs.core.StreamingOutput;
import org.apache.jena.query.Query;

/**
 * RDF output stream.
 * Used to write CSV data transformed to RDF.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see com.atomgraph.linkeddatahub.listener.ImportListener
 */
public class CSVStreamRDFOutput extends com.atomgraph.etl.csv.stream.CSVStreamRDFOutput implements StreamingOutput
{
    
    public CSVStreamRDFOutput(InputStreamReader csv, String base, Query query, char delimiter)
    {
        super(csv, base, query, delimiter, null); // TO-DO: specify maxCharsPerColumn ?
    }
    
}
