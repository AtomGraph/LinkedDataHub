/*
 * Copyright 2016 Martynas Jusevičius <martynas@atomgraph.com>.
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
package com.atomgraph.linkeddatahub.vocabulary;

import org.apache.jena.ontapi.OntModelFactory;
import org.apache.jena.ontapi.OntSpecification;
import org.apache.jena.ontapi.model.OntModel;
import org.apache.jena.rdf.model.Property;

import org.apache.jena.rdf.model.Resource;

/**
 * Document Hierarchy vocabulary.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class DH
{

    static
    {
        org.apache.jena.sys.JenaSystem.init(); // ensure Jena (RDFS vocab) is initialized before ontapi touches it
    }

    /** <p>The RDF model that holds the vocabulary terms</p> */
    private static OntModel m_model = OntModelFactory.createModel(OntSpecification.OWL2_FULL_MEM);
    
    /** <p>The namespace of the vocabulary as a string</p> */
    public static final String NS = "https://www.w3.org/ns/ldt/document-hierarchy#";
    
    /** <p>The namespace of the vocabulary as a string</p>
     *  @return namespace URI
     *  @see #NS */
    public static String getURI()
    {
        return NS;
    }
    
    /** <p>The namespace of the vocabulary as a resource</p> */
    public static final Resource NAMESPACE = m_model.createResource( NS );

    /** Document class */
    public static final Resource Document = m_model.createOntClass( NS + "Document" );
    
    /** Container class */
    public static final Resource Container = m_model.createOntClass( NS + "Container" );
    
    /** Item class */
    public static final Resource Item = m_model.createOntClass( NS + "Item" );
    
    /** Slug property */
    public static final Property slug = m_model.createDataProperty( NS + "slug" );

}
