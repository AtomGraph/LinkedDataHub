/**
 *  Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */
package com.atomgraph.linkeddatahub.vocabulary;

import org.apache.jena.rdf.model.Property;
import org.apache.jena.rdf.model.ResourceFactory;

/**
 * The terms of the SPARQL 1.1 Service Description the platform uses beyond those Core's vocabulary declares.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see <a href="https://www.w3.org/TR/sparql11-service-description/">SPARQL 1.1 Service Description</a>
 */
public class SD
{

    /** Namespace of the SPARQL 1.1 Service Description vocabulary */
    public static final String NS = com.atomgraph.core.vocabulary.SD.NS;

    /**
     * Returns the namespace of the vocabulary.
     *
     * @return namespace URI
     */
    public static String getURI()
    {
        return NS;
    }

    /** sd:propertyFeature: a property function the service's endpoint supports, such as jena-text's text:query */
    public static final Property propertyFeature = ResourceFactory.createProperty(NS + "propertyFeature");

}
