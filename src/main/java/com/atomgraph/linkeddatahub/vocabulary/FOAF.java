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
 * FOAF vocabulary.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class FOAF
{
    /** The RDF model that holds the vocabulary terms */
    private static OntModel m_model = ModelFactory.createOntologyModel(OntModelSpec.OWL_MEM, null);
    
    /** The namespace of the vocabulary as a string */
    public static final String NS = "http://xmlns.com/foaf/0.1/";
    
    /**
     * The namespace of the vocabulary as a string.
     * 
     * @return URI string
     * @see #NS
     */
    public static String getURI()
    {
        return NS;
    }
    
    /** The namespace of the vocabulary as a resource */
    public static final Resource NAMESPACE = m_model.createResource( NS );

    /** Agent class */
    public static final OntClass Agent = m_model.createClass( NS + "Agent" );
    
    /** Person class */
    public static final OntClass Person = m_model.createClass( NS + "Person" );
    
    /** Document class */
    public static final OntClass Document = m_model.createClass( NS + "Document" );

    /** Name property */
    public static final DatatypeProperty name = m_model.createDatatypeProperty( NS + "name" );

    /** Given name property */
    public static final DatatypeProperty givenName = m_model.createDatatypeProperty( NS + "givenName" );

    /** Family name property */
    public static final DatatypeProperty familyName = m_model.createDatatypeProperty( NS + "familyName" );
    
    /** Mailbox property */
    public static final ObjectProperty mbox = m_model.createObjectProperty( NS + "mbox" );

    /** Based near property */
    public static final ObjectProperty based_near = m_model.createObjectProperty( NS + "based_near" );
    
    /** Member property */
    public static final ObjectProperty member = m_model.createObjectProperty( NS + "member" );

    /** Primary topic property */
    public static final ObjectProperty primaryTopic = m_model.createObjectProperty( NS + "primaryTopic" );
    
    /** Is primary topic of property */
    public static final ObjectProperty isPrimaryTopicOf = m_model.createObjectProperty( NS + "isPrimaryTopicOf" );
    
    /** Maker property */
    public static final ObjectProperty maker = m_model.createObjectProperty( NS + "maker" );

    /** Account property */
    public static final ObjectProperty account = m_model.createObjectProperty( NS + "account" );

    /** Image property */
    public static final ObjectProperty img = m_model.createObjectProperty( NS + "img" );
    
}
