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
public class AC
{
    /** <p>The RDF model that holds the vocabulary terms</p> */
    private static OntModel m_model = ModelFactory.createOntologyModel(OntModelSpec.OWL_MEM, null);
    
    /** <p>The namespace of the vocabulary as a string</p> */
    public static final String NS = "http://atomgraph.com/ns/client#";
    
    /** <p>The namespace of the vocabulary as a string</p>
     *  @see #NS */
    public static String getURI()
    {
        return NS;
    }
    
    /** <p>The namespace of the vocabulary as a resource</p> */
    public static final Resource NAMESPACE = m_model.createResource( NS );
    
    public static final OntClass ConstructMode = m_model.createClass( NS + "ConstructMode" );

    public static final ObjectProperty chart_type = m_model.createObjectProperty( NS + "chart-type" );
    
    public static final ObjectProperty category = m_model.createObjectProperty( NS + "category" );
    
    public static final ObjectProperty series = m_model.createObjectProperty( NS + "series" );

    public static final ObjectProperty access_to = m_model.createObjectProperty( NS + "access-to" );

    public static final DatatypeProperty label = m_model.createDatatypeProperty( NS + "label" );

    public static final DatatypeProperty filter_regex = m_model.createDatatypeProperty( NS + "filter-regex" );

    public static final DatatypeProperty filter_in = m_model.createDatatypeProperty( NS + "filter-in" );

    public static final DatatypeProperty filter_ge = m_model.createDatatypeProperty( NS + "filter-ge" );

    public static final DatatypeProperty filter_le = m_model.createDatatypeProperty( NS + "filter-le" );

}
