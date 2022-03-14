/**
 *  Copyright 2019 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.vocabulary;

import org.apache.jena.ontology.ObjectProperty;
import org.apache.jena.ontology.OntClass;
import org.apache.jena.ontology.OntModel;
import org.apache.jena.ontology.OntModelSpec;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ACL
{
    /** The RDF model that holds the vocabulary terms */
    private static OntModel m_model = ModelFactory.createOntologyModel(OntModelSpec.OWL_MEM, null);
    
    /** The namespace of the vocabulary as a string */
    public static final String NS = "http://www.w3.org/ns/auth/acl#";
    
    /** The namespace of the vocabulary as a string.
     * @return namespace URI
     * @see #NS
     */
    public static String getURI()
    {
        return NS;
    }
    
    /** The namespace of the vocabulary as a resource */
    public static final Resource NAMESPACE = m_model.createResource( NS );
    
    /** <code>acl:Authorization</code> class */
    public static final OntClass Authorization = m_model.createClass( NS + "Authorization" );

    /** <code>acl:Read</code> access mode */
    public static final OntClass Read = m_model.createClass( NS + "Read" );

    /** <code>acl:Write</code> access mode */
    public static final OntClass Write = m_model.createClass( NS + "Write" );
    
    /** <code>acl:Append</code> access mode */
    public static final OntClass Append = m_model.createClass( NS + "Append" );

    /** <code>acl:AuthenticatedAgent</code> class */
    public static final OntClass AuthenticatedAgent = m_model.createClass( NS + "AuthenticatedAgent" );

    /** <code>acl:delegates</code> property **/
    public static final ObjectProperty delegates = m_model.createObjectProperty( NS + "delegates" );

    /** <code>acl:owner</code> property */
    public static final ObjectProperty owner = m_model.createObjectProperty( NS + "owner" );

    /** <code>acl:agent</code> property */
    public static final ObjectProperty agent = m_model.createObjectProperty( NS + "agent" );
    
    /** <code>acl:agentClass</code> property */
    public static final ObjectProperty agentClass = m_model.createObjectProperty( NS + "agentClass" );

    /** <code>acl:agentGroup</code> property */
    public static final ObjectProperty agentGroup = m_model.createObjectProperty( NS + "agentGroup" );

    /** <code>acl:mode</code> property */
    public static final ObjectProperty mode = m_model.createObjectProperty( NS + "mode" );
    
    /** <code>acl:accessTo</code> property */
    public static final ObjectProperty accessTo = m_model.createObjectProperty( NS + "accessTo" );

    /** <code>acl:accessToClass</code> property */
    public static final ObjectProperty accessToClass = m_model.createObjectProperty( NS + "accessToClass" );

}
