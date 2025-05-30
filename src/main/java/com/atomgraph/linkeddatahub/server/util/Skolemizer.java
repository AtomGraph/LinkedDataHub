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

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import jakarta.ws.rs.core.UriBuilder;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.util.ResourceUtils;
import org.apache.jena.util.iterator.ExtendedIterator;

/**
 * Skolemizes blank node resources into URI resources.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class Skolemizer implements Function<Model, Model>
{

    private final String base;

    /**
     * Constructs skolemizer from base URI.
     * 
     * @param base URI that fragments will be resolved against. <code>ldh:fragment</code> is the default.
     */
    public Skolemizer(String base)
    {
        this.base = base;
    }
    
    /**
     * Skolemizes RDF graph by replacing blank node resources with hash-URI resources.
     * 
     * @param model input model
     * @return skolemized model
     */
    @Override
    public Model apply(Model model)
    {
        Map<Resource, String> bnodes = new HashMap<>();

        ExtendedIterator<Resource> it = model.listSubjects().
            filterKeep((Resource res) -> (res.isAnon()));
        try
        {
            while (it.hasNext())
            {
                Resource bnode = it.next();

                final String fragment = "id" + UUID.randomUUID().toString(); // UUID can start with a number which is not legal for a fragment ID
                
                bnodes.put(bnode, fragment);
            }
        }
        finally
        {
            it.close();
        }

        bnodes.entrySet().forEach(entry ->
            {
                ResourceUtils.renameResource(entry.getKey(), UriBuilder.fromUri(getBase()).
                    fragment(entry.getValue()).
                    build().
                    toString());
            });

        return model;
    }

    /**
     * Returns the base URI against which fragments are resolved.
     * 
     * @return base URI
     */
    public String getBase()
    {
        return base;
    }
    
}
