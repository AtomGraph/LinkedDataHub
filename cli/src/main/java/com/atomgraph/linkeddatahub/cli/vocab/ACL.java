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
 * W3C Web Access Control vocabulary.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class ACL
{

    /** Namespace URI */
    public static final String NS = "http://www.w3.org/ns/auth/acl#";

    private ACL() { }

    /** acl:Authorization class */
    public static final Resource Authorization = ResourceFactory.createResource(NS + "Authorization");
    /** acl:Append mode */
    public static final Resource Append = ResourceFactory.createResource(NS + "Append");
    /** acl:Control mode */
    public static final Resource Control = ResourceFactory.createResource(NS + "Control");
    /** acl:Read mode */
    public static final Resource Read = ResourceFactory.createResource(NS + "Read");
    /** acl:Write mode */
    public static final Resource Write = ResourceFactory.createResource(NS + "Write");

    /** acl:agent property */
    public static final Property agent = ResourceFactory.createProperty(NS + "agent");
    /** acl:agentClass property */
    public static final Property agentClass = ResourceFactory.createProperty(NS + "agentClass");
    /** acl:agentGroup property */
    public static final Property agentGroup = ResourceFactory.createProperty(NS + "agentGroup");
    /** acl:accessTo property */
    public static final Property accessTo = ResourceFactory.createProperty(NS + "accessTo");
    /** acl:accessToClass property */
    public static final Property accessToClass = ResourceFactory.createProperty(NS + "accessToClass");
    /** acl:mode property */
    public static final Property mode = ResourceFactory.createProperty(NS + "mode");

}
