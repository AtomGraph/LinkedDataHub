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
 * NEPOMUK File Ontology vocabulary.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class NFO
{

    /** Namespace URI */
    public static final String NS = "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#";

    private NFO() { }

    /** nfo:FileDataObject class */
    public static final Resource FileDataObject = ResourceFactory.createResource(NS + "FileDataObject");

    /** nfo:fileName property */
    public static final Property fileName = ResourceFactory.createProperty(NS + "fileName");

}
