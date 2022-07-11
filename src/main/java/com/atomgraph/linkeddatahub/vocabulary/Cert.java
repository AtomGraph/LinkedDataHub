// Copyright 2019 Martynas Jusevičius <martynas@atomgraph.com>
// SPDX-FileCopyrightText: 2017-2022 2017 Martynas Jusevicius, <martynas@atomgraph.com> et al.
//
// SPDX-License-Identifier: Apache-2.0

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