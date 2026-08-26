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

import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;

/**
 * Document hierarchy vocabulary.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class DH
{

    /** Namespace URI */
    public static final String NS = "https://www.w3.org/ns/ldt/document-hierarchy#";

    private DH() { }

    /** dh:Item class */
    public static final Resource Item = ResourceFactory.createResource(NS + "Item");
    /** dh:Container class */
    public static final Resource Container = ResourceFactory.createResource(NS + "Container");

}
