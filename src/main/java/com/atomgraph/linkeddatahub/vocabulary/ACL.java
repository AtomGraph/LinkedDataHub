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

import org.apache.jena.ontapi.OntModelFactory;
import org.apache.jena.ontapi.OntSpecification;
import org.apache.jena.ontapi.model.OntModel;
import org.apache.jena.rdf.model.Property;

import org.apache.jena.rdf.model.Resource;

/**
 * ACL vocabulary.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ACL
{

    static
    {
        org.apache.jena.sys.JenaSystem.init(); // ensure Jena (RDFS vocab) is initialized before ontapi touches it
    }
    /** The RDF model that holds the vocabulary terms */
    private static OntModel m_model = OntModelFactory.createModel(OntSpecification.OWL2_DL_MEM);
    
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
    public static final Resource Authorization = m_model.createOntClass( NS + "Authorization" );

    /** <code>acl:Read</code> access mode */
    public static final Resource Read = m_model.createOntClass( NS + "Read" );

    /** <code>acl:Write</code> access mode */
    public static final Resource Write = m_model.createOntClass( NS + "Write" );
    
    /** <code>acl:Append</code> access mode */
    public static final Resource Append = m_model.createOntClass( NS + "Append" );

    /** <code>acl:Control</code> access mode */
    public static final Resource Control = m_model.createOntClass( NS + "Control" );

    /** <code>acl:AuthenticatedAgent</code> class */
    public static final Resource AuthenticatedAgent = m_model.createOntClass( NS + "AuthenticatedAgent" );

    /** <code>acl:delegates</code> property **/
    public static final Property delegates = m_model.createObjectProperty( NS + "delegates" );

    /** <code>acl:owner</code> property */
    public static final Property owner = m_model.createObjectProperty( NS + "owner" );

    /** <code>acl:agent</code> property */
    public static final Property agent = m_model.createObjectProperty( NS + "agent" );
    
    /** <code>acl:agentClass</code> property */
    public static final Property agentClass = m_model.createObjectProperty( NS + "agentClass" );

    /** <code>acl:agentGroup</code> property */
    public static final Property agentGroup = m_model.createObjectProperty( NS + "agentGroup" );

    /** <code>acl:mode</code> property */
    public static final Property mode = m_model.createObjectProperty( NS + "mode" );
    
    /** <code>acl:accessTo</code> property */
    public static final Property accessTo = m_model.createObjectProperty( NS + "accessTo" );

    /** <code>acl:accessToClass</code> property */
    public static final Property accessToClass = m_model.createObjectProperty( NS + "accessToClass" );

}
