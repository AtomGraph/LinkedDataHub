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
 * LAPP vocabulary.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class LAPP
{

    /** The RDF model that holds the vocabulary terms */
    private static OntModel m_model = ModelFactory.createOntologyModel(OntModelSpec.OWL_MEM, null);
    
    /** The namespace of the vocabulary as a string */
    public static final String NS = "https://w3id.org/atomgraph/linkeddatahub/apps#";
    
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

    /** Dataset class */
    public static final OntClass Dataset = m_model.createClass( NS + "Dataset" );
    
    /** Application class */
    public static final OntClass Application = m_model.createClass( NS + "Application" );

    /** Admin application class */
    public static final OntClass AdminApplication = m_model.createClass( NS + "AdminApplication" );

    /** End-user application class */
    public static final OntClass EndUserApplication = m_model.createClass( NS + "EndUserApplication" );
    
    /** Admin application class */
    public static final ObjectProperty adminApplication = m_model.createObjectProperty( NS + "adminApplication" );

    /** End-user application class */
    public static final ObjectProperty endUserApplication = m_model.createObjectProperty( NS + "endUserApplication" );

    /** Proxy property */
    public static final ObjectProperty proxy = m_model.createObjectProperty( NS + "proxy" );

    /** Prefix property */
    public static final ObjectProperty prefix = m_model.createObjectProperty( NS + "prefix" );
    
    /** Read-only property */
    public static final DatatypeProperty readOnly = m_model.createDatatypeProperty( NS + "readOnly" );

}
