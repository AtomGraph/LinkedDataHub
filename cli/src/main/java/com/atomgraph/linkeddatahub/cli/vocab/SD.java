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

package com.atomgraph.linkeddatahub.cli.vocab;

import org.apache.jena.rdf.model.Property;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;

/**
 * SPARQL 1.1 Service Description vocabulary.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class SD
{

    /** Namespace URI */
    public static final String NS = "http://www.w3.org/ns/sparql-service-description#";

    private SD() { }

    /** sd:Service class */
    public static final Resource Service = ResourceFactory.createResource(NS + "Service");
    /** sd:SPARQL11Query language */
    public static final Resource SPARQL11Query = ResourceFactory.createResource(NS + "SPARQL11Query");
    /** sd:SPARQL11Update language */
    public static final Resource SPARQL11Update = ResourceFactory.createResource(NS + "SPARQL11Update");

    /** sd:endpoint property */
    public static final Property endpoint = ResourceFactory.createProperty(NS + "endpoint");
    /** sd:supportedLanguage property */
    public static final Property supportedLanguage = ResourceFactory.createProperty(NS + "supportedLanguage");
    /** sd:name property */
    public static final Property name = ResourceFactory.createProperty(NS + "name");

}
