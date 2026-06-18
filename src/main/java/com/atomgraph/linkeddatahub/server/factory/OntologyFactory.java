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
package com.atomgraph.linkeddatahub.server.factory;

import java.util.Optional;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.ext.Provider;
import org.apache.jena.ontapi.model.OntModel;
import org.apache.jena.vocabulary.OWL;
import org.glassfish.hk2.api.Factory;
import org.glassfish.hk2.api.ServiceLocator;

/**
 * JAX-RS factory for application ontology.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Provider
public class OntologyFactory implements Factory<Optional<OntModel>>
{

    @Context private ServiceLocator serviceLocator;

    @Override
    public Optional<OntModel> provide()
    {
        return getOntology();
    }

    @Override
    public void dispose(Optional<OntModel> t)
    {
    }
    
    /**
     * Retrieves ontology from the request context.
     * 
     * @return ontology
     */
    public Optional<OntModel> getOntology()
    {
        return (Optional<OntModel>)getContainerRequestContext().getProperty(OWL.Ontology.getURI());
    }
    
    /**
     * Returns the container request context.
     * 
     * @return request context
     */
    public ContainerRequestContext getContainerRequestContext()
    {
        return serviceLocator.getService(ContainerRequestContext.class);
    }
    
}
