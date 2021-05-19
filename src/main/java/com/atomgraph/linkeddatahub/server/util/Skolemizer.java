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

import com.atomgraph.processor.vocabulary.SIOC;
import javax.ws.rs.core.UriBuilder;
import org.apache.jena.ontology.OntClass;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.rdf.model.Resource;

/**
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class Skolemizer extends com.atomgraph.processor.util.Skolemizer
{

    public Skolemizer(Ontology ontology, UriBuilder baseUriBuilder, UriBuilder absolutePathBuilder)
    {
        super(ontology, baseUriBuilder, absolutePathBuilder);
    }

    @Override
    public UriBuilder getUriBuilder(String path, Resource resource, OntClass typeClass)
    {
        if (path == null) throw new IllegalArgumentException("Path cannot be null");
        if (typeClass == null) throw new IllegalArgumentException("OntClass cannot be null");

        final UriBuilder builder;
        // treat paths starting with / as absolute, others as relative (to the current absolute path)
        // JAX-RS URI templates do not have this distinction (leading slash is irrelevant)
        if (path.startsWith("/"))
            builder = getBaseUriBuilder().clone();
        else
        {
            Resource parent = getParent(resource);
            if (parent != null) builder = UriBuilder.fromUri(parent.getURI());
            else builder = getAbsolutePathBuilder().clone();
        }
        
        return builder;
    }
    
    public Resource getParent(Resource resource)
    {
        Resource parent = resource.getPropertyResourceValue(SIOC.HAS_PARENT);
        if (parent != null) return parent;
        parent = resource.getPropertyResourceValue(SIOC.HAS_CONTAINER);
        return parent;
    }

}
