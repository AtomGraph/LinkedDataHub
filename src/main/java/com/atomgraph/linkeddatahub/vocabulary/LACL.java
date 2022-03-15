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

import org.apache.jena.ontology.DatatypeProperty;
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
public class LACL
{
    /** The RDF model that holds the vocabulary terms */
    private static OntModel m_model = ModelFactory.createOntologyModel(OntModelSpec.OWL_MEM, null);
    
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
    public static final OntClass AuthorizationRequest = m_model.createClass( NS + "AuthorizationRequest" );

    /** Password property */
    public static final DatatypeProperty password = m_model.createDatatypeProperty( NS + "password" );
    
    /** Issuer property */
    public static final DatatypeProperty issuer = m_model.createDatatypeProperty( NS + "issuer" );

    /** Request agent property **/
    public static final ObjectProperty requestAgent = m_model.createObjectProperty( NS + "requestAgent" );

    /** Request access to property */
    public static final ObjectProperty requestAccessTo = m_model.createObjectProperty( NS + "requestAccessTo" );

    /** Request access property */
    public static final ObjectProperty requestAccess = m_model.createObjectProperty( NS + "requestAccess" );

}
