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
 */
package com.atomgraph.linkeddatahub.imports;

import com.atomgraph.etl.csv.ModelTransformer;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.core.StreamingOutput;
import org.apache.jena.query.Query;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFDataMgr;
import org.apache.jena.riot.system.StreamRDF;
import org.apache.jena.riot.system.StreamRDFLib;
import org.apache.jena.riot.system.StreamRDFOps;

/**
 *
 * @author Martynas Jusevičius <martynas@atomgraph.com>
 */
public class StreamRDFOutput implements StreamingOutput
{
    
    private final String base;
    private final InputStream input;
    private final Query query;
    private final Lang lang;
    
    public StreamRDFOutput(InputStream reader, String base, Query query, Lang lang)
    {
        this.base = base;
        this.input = reader;
        this.query = query;
        this.lang = lang;
    }

    @Override
    public void write(OutputStream os) throws IOException, WebApplicationException
    {
        write(StreamRDFLib.writer(os));
    }
    
    public void write(StreamRDF stream)
    {
        Model model = ModelFactory.createDefaultModel();
        RDFDataMgr.read(model, getInputStream(), getBase(), getLang());
        model = new ModelTransformer().apply(getQuery(), model); // transform row
        StreamRDFOps.sendTriplesToStream(model.getGraph(), stream); // send the transformed RDF to the stream
    }
    
    public InputStream getInputStream()
    {
        return input;
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
    
}
