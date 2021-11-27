/**
 *  Copyright 2021 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.resource;

import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.model.impl.GraphStoreImpl;
import java.net.URI;
import java.util.HashSet;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import javax.inject.Inject;
import javax.ws.rs.DefaultValue;
import javax.ws.rs.POST;
import javax.ws.rs.QueryParam;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.UriBuilder;
import javax.ws.rs.core.UriInfo;
import javax.ws.rs.ext.Providers;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.Statement;
import org.apache.jena.util.ResourceUtils;
import org.apache.jena.util.iterator.ExtendedIterator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class Skolemize extends GraphStoreImpl
{

    private static final Logger log = LoggerFactory.getLogger(Add.class);

    @Inject
    public Skolemize(@Context Request request, @Context UriInfo uriInfo, MediaTypes mediaTypes,
            Optional<Ontology> ontology, Optional<Service> service,
            @Context Providers providers, com.atomgraph.linkeddatahub.Application system)
    {
        super(request, uriInfo, mediaTypes, ontology, service, providers, system);
    }
    
    @POST
    @Override
    public Response post(Model unused, @QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        Model model = getDatasetAccessor().getModel(graphUri.toString());
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
            ResourceUtils.renameResource(bnode, UriBuilder.fromUri(graphUri).
                fragment("id{uuid}").
                build(UUID.randomUUID().toString()).toString())); // TO-DO: replace Skolemizer with this?
        
        // replace the existing graph with the skolemized graph
        return super.put(model, defaultGraph, graphUri);
    }
    
}
