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
 * LDH vocabulary.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class LDH
{

    static
    {
        org.apache.jena.sys.JenaSystem.init(); // ensure Jena (RDFS vocab) is initialized before ontapi touches it
    }
    /** The RDF model that holds the vocabulary terms */
    private static OntModel m_model = OntModelFactory.createModel(OntSpecification.OWL1_FULL_MEM);
    
    /** The namespace of the vocabulary as a string */
    public static final String NS = "https://w3id.org/atomgraph/linkeddatahub#";
    
    /**
     * The namespace of the vocabulary as a string
     * 
     * @return namespace URI
     * @see #NS */
    public static String getURI()
    {
        return NS;
    }
    
    /** The namespace of the vocabulary as a resource */
    public static final Resource NAMESPACE = m_model.createResource( NS );

    /** Dataset class */
    public static final Resource Dataset = m_model.createOntClass(NS + "Dataset");

    /** Generic service class */
    public static final Resource GenericService = m_model.createOntClass(NS + "GenericService");
    
    /** Import class */
    public static final Resource Import = m_model.createOntClass(NS + "Import");

    /** CSV import class */
    public static final Resource CSVImport = m_model.createOntClass(NS + "CSVImport");

    /** RDF import class */
    public static final Resource RDFImport = m_model.createOntClass(NS + "RDFImport");

    /** File class */
    public static final Resource File = m_model.createOntClass(NS + "File");
    
    /** Object class */
    public static final Resource Object = m_model.createOntClass(NS + "Object");

    /** View class */
    public static final Resource View = m_model.createOntClass(NS + "View");

    /** URI syntax violation class */
    public static final Resource URISyntaxViolation = m_model.createOntClass(NS + "URISyntaxViolation");
    
    /** Base property */
    public static final Property base = m_model.createObjectProperty( NS + "base" );
    
    /** File property */
    public static final Property file = m_model.createObjectProperty( NS + "file" );
    
    /** Action property */
    public static final Property action = m_model.createObjectProperty( NS + "action" );

    /** Delimiter property */
    public static final Property delimiter = m_model.createDataProperty( NS + "delimiter" );

    /** Violation value property */
    public static final Property violationValue = m_model.createDataProperty( NS + "violationValue" );
    
    /** Request URI property */
    public static final Property requestUri = m_model.createObjectProperty(NS + "requestUri");

    /** HTTP headers property */
    public static final Property httpHeaders = m_model.createObjectProperty(NS + "httpHeaders");
    
    /** Service property */
    public static final Property service = m_model.createObjectProperty( NS + "service" );

    /**
     * For shape property */
    public static final Property forShape = m_model.createObjectProperty( NS + "forShape" );

    /**
     * Import property - used to import packages into an application */
    public static final Property importPackage = m_model.createObjectProperty( NS + "import" );

}
