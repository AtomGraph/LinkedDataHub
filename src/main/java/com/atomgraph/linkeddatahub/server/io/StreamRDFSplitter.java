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
package com.atomgraph.linkeddatahub.server.io;

import java.util.function.Function;
import org.apache.commons.codec.digest.DigestUtils;
import org.apache.jena.graph.NodeFactory;
import org.apache.jena.graph.Triple;
import org.apache.jena.riot.system.StreamRDF;
import org.apache.jena.riot.system.StreamRDFWrapper;
import org.apache.jena.sparql.core.Quad;

/**
 *
 * @author Martynas Jusevičius <martynas@atomgraph.com>
 */
public class StreamRDFSplitter extends StreamRDFWrapper implements Function<StreamRDF, StreamRDF>
{
    private final boolean stripFragments;
    
    public StreamRDFSplitter(StreamRDF other, boolean stripFragments)
    {
        super(other);
        this.stripFragments = stripFragments;
    }
    
    @Override
    public void triple(Triple triple)
    {
        final String hash;
        
        if (triple.getSubject().isURI())
        {
            String uri = triple.getSubject().getURI();
            
            if (uri.contains("#") && stripFragments()) uri = uri.substring(0, uri.indexOf("#"));
             
            hash = DigestUtils.sha1Hex(uri);
        }
        else hash = DigestUtils.sha1Hex(triple.getSubject().getBlankNodeLabel());
        
        super.quad(new Quad(NodeFactory.createURI(hash), triple));
    }

    @Override
    public void quad(Quad quad)
    {
        triple(quad.asTriple());
    }

    @Override
    public StreamRDF apply(StreamRDF streamRDF)
    {
        return new StreamRDFSplitter(streamRDF, stripFragments());
    }
    
    public boolean stripFragments()
    {
        return stripFragments;
    }
    
}