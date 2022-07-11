// Copyright 2022 Martynas Jusevičius <martynas@atomgraph.com>
// SPDX-FileCopyrightText: 2017-2022 2017 Martynas Jusevicius, <martynas@atomgraph.com> et al.
//
// SPDX-License-Identifier: Apache-2.0

package com.atomgraph.linkeddatahub.model.auth.impl;

import com.atomgraph.linkeddatahub.model.auth.Authorization;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import java.net.URI;
import java.util.Set;
import java.util.stream.Collectors;
import org.apache.jena.enhanced.EnhGraph;
import org.apache.jena.enhanced.EnhNode;
import org.apache.jena.enhanced.Implementation;
import org.apache.jena.graph.Node;
import org.apache.jena.ontology.ConversionException;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.StmtIterator;
import org.apache.jena.rdf.model.impl.ResourceImpl;
import org.apache.jena.vocabulary.RDF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class AuthorizationImpl extends ResourceImpl implements Authorization
{

    private static final Logger log = LoggerFactory.getLogger(AuthorizationImpl.class);

    /**
     * The implementation factory.
     */
    public static Implementation factory = new Implementation() 
    {
        
        @Override
        public EnhNode wrap(Node node, EnhGraph enhGraph)
        {
            if (canWrap(node, enhGraph))
            {
                return new AuthorizationImpl(node, enhGraph);
            }
            else
            {
                throw new ConversionException( "Cannot convert node " + node.toString() + " to Import: it does not have rdf:type acl:Authorization or equivalent");
            }
        }

        @Override
        public boolean canWrap(Node node, EnhGraph eg)
        {
            if (eg == null) throw new IllegalArgumentException("EnhGraph cannot be null");

            return eg.asGraph().contains(node, RDF.type.asNode(), ACL.Authorization.asNode());
        }
    };
    
    /**
     * Constructs instance from graph node.
     * 
     * @param n node
     * @param g graph
     */
    public AuthorizationImpl(Node n, EnhGraph g)
    {
        super(n, g);
    }
    
    @Override
    public Set<Resource> getModes()
    {
        StmtIterator it = listProperties(ACL.mode);
        try
        {
            return it.toList().stream().map(stmt -> stmt.getResource()).collect(Collectors.toSet());
        }
        finally
        {
            it.close();
        }
    }

    @Override
    public Set<URI> getModeURIs()
    {
        return getModes().stream().map(resource -> URI.create(resource.getURI())).collect(Collectors.toSet());
    }

}
