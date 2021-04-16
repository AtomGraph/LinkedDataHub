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
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.core.Context;
import javax.ws.rs.ext.Provider;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.vocabulary.OWL;
import org.glassfish.hk2.api.Factory;
import org.glassfish.hk2.api.ServiceLocator;

/**
 * JAX-RS provider of application ontology .
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Provider
public class OntologyOptionalFactory implements Factory<Optional<Ontology>>
{

    @Context private ServiceLocator serviceLocator;

    @Override
    public Optional<Ontology> provide()
    {
        return getOntology(getContainerRequestContext());
    }

    @Override
    public void dispose(Optional<Ontology> t)
    {
    }
    
    public Optional<Ontology> getOntology(ContainerRequestContext crc)
    {
        return (Optional<Ontology>)crc.getProperty(OWL.Ontology.getURI());
    }
    
    public ContainerRequestContext getContainerRequestContext()
    {
        return serviceLocator.getService(ContainerRequestContext.class);
    }
    
}
