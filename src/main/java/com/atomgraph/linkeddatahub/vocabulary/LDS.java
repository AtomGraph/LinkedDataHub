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
 * LDS vocabulary.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class LDS
{

    static
    {
        org.apache.jena.sys.JenaSystem.init(); // ensure Jena (RDFS vocab) is initialized before ontapi touches it
    }

    /** The RDF model that holds the vocabulary terms */
    private static OntModel m_model = OntModelFactory.createModel(OntSpecification.OWL2_FULL_MEM);
    
    /** The namespace of the vocabulary as a string */
    public static final String NS = "https://w3id.org/atomgraph/linkeddatahub/dataspaces#";
    
    /**
     * The namespace of the vocabulary as a string
     * 
     * @return namespace URI
     * @see #NS
     */
    public static String getURI()
    {
        return NS;
    }
    
    /** The namespace of the vocabulary as a resource */
    public static final Resource NAMESPACE = m_model.createResource( NS );

    /** System context class */
    public static final Resource Context = m_model.createOntClass( NS + "Context" );
    
    /** Dataset class */
    public static final Resource Dataset = m_model.createOntClass( NS + "Dataset" );
    
    /** Dataspace class */
    public static final Resource Dataspace = m_model.createOntClass( NS + "Dataspace" );

    /** Admin dataspace class */
    public static final Resource AdminDataspace = m_model.createOntClass( NS + "AdminDataspace" );

    /** End-user dataspace class */
    public static final Resource EndUserDataspace = m_model.createOntClass( NS + "EndUserDataspace" );

    /** Package class */
    public static final Resource Package = m_model.createOntClass( NS + "Package" );

    /** Backend proxy property */
    public static final Property backendProxy = m_model.createObjectProperty( NS + "backendProxy" );

    /** Prefix property */
    public static final Property prefix = m_model.createObjectProperty( NS + "prefix" );
    
    /** Read-only property */
    public static final Property allowRead = m_model.createDataProperty( NS + "allowRead" );

    /** Origin property for subdomain-based dataspace matching */
    public static final Property origin = m_model.createObjectProperty(NS + "origin");

    /** Base URI property */
    public static final Property base = m_model.createObjectProperty( NS + "base" );

    /** Ontology property */
    public static final Property ontology = m_model.createObjectProperty( NS + "ontology" );

    /** SPARQL service property */
    public static final Property service = m_model.createObjectProperty( NS + "service" );

    /** Dataspace property (for Link header rel) */
    public static final Property dataspace = m_model.createObjectProperty( NS + "dataspace" );

    /** Versioning repository property linking a dataspace to a <code>doap:GitRepository</code> */
    public static final Property versioningRepository = m_model.createObjectProperty( NS + "versioningRepository" );

}
