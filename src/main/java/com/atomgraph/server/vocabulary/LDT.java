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

import org.apache.jena.ontapi.OntModelFactory;
import org.apache.jena.ontapi.OntSpecification;
import org.apache.jena.ontapi.model.OntModel;
import org.apache.jena.rdf.model.Property;

import org.apache.jena.rdf.model.Resource;

/**
 * Linked Data Templates vocabulary.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class LDT
{

    static
    {
        org.apache.jena.sys.JenaSystem.init(); // ensure Jena (RDFS vocab) is initialized before ontapi touches it
    }
    /** <p>The RDF model that holds the vocabulary terms</p> */
    private static OntModel m_model = OntModelFactory.createModel(OntSpecification.OWL2_DL_MEM);
    
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

    public static final Resource Application = m_model.createOntClass( NS + "Application" );

    public static final Resource Ontology = m_model.createOntClass( NS + "Ontology" );

    public static final Resource Template = m_model.createOntClass( NS + "Template" );

    public static final Resource Parameter = m_model.createOntClass( NS + "Parameter" );

    public static final Resource TemplateCall = m_model.createOntClass( NS + "TemplateCall" );

    public static final Resource Argument = m_model.createOntClass( NS + "Argument" );

    public static final Property base = m_model.createObjectProperty( NS + "base" );

    public static final Property ontology = m_model.createObjectProperty( NS + "ontology" );

    public static final Property service = m_model.createObjectProperty( NS + "service" );

    public static final Property arg = m_model.createObjectProperty( NS + "arg" );
    
    public static final Property paramName = m_model.createDataProperty( NS + "paramName" );    

    // "extends" is a reserved keyword in Java, obviously
    public static final Property extends_ = m_model.createObjectProperty( NS + "extends" );

    public static final Property path = m_model.createDataProperty( NS + "path" );
    
    public static final Property query = m_model.createObjectProperty( NS + "query" );

    public static final Property update = m_model.createObjectProperty( NS + "update" );

    public static final Property match = m_model.createDataProperty( NS + "match" );

    public static final Property priority = m_model.createDataProperty( NS + "priority" );

    public static final Property fragment = m_model.createDataProperty( NS + "fragment" );

    public static final Property param = m_model.createObjectProperty( NS + "param" );
    
    public static final Property loadClass = m_model.createObjectProperty( NS + "loadClass" );

    public static final Property cacheControl = m_model.createDataProperty( NS + "cacheControl" );
    
    public static final Property lang = m_model.createObjectProperty( NS + "lang" );

    public static final Property template = m_model.createObjectProperty( NS + "template" );

}
