/**
 *  Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>
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
 * Memento vocabulary (RFC 7089).
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see <a href="https://datatracker.ietf.org/doc/html/rfc7089">RFC 7089: HTTP Framework for Time-Based Access to Resource States -- Memento</a>
 */
public class MEM
{

    static
    {
        org.apache.jena.sys.JenaSystem.init(); // ensure Jena (RDFS vocab) is initialized before ontapi touches it
    }

    /** The RDF model that holds the vocabulary terms */
    private static OntModel m_model = OntModelFactory.createModel(OntSpecification.OWL2_FULL_MEM);

    /** The namespace of the vocabulary as a string */
    public static final String NS = "http://mementoweb.org/ns#";

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

    /** Original resource class */
    public static final Resource OriginalResource = m_model.createOntClass( NS + "OriginalResource" );

    /** Memento class */
    public static final Resource Memento = m_model.createOntClass( NS + "Memento" );

    /** TimeMap class */
    public static final Resource TimeMap = m_model.createOntClass( NS + "TimeMap" );

    /** Original resource property */
    public static final Property original = m_model.createObjectProperty( NS + "original" );

    /** Memento property */
    public static final Property memento = m_model.createObjectProperty( NS + "memento" );

    /** Timemap property */
    public static final Property timemap = m_model.createObjectProperty( NS + "timemap" );

    /** Memento datetime property */
    public static final Property mementoDatetime = m_model.createDataProperty( NS + "mementoDatetime" );

}
