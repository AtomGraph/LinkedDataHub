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

import com.atomgraph.linkeddatahub.vocabulary.LDH;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import javax.ws.rs.core.UriBuilder;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Property;
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
    private final Property fragmentProperty;
    
    /**
     * Constructs skolemizer from base URI and optional fragment property.
     * 
     * @param base URI that fragments will be resolved against
     * @param fragmentProperty if specified, the skolemizer will use the value of this property as the fragment ID
     */
    public Skolemizer(String base, Property fragmentProperty)
    {
        this.base = base;
        this.fragmentProperty = fragmentProperty;
    }

    /**
     * Constructs skolemizer from base URI.
     * 
     * @param base URI that fragments will be resolved against. <code>ldh:fragment</code> is the default.
     */
    public Skolemizer(String base)
    {
        this(base, LDH.fragment);
    }
    
    /**
     * Skolemizes RDF graph by replacing blank node resources with fragment URI resources.
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

                final String fragment;
                if (bnode.hasProperty(getFragmentProperty())) fragment = bnode.getProperty(getFragmentProperty()).getString();
                else fragment = "id" + UUID.randomUUID().toString(); // UUID can start with a number which is not legal for a fragment ID
                
                bnodes.put(bnode, fragment);
            }
        }
        finally
        {
            it.close();
        }

        bnodes.entrySet().forEach(entry ->
            {
                if (getFragmentProperty() != null) entry.getKey().removeAll(getFragmentProperty()); // remove the fragment slug
                
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
    
    /**
     * Returns the property which can be used to specify the fragment ID.
     * 
     * @return RDF property
     */
    public Property getFragmentProperty()
    {
        return fragmentProperty;
    }
    
}
