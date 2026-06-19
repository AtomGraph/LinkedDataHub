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
 * LACL vocabulary.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class LACL
{

    static
    {
        org.apache.jena.sys.JenaSystem.init(); // ensure Jena (RDFS vocab) is initialized before ontapi touches it
    }
    /** The RDF model that holds the vocabulary terms */
    private static OntModel m_model = OntModelFactory.createModel(OntSpecification.OWL2_FULL_MEM);
    
    /** The namespace of the vocabulary as a string */
    public static final String NS = "https://w3id.org/atomgraph/linkeddatahub/admin/acl#";
    
    /**
     * The namespace of the vocabulary as a string
     * 
     * @return namespace URI
     * @see #NS
     */
    public static String getURI()
    {
        return NS;
    }
    
    /** The namespace of the vocabulary as a resource */
    public static final Resource NAMESPACE = m_model.createResource( NS );

    /** Authorization request class */
    public static final Resource AuthorizationRequest = m_model.createOntClass( NS + "AuthorizationRequest" );
    
    /** Authorization request class */
    public static final Resource OwnerAuthorization = m_model.createOntClass( NS + "OwnerAuthorization" );

    /** Password property */
    public static final Property password = m_model.createDataProperty( NS + "password" );
    
    /** Issuer property */
    public static final Property issuer = m_model.createDataProperty( NS + "issuer" );

        /** Request agent property **/
    public static final Property requestMode = m_model.createObjectProperty( NS + "requestMode" );

    /** Request agent property **/
    public static final Property requestAgent = m_model.createObjectProperty( NS + "requestAgent" );

    /** Request agent group property **/
    public static final Property requestAgentGroup = m_model.createObjectProperty( NS + "requestAgentGroup" );

    /** Request access to property */
    public static final Property requestAccessTo = m_model.createObjectProperty( NS + "requestAccessTo" );

        /** Request access to class property */
    public static final Property requestAccessToClass = m_model.createObjectProperty( NS + "requestAccessToClass" );
    
    /** Request access property */
    public static final Property requestAccess = m_model.createObjectProperty( NS + "requestAccess" );

}
