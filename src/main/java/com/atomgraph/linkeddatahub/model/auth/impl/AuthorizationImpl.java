/**
 *  Copyright 2022 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.model.auth.impl;

import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.linkeddatahub.model.auth.Authorization;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import java.net.URI;
import java.util.List;
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
    public List<Resource> getModes()
    {
        StmtIterator it = listProperties(AC.mode);
        try
        {
            return it.toList().stream().map(stmt -> stmt.getResource()).collect(Collectors.toList());
        }
        finally
        {
            it.close();
        }
    }

    @Override
    public List<URI> getModeURIs()
    {
        return getModes().stream().map(resource -> URI.create(resource.getURI())).collect(Collectors.toList());
    }

}
