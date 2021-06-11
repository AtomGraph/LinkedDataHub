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
package com.atomgraph.linkeddatahub.sitemap.resource.ontology;

import com.atomgraph.core.MediaTypes;
import com.atomgraph.core.exception.ConfigurationException;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.model.ClientUriInfo;
import com.atomgraph.client.util.DataManager;
import com.atomgraph.linkeddatahub.vocabulary.APLC;
import com.atomgraph.linkeddatahub.vocabulary.LSMT;
import com.atomgraph.processor.util.Skolemizer;
import com.atomgraph.processor.model.TemplateCall;
import com.atomgraph.processor.util.Validator;
import com.atomgraph.server.exception.SPINConstraintViolationException;
import com.atomgraph.spinrdf.constraints.ConstraintViolation;
import java.util.List;
import java.util.Optional;
import javax.inject.Inject;
import javax.servlet.ServletConfig;
import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.container.ResourceContext;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.SecurityContext;
import javax.ws.rs.core.UriInfo;
import javax.ws.rs.ext.Providers;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.query.Query;
import org.apache.jena.query.QueryExecution;
import org.apache.jena.query.QueryExecutionFactory;
import org.apache.jena.query.QueryFactory;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.RDF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS resource that handles ontology container requests.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class Container extends com.atomgraph.linkeddatahub.server.model.impl.ResourceBase
{
    private static final Logger log = LoggerFactory.getLogger(Container.class);

    private final Query ontologyImportQuery;

    @Inject
    public Container(@Context UriInfo uriInfo, ClientUriInfo clientUriInfo, @Context Request request, MediaTypes mediaTypes,
            Optional<Service> service, Optional<com.atomgraph.linkeddatahub.apps.model.Application> application,
            Optional<Ontology> ontology, Optional<TemplateCall> templateCall,
            @Context HttpHeaders httpHeaders, @Context ResourceContext resourceContext,
            @Context HttpServletRequest httpServletRequest, @Context SecurityContext securityContext,
            DataManager dataManager, @Context Providers providers,
            com.atomgraph.linkeddatahub.Application system, @Context final ServletConfig servletConfig)
    {
        super(uriInfo, clientUriInfo, request, mediaTypes, 
                service, application,
                ontology, templateCall,
                httpHeaders, resourceContext,
                httpServletRequest, securityContext,
                dataManager, providers,
                system);
        
        String ontologyImportQueryString = servletConfig.getServletContext().getInitParameter(APLC.ontologyImportQuery.getURI());
        if (ontologyImportQueryString == null) throw new WebApplicationException(new ConfigurationException(APLC.ontologyImportQuery));
        ontologyImportQuery = QueryFactory.create(ontologyImportQueryString, uriInfo.getBaseUri().toString());
    }
    
    @Override
    public Response post(Model model)
    {
        Resource sourceArg = getArgument(model, LSMT.Source);
        if (sourceArg != null)
        {
            Resource source = sourceArg.getRequiredProperty(RDF.value).getResource();
            Model sourceModel = getDataManager().loadModel(source.getURI());
            Model transformedModel = ModelFactory.createDefaultModel();
            
            try (QueryExecution qex = QueryExecutionFactory.create(getOntologyImportQuery(), sourceModel))
            {
                qex.execConstruct(transformedModel);
                
                Validator validator = new Validator(getOntology().getOntModel());
                List<ConstraintViolation> cvs = validator.validate(transformedModel);
                if (!cvs.isEmpty())
                {
                    if (log.isDebugEnabled()) log.debug("SPIN constraint violations: {}", cvs);
                    throw new SPINConstraintViolationException(cvs, transformedModel);
                }

                transformedModel = new Skolemizer(getOntology(), getUriInfo().getBaseUriBuilder(), getUriInfo().getAbsolutePathBuilder()).build(transformedModel);

                super.post(transformedModel).close();
            }
            
            return get();
        }

        return super.post(model);
    }
    
    public Resource getArgument(Model model, Resource type)
    {
        if (model == null) throw new IllegalArgumentException("Model cannot be null");
        if (type == null) throw new IllegalArgumentException("Resource cannot be null");

        ResIterator it = model.listSubjectsWithProperty(RDF.type, type);

        try
        {
            if (it.hasNext()) return it.next();
        }
        finally
        {
            it.close();
        }
        
        return null;
    }
    
    public Query getOntologyImportQuery()
    {
        return ontologyImportQuery;
    }
    
}