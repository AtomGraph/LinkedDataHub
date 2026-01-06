/**
 *  Copyright 2014 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.server.vocabulary;

import org.apache.jena.ontology.DatatypeProperty;
import org.apache.jena.ontology.ObjectProperty;
import org.apache.jena.ontology.OntClass;
import org.apache.jena.ontology.OntModel;
import org.apache.jena.ontology.OntModelSpec;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;

/**
 * Linked Data Templates vocabulary.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class LDT
{
    /** <p>The RDF model that holds the vocabulary terms</p> */
    private static OntModel m_model = ModelFactory.createOntologyModel(OntModelSpec.OWL_MEM, null);
    
    /** <p>The namespace of the vocabulary as a string</p> */
    public static final String NS = "https://www.w3.org/ns/ldt#";
    
    /** <p>The namespace of the vocabulary as a string</p>
     *  @see #NS */
    public static String getURI()
    {
	return NS;
    }
    
    /** <p>The namespace of the vocabulary as a resource</p> */
    public static final Resource NAMESPACE = m_model.createResource( NS );

    public static final OntClass Application = m_model.createClass( NS + "Application" );

    public static final OntClass Ontology = m_model.createClass( NS + "Ontology" );

    public static final OntClass Template = m_model.createClass( NS + "Template" );

    public static final OntClass Parameter = m_model.createClass( NS + "Parameter" );

    public static final OntClass TemplateCall = m_model.createClass( NS + "TemplateCall" );

    public static final OntClass Argument = m_model.createClass( NS + "Argument" );

    public static final ObjectProperty base = m_model.createObjectProperty( NS + "base" );

    public static final ObjectProperty ontology = m_model.createObjectProperty( NS + "ontology" );

    public static final ObjectProperty service = m_model.createObjectProperty( NS + "service" );

    public static final ObjectProperty arg = m_model.createObjectProperty( NS + "arg" );
    
    public static final DatatypeProperty paramName = m_model.createDatatypeProperty( NS + "paramName" );    

    // "extends" is a reserved keyword in Java, obviously
    public static final ObjectProperty extends_ = m_model.createObjectProperty( NS + "extends" );

    public static final DatatypeProperty path = m_model.createDatatypeProperty( NS + "path" );
    
    public static final ObjectProperty query = m_model.createObjectProperty( NS + "query" );

    public static final ObjectProperty update = m_model.createObjectProperty( NS + "update" );

    public static final DatatypeProperty match = m_model.createDatatypeProperty( NS + "match" );

    public static final DatatypeProperty priority = m_model.createDatatypeProperty( NS + "priority" );

    public static final DatatypeProperty fragment = m_model.createDatatypeProperty( NS + "fragment" );

    public static final ObjectProperty param = m_model.createObjectProperty( NS + "param" );
    
    public static final ObjectProperty loadClass = m_model.createObjectProperty( NS + "loadClass" );

    public static final DatatypeProperty cacheControl = m_model.createDatatypeProperty( NS + "cacheControl" );
    
    public static final ObjectProperty lang = m_model.createObjectProperty( NS + "lang" );

    public static final ObjectProperty template = m_model.createObjectProperty( NS + "template" );

}
