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
package com.atomgraph.linkeddatahub.server.model.impl;

import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.model.Agent;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.linkeddatahub.vocabulary.APL;
import com.atomgraph.linkeddatahub.vocabulary.PROV;
import com.atomgraph.linkeddatahub.vocabulary.VoID;
import com.atomgraph.processor.vocabulary.DH;
import com.atomgraph.processor.vocabulary.SIOC;
import java.net.URI;
import java.util.Calendar;
import java.util.Optional;
import javax.ws.rs.DefaultValue;
import javax.ws.rs.POST;
import javax.ws.rs.QueryParam;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.SecurityContext;
import javax.ws.rs.core.UriBuilder;
import javax.ws.rs.core.UriInfo;
import org.apache.commons.codec.digest.DigestUtils;
import org.apache.jena.query.Dataset;
import org.apache.jena.query.DatasetFactory;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.Statement;
import org.apache.jena.rdf.model.StmtIterator;
import org.apache.jena.sparql.vocabulary.FOAF;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * LinkedDataHub Graph Store implementation.
 * We need to subclass the Core class because we're injecting a subclass of Service.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class GraphStoreImpl extends com.atomgraph.core.model.impl.GraphStoreImpl
{
    
    private static final Logger log = LoggerFactory.getLogger(GraphStoreImpl.class);

    private final UriInfo uriInfo;
    private final SecurityContext securityContext;
    
    public GraphStoreImpl(@Context Request request, Optional<Service> service, @Context MediaTypes mediaTypes,
            @Context UriInfo uriInfo, @Context SecurityContext securityContext)
    {
        super(request, service.get(), mediaTypes);
        this.uriInfo = uriInfo;
        this.securityContext = securityContext;
    }
    
    @POST
    @Override
    public Response post(Model model, @QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        if (log.isDebugEnabled()) log.debug("POST Graph Store request with RDF payload: {} payload size(): {}", model, model.size());
        
        if (model.isEmpty()) return Response.noContent().build();
        
        if (defaultGraph)
        {
            if (log.isDebugEnabled()) log.debug("POST Model to default graph");
            getDatasetAccessor().add(model);
            return Response.ok().build();
        }
        else
        {
            final boolean existingGraph;
            if (graphUri != null) existingGraph = getDatasetAccessor().containsModel(graphUri.toString());
            else
            {
                existingGraph = false;
                
                ResIterator it = model.listSubjects();
                graphUri = URI.create(it.next().getURI()); // there has to be a subject resource since we checked (above) that the model is not empty
                it.close();
            }

            // is this implemented correctly? The specification is not very clear.
            if (log.isDebugEnabled()) log.debug("POST Model to named graph with URI: {} Did it already exist? {}", graphUri, existingGraph);
            getDatasetAccessor().add(graphUri.toString(), model);

            if (existingGraph) return Response.ok().build();
            else return Response.created(graphUri).build();
        }
    }
    
    public Dataset splitDefaultModel(Model model)
    {
        return splitDefaultModel(model, getUriInfo().getBaseUri(), getAgent(), Calendar.getInstance());
    }
    
    public Dataset splitDefaultModel(Model model, URI base, Agent agent, Calendar created)
    {
        if (model == null) throw new IllegalArgumentException("Model cannot be null");
        if (base == null) throw new IllegalArgumentException("URI base cannot be null");

        Dataset dataset = DatasetFactory.create();

        StmtIterator it = model.listStatements(); // TO-DO: refactor using ResIterator?
        try
        {
            while (it.hasNext())
            {
                Statement stmt = it.next();
                
                String docURI = null;
//                final String hash;
//                if (stmt.getSubject().isURIResource())
//                {
//                    docURI = stmt.getSubject().getURI();
//                    if (docURI.contains("#")) docURI = docURI.substring(0, docURI.indexOf("#")); // strip the fragment, leaving only document URIs
//                    hash = DigestUtils.sha1Hex(docURI);
//                }
//                else hash = DigestUtils.sha1Hex(stmt.getSubject().getId().getBlankNodeId().toString());
                
                String graphURI = docURI; // UriBuilder.fromUri(base).path("graphs/{hash}/").build(hash).toString(); // TO-DO: use the apl:GraphItem ldt:path value
                Model namedModel = dataset.getNamedModel(graphURI);
                namedModel.add(stmt);

                // create the meta-graph with provenance metadata
                String graphHash = DigestUtils.sha1Hex(graphURI);
                String metaGraphURI = UriBuilder.fromUri(base).path("graphs/{hash}/").build(graphHash).toString();
                Model namedMetaModel = dataset.getNamedModel(metaGraphURI);
                if (namedMetaModel.isEmpty())
                {
                    Resource graph = namedMetaModel.createResource(graphURI + "#this");
                    Resource graphDoc = namedMetaModel.createResource(graphURI).
                        addProperty(RDF.type, DH.Item).
                        addProperty(SIOC.HAS_SPACE, namedMetaModel.createResource(getUriInfo().getBaseUri().toString())).
                        addProperty(SIOC.HAS_CONTAINER, namedMetaModel.createResource(UriBuilder.fromUri(base).path("graphs/").build().toString())).
                        addProperty(FOAF.maker, agent).
                        addProperty(ACL.owner, agent).
                        addProperty(FOAF.primaryTopic, graph).
                        addLiteral(PROV.generatedAtTime, namedMetaModel.createTypedLiteral(Calendar.getInstance()));
                    graph.addProperty(RDF.type, APL.Dataset).
                        addProperty(FOAF.isPrimaryTopicOf, graphDoc);

                    // add provenance metadata for base URI-relative (internal) documents
                    if (docURI != null && !getUriInfo().getBaseUri().relativize(URI.create(docURI)).isAbsolute())
                    {
                        Resource doc = namedMetaModel.createResource(docURI).
                            addProperty(SIOC.HAS_SPACE, namedMetaModel.createResource(getUriInfo().getBaseUri().toString())).
                            addProperty(VoID.inDataset, graph);
                    
                        if (agent != null) doc.addProperty(FOAF.maker, agent).
                            addProperty(ACL.owner, agent);
                        
                        if (created != null) doc.addLiteral(DCTerms.created, created);
                    }
                }
            }
        }
        finally
        {
            it.close();
        }
        
        return dataset;
    }
    
    public UriInfo getUriInfo()
    {
        return uriInfo;
    }
    
    /**
     * Gets agent authenticated for the current request.
     * 
     * @return agent
     */
    public Agent getAgent()
    {
        if (getSecurityContext() != null &&
                getSecurityContext().getUserPrincipal() != null &&
                getSecurityContext().getUserPrincipal() instanceof Agent)
            return (Agent)getSecurityContext().getUserPrincipal();
        
        return null;
    }
    
    public SecurityContext getSecurityContext()
    {
        return securityContext;
    }
    
}
