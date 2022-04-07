/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */

package com.atomgraph.linkeddatahub.server.util;

import java.util.HashSet;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import javax.ws.rs.core.UriBuilder;
import org.apache.jena.rdf.model.Model;
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
    
    /**
     * Constructs skolemizer from base URI.
     * 
     * @param base URI that fragments will be resolved against
     */
    public Skolemizer(String base)
    {
        this.base = base;
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
        Set<Resource> bnodes = new HashSet<>();

        ExtendedIterator<Statement> it = model.listStatements().
            filterKeep((Statement stmt) -> (stmt.getSubject().isAnon() || stmt.getObject().isAnon()));
        try
        {
            while (it.hasNext())
            {
                Statement stmt = it.next();

                if (stmt.getSubject().isAnon()) bnodes.add(stmt.getSubject());
                if (stmt.getObject().isAnon()) bnodes.add(stmt.getObject().asResource());
            }
        }
        finally
        {
            it.close();
        }

        bnodes.stream().forEach(bnode ->
            ResourceUtils.renameResource(bnode, UriBuilder.fromUri(getBase()).
                fragment("id{uuid}").
                build(UUID.randomUUID().toString()).toString()));

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
    
}
