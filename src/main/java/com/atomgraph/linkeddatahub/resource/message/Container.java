/**
 *  Copyright 2020 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.resource.message;

import com.atomgraph.client.util.DataManager;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.core.client.LinkedDataClient;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.model.ClientUriInfo;
import com.atomgraph.linkeddatahub.server.model.impl.ResourceBase;
import com.atomgraph.processor.model.TemplateCall;
import java.net.URI;
import java.util.Optional;
import javax.inject.Inject;
import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.container.ResourceContext;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.SecurityContext;
import javax.ws.rs.core.UriInfo;
import javax.ws.rs.ext.Providers;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.rdf.model.InfModel;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.vocabulary.RDF;

/**
 *
 * @author Martynas Jusevičius <martynas@atomgraph.com>
 */
public class Container extends ResourceBase
{
    
    @Inject
    public Container(@Context UriInfo uriInfo, ClientUriInfo clientUriInfo, @Context Request request, MediaTypes mediaTypes,
            Service service, com.atomgraph.linkeddatahub.apps.model.Application application,
            Ontology ontology, Optional<TemplateCall> templateCall,
            @Context HttpHeaders httpHeaders, @Context ResourceContext resourceContext,
            @Context HttpServletRequest httpServletRequest, @Context SecurityContext securityContext,
            DataManager dataManager, @Context Providers providers,
            com.atomgraph.linkeddatahub.Application system)
    {
        super(uriInfo, clientUriInfo, request, mediaTypes,
                service, application, ontology, templateCall,
                httpHeaders, resourceContext,
                httpServletRequest, securityContext,
                dataManager, providers,
                system);
    }

    @Override
    public Response construct(InfModel infModel)
    {
        
        ResIterator it = infModel.listSubjectsWithProperty(RDF.type, ResourceFactory.createResource("https://w3id.org/atomgraph/linkeddatahub/modules/messages#Message"));
        try
        {
            while (it.hasNext())
            {
                Resource message = it.next();
                Resource recipient = message.getPropertyResourceValue(ResourceFactory.createProperty("https://w3id.org/atomgraph/linkeddatahub/modules/messages#recipient"));
                // TO-DO get inbox container from Agent
                URI inbox = getUriInfo().getBaseUriBuilder().path("messages/received/").build();
                LinkedDataClient ldc = LinkedDataClient.create(getClient().target(inbox), getMediaTypes());
                ldc.post(message.getModel());
            }
        }
        finally
        {
            it.close();
        }
        
        return super.construct(infModel);
    }
    
}
