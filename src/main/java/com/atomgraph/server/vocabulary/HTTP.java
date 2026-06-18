/*
 * Copyright 2014 Martynas Jusevičius <martynas@atomgraph.com>.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.atomgraph.server.vocabulary;

import org.apache.jena.ontapi.OntModelFactory;
import org.apache.jena.ontapi.OntSpecification;
import org.apache.jena.ontapi.model.OntModel;
import org.apache.jena.rdf.model.Property;

import org.apache.jena.rdf.model.Resource;

/**
 * HTTP Vocabulary in RDF
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see <a href="http://www.w3.org/TR/HTTP-in-RDF10/">HTTP Vocabulary in RDF 1.0</a>
 */
public class HTTP
{

    static
    {
        org.apache.jena.sys.JenaSystem.init(); // ensure Jena (RDFS vocab) is initialized before ontapi touches it
    }

    /** <p>The RDF model that holds the vocabulary terms</p> */
    private static OntModel m_model = OntModelFactory.createModel(OntSpecification.OWL2_DL_MEM);
    
    /** <p>The namespace of the vocabulary as a string</p> */
    public static final String NS = "http://www.w3.org/2011/http#";
    
    /** <p>The namespace of the vocabulary as a string</p>
     *  @see #NS */
    public static String getURI()
    {
	return NS;
    }
    
    /** <p>The namespace of the vocabulary as a resource</p> */
    public static final Resource NAMESPACE = m_model.createResource( NS );

    public static final Resource Response = m_model.createOntClass( NS + "Response" );
    
    public static final Property sc = m_model.createObjectProperty( NS + "sc" );

    public static final Property statusCodeValue = m_model.createDataProperty( NS + "statusCodeValue" );

    public static final Property reasonPhrase = m_model.createDataProperty( NS + "reasonPhrase" );
    
    public static final Property absoluteURI = m_model.createDataProperty( NS + "absoluteURI" );

    public static final Property absolutePath = m_model.createDataProperty( NS + "absolutePath" );

}
