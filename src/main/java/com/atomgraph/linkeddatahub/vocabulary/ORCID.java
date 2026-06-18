package com.atomgraph.linkeddatahub.vocabulary;

import org.apache.jena.ontapi.OntModelFactory;
import org.apache.jena.ontapi.OntSpecification;
import org.apache.jena.ontapi.model.OntModel;
import org.apache.jena.rdf.model.Property;

import org.apache.jena.rdf.model.Resource;

/**
 * ORCID-specific vocabulary.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ORCID
{

    static
    {
        org.apache.jena.sys.JenaSystem.init(); // ensure Jena (RDFS vocab) is initialized before ontapi touches it
    }

    /** The RDF model that holds the vocabulary terms */
    private static OntModel m_model = OntModelFactory.createModel(OntSpecification.OWL1_FULL_MEM);

    /** The namespace of the vocabulary as a string */
    public static final String NS = "https://w3id.org/atomgraph/linkeddatahub/services/orcid#";

    /**
     * The namespace of the vocabulary as a string
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

    /** Client ID property */
    public static final Property clientID = m_model.createDataProperty( NS + "clientID" );

    /** Client secret property */
    public static final Property clientSecret = m_model.createDataProperty( NS + "clientSecret" );

}
