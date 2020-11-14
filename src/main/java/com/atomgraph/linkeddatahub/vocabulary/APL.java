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
public class APL
{
    /** <p>The RDF model that holds the vocabulary terms</p> */
    private static OntModel m_model = ModelFactory.createOntologyModel(OntModelSpec.OWL_MEM, null);
    
    /** <p>The namespace of the vocabulary as a string</p> */
    public static final String NS = "https://w3id.org/atomgraph/linkeddatahub/domain#";
    
    /** <p>The namespace of the vocabulary as a string</p>
     *  @see #NS */
    public static String getURI()
    {
        return NS;
    }
    
    /** <p>The namespace of the vocabulary as a resource</p> */
    public static final Resource NAMESPACE = m_model.createResource( NS );

    // DOMAIN

    public static final OntClass Dataset = m_model.createClass(NS + "Dataset");

    public static final OntClass GenericService = m_model.createClass(NS + "GenericService");
    
    public static final OntClass DydraService = m_model.createClass(NS + "DydraService");
    
    public static final OntClass Import = m_model.createClass(NS + "Import");

    public static final OntClass CSVImport = m_model.createClass(NS + "CSVImport");

    public static final OntClass XMLImport = m_model.createClass(NS + "XMLImport");
    
    public static final OntClass RDFImport = m_model.createClass(NS + "RDFImport");

    public static final OntClass ImportRun = m_model.createClass(NS + "ImportRun");
    
    public static final OntClass File = m_model.createClass(NS + "File");

    public static final OntClass Counter = m_model.createClass(NS + "Counter");
    
    public static final OntClass CountMode = m_model.createClass(NS + "CountMode");

    public static final OntClass ChartMode = m_model.createClass(NS + "ChartMode");

    public static final OntClass ConstructorMode = m_model.createClass(NS + "ConstructorMode");

    public static final OntClass URISyntaxViolation = m_model.createClass(NS + "URISyntaxViolation");
    
    public static final ObjectProperty baseUri = m_model.createObjectProperty( NS + "baseUri" );
    
    public static final ObjectProperty violation = m_model.createObjectProperty( NS + "violation" );
    
    public static final ObjectProperty file = m_model.createObjectProperty( NS + "file" );
    
    public static final ObjectProperty action = m_model.createObjectProperty( NS + "action" );

    public static final DatatypeProperty delimiter = m_model.createDatatypeProperty( NS + "delimiter" );

    public static final ObjectProperty resourceType = m_model.createObjectProperty( NS + "resourceType" );

    public static final DatatypeProperty violationValue = m_model.createDatatypeProperty( NS + "violationValue" );
    
    public static final ObjectProperty access_to = m_model.createObjectProperty(NS + "access-to"); // TO-DO: move to client-side?

}
