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

import static com.atomgraph.processor.util.Skolemizer.getNameValueMap;
import com.atomgraph.processor.vocabulary.LDT;
import java.net.URI;
import java.util.Map;
import javax.ws.rs.core.UriBuilder;
import org.apache.jena.ontology.OntClass;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.StmtIterator;
import org.apache.jena.vocabulary.RDF;
import org.glassfish.jersey.uri.internal.UriTemplateParser;

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
    public URI build(Resource resource)
    {
        if (resource == null) throw new IllegalArgumentException("Resource cannot be null");
        
        StmtIterator it = resource.listProperties(RDF.type);
        
        try
        {
            while (it.hasNext())
            {
                Resource type = it.next().getResource(); // will fail if rdf:type object is not a resource
                if (getOntology().getOntModel().getOntResource(type).canAs(OntClass.class))
                {
                    OntClass typeClass = getOntology().getOntModel().getOntResource(type).asClass();
                    
                    OntClass pathClass = getPathClass(typeClass);
                    final String pathTemplate;
                    if (pathClass != null) pathTemplate = getStringValue(pathClass, LDT.path);
                    else pathTemplate = null;

                    OntClass fragmentClass = getFragmentClass(typeClass);
                    final String fragmentTemplate;
                    if (fragmentClass != null) fragmentTemplate = getStringValue(fragmentClass, LDT.fragment);
                    else fragmentTemplate = null;

                    return build(resource, getUriBuilder(pathTemplate), pathTemplate, fragmentTemplate);
                }
            }
        }
        finally
        {
            it.close();
        }
        
        return null;
    }
    
    public UriBuilder getUriBuilder(String pathTemplate)
    {
        // treat paths starting with / as absolute, others as relative (to the current absolute path)
        // JAX-RS URI templates do not have this distinction (leading slash is irrelevant)
        if (pathTemplate != null && pathTemplate.startsWith("/")) return getBaseUriBuilder().clone();
        else return getAbsolutePathBuilder().clone();
    }
    
    @Override
    public URI build(Resource resource, UriBuilder builder, String path, String fragment)
    {
        if (resource == null) throw new IllegalArgumentException("Resource cannot be null");
        if (builder == null) throw new IllegalArgumentException("UriBuilder cannot be null");

        Map<String, String> nameValueMap = getNameValueMap(resource, new UriTemplateParser(path));
        if (path != null) builder = builder.path(path);
        
        return builder.path(path).fragment(fragment).buildFromMap(nameValueMap); // TO-DO: wrap into SkolemizationException
    }
    
    
//    public Resource getParent(Resource resource)
//    {
//        Resource parent = resource.getPropertyResourceValue(SIOC.HAS_PARENT);
//        if (parent != null) return parent;
//        parent = resource.getPropertyResourceValue(SIOC.HAS_CONTAINER);
//        return parent;
//    }

}