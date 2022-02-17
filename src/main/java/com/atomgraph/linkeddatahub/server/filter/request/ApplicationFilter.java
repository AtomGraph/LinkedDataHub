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
package com.atomgraph.linkeddatahub.server.filter.request;

import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import com.atomgraph.linkeddatahub.writer.Mode;
import java.io.IOException;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;
import javax.annotation.Priority;
import javax.inject.Inject;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.ContainerRequestFilter;
import javax.ws.rs.container.PreMatching;
import javax.ws.rs.core.HttpHeaders;
import org.apache.jena.rdf.model.Resource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Request filter that sets request attribute with name <code>ldt:Application</code> and current application as the value
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@PreMatching
@Priority(700)
public class ApplicationFilter implements ContainerRequestFilter
{

    private static final Logger log = LoggerFactory.getLogger(ApplicationFilter.class);
    
    @Inject com.atomgraph.linkeddatahub.Application system;

    @Override
    public void filter(ContainerRequestContext request) throws IOException
    {
        // there always have to be an app
        Resource appResource = getSystem().matchApp(LAPP.Application, request.getUriInfo().getAbsolutePath());
        if (appResource == null) throw new IllegalStateException("Request URI '" + request.getUriInfo().getAbsolutePath() + "' has not matched any lapp:Application");

        // instead of InfModel, do faster explicit checks for subclasses and add rdf:type
        if (!appResource.canAs(com.atomgraph.linkeddatahub.apps.model.Application.class) &&
                !appResource.canAs(com.atomgraph.linkeddatahub.apps.model.EndUserApplication.class) &&
                !appResource.canAs(com.atomgraph.linkeddatahub.apps.model.AdminApplication.class))
            throw new IllegalStateException("Resource <" + appResource + "> cannot be cast to lapp:Application");

        com.atomgraph.linkeddatahub.apps.model.Application app = appResource.as(com.atomgraph.linkeddatahub.apps.model.Application.class);
        request.setProperty(LAPP.Application.getURI(), app); // wrap into a helper class so it doesn't interfere with injection of Application
        request.setRequestUri(app.getBaseURI(), request.getUriInfo().getRequestUri()); // there's always ldt:base

        // override "Accept" header using then ?accept= param value. TO-DO: move to a separate ContainerRequestFilter?
        // has to go before ?uri logic because that will change the UriInfo
        if (request.getUriInfo().getQueryParameters().containsKey(AC.accept.getLocalName()))
            request.getHeaders().putSingle(HttpHeaders.ACCEPT, request.getUriInfo().getQueryParameters().getFirst(AC.accept.getLocalName()));

        // used by ModeFactory and ModelXSLTWriterBase
        if (request.getUriInfo().getQueryParameters().containsKey(AC.mode.getLocalName()))
        {
            List<String> modeUris = request.getUriInfo().getQueryParameters().get(AC.mode.getLocalName());
            List<Mode> modes = modeUris.stream().map(Mode::new).collect(Collectors.toList());
            request.setProperty(AC.mode.getURI(), modes);
        }
        else request.setProperty(AC.mode.getURI(), Collections.emptyList());

        // TO-DO: move Dataset logic to a separate ContainerRequestFilter?
        Resource datasetResource = getSystem().matchDataset(LAPP.Dataset, request.getUriInfo().getAbsolutePath());
        if (datasetResource != null)
        {
            // instead of InfModel, do faster explicit checks for subclasses and add rdf:type
            if (!datasetResource.canAs(com.atomgraph.linkeddatahub.apps.model.Dataset.class))
                throw new IllegalStateException("Resource <" + datasetResource + "> cannot be cast to lapp:Dataset");

            com.atomgraph.linkeddatahub.apps.model.Dataset dataset = datasetResource.as(com.atomgraph.linkeddatahub.apps.model.Dataset.class);
            if (log.isDebugEnabled()) log.debug("Request URI <{}> has matched a lapp:Dataset <{}>", request.getUriInfo().getRequestUri(), dataset.getURI());
            request.setProperty(LAPP.Dataset.getURI(), Optional.of(dataset));
        }
        else
        {
            if (log.isDebugEnabled()) log.debug("Request URI <{}> has not matched any lapp:Dataset", request.getUriInfo().getRequestUri());
            request.setProperty(LAPP.Dataset.getURI(), Optional.empty());
        }
    }

    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }
    
}