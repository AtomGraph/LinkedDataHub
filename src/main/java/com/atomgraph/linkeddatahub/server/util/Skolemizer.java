/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */

package com.atomgraph.linkeddatahub.server.util;

import com.atomgraph.linkeddatahub.vocabulary.LDH;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import javax.ws.rs.core.UriBuilder;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Property;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.Statement;
import org.apache.jena.util.ResourceUtils;
import org.apache.jena.util.iterator.ExtendedIterator;

/**
 * Skolemizes blank node resources into URI resources.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class Skolemizer implements Function<Model, Model>
{

    private final String base;
    private final Property fragmentProperty;
    
    /**
     * Constructs skolemizer from base URI and optional fragment property.
     * 
     * @param base URI that fragments will be resolved against
     * @param fragmentProperty if specified, the skolemizer will use the value of this property as the fragment ID
     */
    public Skolemizer(String base, Property fragmentProperty)
    {
        this.base = base;
        this.fragmentProperty = fragmentProperty;
    }

    /**
     * Constructs skolemizer from base URI.
     * 
     * @param base URI that fragments will be resolved against. <code>ldh:fragment</code> is the default.
     */
    public Skolemizer(String base)
    {
        this(base, LDH.fragment);
    }
    
    /**
     * Skolemizes RDF graph by replacing blank node resources with fragment URI resources.
     * 
     * @param model input model
     * @return skolemized model
     */
    @Override
    public Model apply(Model model)
    {
        Map<Resource, String> bnodes = new HashMap<>();

        ExtendedIterator<Statement> it = model.listStatements().
            filterKeep((Statement stmt) -> (stmt.getSubject().isAnon() || stmt.getObject().isAnon()));
        try
        {
            while (it.hasNext())
            {
                Statement stmt = it.next();

                final String fragment;
                if (stmt.getSubject().hasProperty(getFragmentProperty())) fragment = stmt.getSubject().getProperty(getFragmentProperty()).getString();
                else fragment = "id" + UUID.randomUUID().toString(); // UUID can start with a number which is not legal for a fragment ID
                
                if (stmt.getSubject().isAnon()) bnodes.put(stmt.getSubject(), fragment);
                if (stmt.getObject().isAnon()) bnodes.put(stmt.getObject().asResource(), fragment);
            }
        }
        finally
        {
            it.close();
        }

        bnodes.entrySet().forEach(entry ->
            {
                if (getFragmentProperty() != null) entry.getKey().removeAll(getFragmentProperty()); // remove the fragment slug
                
                ResourceUtils.renameResource(entry.getKey(), UriBuilder.fromUri(getBase()).
                    fragment(entry.getValue()).
                    build().
                    toString());
            });

        return model;
    }

    /**
     * Returns the base URI against which fragments are resolved.
     * 
     * @return base URI
     */
    public String getBase()
    {
        return base;
    }
    
    /**
     * Returns the property which can be used to specify the fragment ID.
     * 
     * @return RDF property
     */
    public Property getFragmentProperty()
    {
        return fragmentProperty;
    }
    
}
