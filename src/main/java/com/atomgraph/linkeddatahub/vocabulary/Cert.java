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
 * Cert vocabulary.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */

public class Cert
{
    /** The RDF model that holds the vocabulary terms */
    private static OntModel m_model = ModelFactory.createOntologyModel(OntModelSpec.OWL_MEM, null);
    
    /** The namespace of the vocabulary as a string */
    public static final String NS = "http://www.w3.org/ns/auth/cert#";
    
    /** The namespace of the vocabulary as a string
     * @return namespace URI
     *  @see #NS */
    public static String getURI()
    {
        return NS;
    }
    
    /** The namespace of the vocabulary as a resource */
    public static final Resource NAMESPACE = m_model.createResource( NS );

    /** Public key class */
    public static final OntClass PublicKey = m_model.createClass(NS + "PublicKey");

    /** RSA public key class */
    public static final OntClass RSAPublicKey = m_model.createClass(NS + "RSAPublicKey");

    /** Key property */
    public static final ObjectProperty key = m_model.createObjectProperty( NS + "key" );

    /** Modulus property */
    public static final DatatypeProperty modulus = m_model.createDatatypeProperty( NS + "modulus" );
    
    /** Exponent property */
    public static final DatatypeProperty exponent = m_model.createDatatypeProperty( NS + "exponent" );

}