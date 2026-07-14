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
import org.apache.jena.rdf.model.ResourceFactory;

/**
 * SPIN modeling vocabulary.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class SPIN
{

    /** Namespace URI */
    public static final String NS = "http://spinrdf.org/spin#";

    private SPIN() { }

    /** spin:query property */
    public static final Property query = ResourceFactory.createProperty(NS + "query");
    /** spin:constructor property */
    public static final Property constructor = ResourceFactory.createProperty(NS + "constructor");
    /** spin:constraint property */
    public static final Property constraint = ResourceFactory.createProperty(NS + "constraint");

}
