/*
 * Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.atomgraph.linkeddatahub.rdf.vocabulary;

import org.apache.jena.rdf.model.Property;
import org.apache.jena.rdf.model.ResourceFactory;

/**
 * LinkedDataHub dataspaces vocabulary: the terms a client reads from the platform's <code>Link</code>
 * response headers.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class LDS
{

    /** Namespace URI */
    public static final String NS = "https://w3id.org/atomgraph/linkeddatahub/dataspaces#";

    private LDS() { }

    /** lds:dataspace property, the dataspace a response belongs to */
    public static final Property dataspace = ResourceFactory.createProperty(NS + "dataspace");
    /** lds:ontology property, the dataspace's ontology */
    public static final Property ontology = ResourceFactory.createProperty(NS + "ontology");
    /** lds:admin property, the base URI of an end-user dataspace's administration application */
    public static final Property admin = ResourceFactory.createProperty(NS + "admin");

}
