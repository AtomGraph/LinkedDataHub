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
 * LDH vocabulary.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class LDH
{
    /** The RDF model that holds the vocabulary terms */
    private static OntModel m_model = ModelFactory.createOntologyModel(OntModelSpec.OWL_MEM, null);
    
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
    public static final OntClass Dataset = m_model.createClass(NS + "Dataset");

    /** Generic service class */
    public static final OntClass GenericService = m_model.createClass(NS + "GenericService");
    
    /** Import class */
    public static final OntClass Import = m_model.createClass(NS + "Import");

    /** CSV import class */
    public static final OntClass CSVImport = m_model.createClass(NS + "CSVImport");

    /** RDF import class */
    public static final OntClass RDFImport = m_model.createClass(NS + "RDFImport");

    /** File class */
    public static final OntClass File = m_model.createClass(NS + "File");
    
    /** Content class */
    public static final OntClass Content = m_model.createClass(NS + "Content");

    /** URI syntax violation class */
    public static final OntClass URISyntaxViolation = m_model.createClass(NS + "URISyntaxViolation");
    
    /** Base property */
    public static final ObjectProperty base = m_model.createObjectProperty( NS + "base" );
    
    /** Violation property */
    public static final ObjectProperty violation = m_model.createObjectProperty( NS + "violation" );
    
    /** File property */
    public static final ObjectProperty file = m_model.createObjectProperty( NS + "file" );
    
    /** Action property */
    public static final ObjectProperty action = m_model.createObjectProperty( NS + "action" );

    /** Delimiter property */
    public static final DatatypeProperty delimiter = m_model.createDatatypeProperty( NS + "delimiter" );

    /** Resource type property */
    public static final ObjectProperty resourceType = m_model.createObjectProperty( NS + "resourceType" );

    /** Violation value property */
    public static final DatatypeProperty violationValue = m_model.createDatatypeProperty( NS + "violationValue" );
    
    /** Access to property */
    public static final ObjectProperty access_to = m_model.createObjectProperty(NS + "access-to"); // TO-DO: move to client-side?

    /** Absolute path property */
    public static final ObjectProperty absolutePath = m_model.createObjectProperty(NS + "absolutePath");
    
    /** Request URI property */
    public static final ObjectProperty requestUri = m_model.createObjectProperty(NS + "requestUri");
    
    /** Create graph property */
    public static final DatatypeProperty createGraph = m_model.createDatatypeProperty( NS + "createGraph" );
    
    /** Local graph property */
    public static final DatatypeProperty localGraph = m_model.createDatatypeProperty( NS + "localGraph" );

    /** Original graph property */
    public static final DatatypeProperty originalGraph = m_model.createDatatypeProperty( NS + "originalGraph" );

    /** Fragment property */
    public static final DatatypeProperty fragment = m_model.createDatatypeProperty( NS + "fragment" );

}
