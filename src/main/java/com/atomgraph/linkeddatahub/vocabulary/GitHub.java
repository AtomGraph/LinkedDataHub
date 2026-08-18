package com.atomgraph.linkeddatahub.vocabulary;

import org.apache.jena.ontapi.OntModelFactory;
import org.apache.jena.ontapi.OntSpecification;
import org.apache.jena.ontapi.model.OntModel;
import org.apache.jena.rdf.model.Property;

import org.apache.jena.rdf.model.Resource;

/**
 * GitHub-specific vocabulary.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class GitHub
{

    static
    {
        org.apache.jena.sys.JenaSystem.init(); // ensure Jena (RDFS vocab) is initialized before ontapi touches it
    }

    /** The RDF model that holds the vocabulary terms */
    private static OntModel m_model = OntModelFactory.createModel(OntSpecification.OWL2_FULL_MEM);

    /** The namespace of the vocabulary as a string */
    public static final String NS = "https://w3id.org/atomgraph/linkeddatahub/services/github#";

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

    /** Git branch property of a versioning repository */
    public static final Property branch = m_model.createDataProperty( NS + "branch" );

    /** Path prefix property for graph files in a versioning repository */
    public static final Property pathPrefix = m_model.createDataProperty( NS + "pathPrefix" );

}
