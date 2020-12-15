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
 * Created by Martynas on 10/15/2017.
 */
public class FOAF
{
    /** <p>The RDF model that holds the vocabulary terms</p> */
    private static OntModel m_model = ModelFactory.createOntologyModel(OntModelSpec.OWL_MEM, null);
    
    /** <p>The namespace of the vocabulary as a string</p> */
    public static final String NS = "http://xmlns.com/foaf/0.1/";
    
    /** <p>The namespace of the vocabulary as a string</p>
     *  @see #NS */
    public static String getURI()
    {
        return NS;
    }
    
    /** <p>The namespace of the vocabulary as a resource</p> */
    public static final Resource NAMESPACE = m_model.createResource( NS );

    public static final OntClass Agent = m_model.createClass( NS + "Agent" );
    
    public static final OntClass Document = m_model.createClass( NS + "Document" );

    public static final DatatypeProperty name = m_model.createDatatypeProperty( NS + "name" );

    public static final DatatypeProperty givenName = m_model.createDatatypeProperty( NS + "givenName" );

    public static final DatatypeProperty familyName = m_model.createDatatypeProperty( NS + "familyName" );
    
    public static final ObjectProperty mbox = m_model.createObjectProperty( NS + "mbox" );

    public static final ObjectProperty based_near = m_model.createObjectProperty( NS + "based_near" );
    
    public static final ObjectProperty member = m_model.createObjectProperty( NS + "member" );

    public static final ObjectProperty primaryTopic = m_model.createObjectProperty( NS + "primaryTopic" );
    
    public static final ObjectProperty isPrimaryTopicOf = m_model.createObjectProperty( NS + "isPrimaryTopicOf" );
    
    public static final ObjectProperty maker = m_model.createObjectProperty( NS + "maker" );

    public static final ObjectProperty account = m_model.createObjectProperty( NS + "account" );

}
