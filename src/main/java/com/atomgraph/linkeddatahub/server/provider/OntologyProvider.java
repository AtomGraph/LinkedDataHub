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
package com.atomgraph.linkeddatahub.server.provider;

import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.model.Service;
import com.sun.jersey.core.spi.component.ComponentContext;
import com.sun.jersey.core.spi.component.ComponentScope;
import com.sun.jersey.spi.inject.Injectable;
import com.sun.jersey.spi.inject.InjectableProvider;
import java.lang.reflect.Type;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.Request;
import javax.ws.rs.ext.ContextResolver;
import javax.ws.rs.ext.Provider;
import javax.ws.rs.ext.Providers;
import org.apache.jena.ontology.OntModelSpec;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.query.ParameterizedSparqlString;
import org.apache.jena.query.Query;
import org.apache.jena.query.QuerySolutionMap;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.vocabulary.RDFS;

/**
 * JAX-RS provider of application ontology .
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Provider
public class OntologyProvider extends OntologyLoader implements InjectableProvider<Context, Type>, ContextResolver<Ontology>
{

    @Context Request request;
    @Context Providers providers;
    
    private final Query query;
    
    public OntologyProvider(OntModelSpec ontModelSpec, Query query)
    {
        super(ontModelSpec);
        this.query = query;
    }

    public Injectable<Ontology> getInjectable(ComponentContext cc, Context context)
    {
        return new Injectable<Ontology>()
        {
            @Override
            public Ontology getValue()
            {
                return getOntology();
            }
        };
    }

    @Override
    public Ontology getContext(Class<?> type)
    {
        return getOntology();
    }
    
    public Ontology getOntology()
    {
        Application app = getApplication();
        if (app == null) return null; // throw exception instead?
        
        return getOntology(app);
    }
    
    @Override
    public Model getModel(Service service, String ontologyURI)
    {
        QuerySolutionMap qsm = new QuerySolutionMap();
        qsm.add(RDFS.isDefinedBy.getLocalName(), ResourceFactory.createResource(ontologyURI));
                
        return service.getSPARQLClient().loadModel(new ParameterizedSparqlString(getQuery().toString(), qsm).asQuery());
    }
    
    public Query getQuery()
    {
        return query;
    }
    
    public Application getApplication()
    {
        return getProviders().getContextResolver(Application.class, null).getContext(Application.class);
    }
    
    public MediaTypes getMediaTypes()
    {
        return getProviders().getContextResolver(MediaTypes.class, null).getContext(MediaTypes.class);
    }
    
    public Request getRequest()
    {
        return request;
    }
    
    public Providers getProviders()
    {
        return providers;
    }

    @Override
    public ComponentScope getScope()
    {
        return ComponentScope.PerRequest;
    }

    @Override
    public Injectable getInjectable(ComponentContext ic, Context a, Type c)
    {
        if (c.equals(Ontology.class)) return getInjectable(ic, a);

        return null;
    }
    
}
