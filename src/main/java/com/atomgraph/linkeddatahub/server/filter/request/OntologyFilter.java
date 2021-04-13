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
package com.atomgraph.linkeddatahub.server.filter.request;

import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.server.util.SPARQLClientOntologyLoader;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import java.io.IOException;
import java.util.Optional;
import javax.annotation.Priority;
import javax.inject.Inject;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.ContainerRequestFilter;
import javax.ws.rs.container.PreMatching;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.vocabulary.OWL;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@PreMatching
@Priority(800)
public class OntologyFilter extends SPARQLClientOntologyLoader implements ContainerRequestFilter
{
    
    @Inject
    public OntologyFilter(com.atomgraph.linkeddatahub.Application system)
    {
        super(system.getOntModelSpec(), system.getSitemapQuery());
    }
    
    @Override
    public void filter(ContainerRequestContext crc) throws IOException
    {
        crc.setProperty(OWL.Ontology.getURI(), getOntology(crc));
    }
    
    public Optional<Ontology> getOntology(ContainerRequestContext crc)
    {
        Optional<Application> app = getApplication(crc);
        if (app.isEmpty()) return Optional.empty();
        
        return Optional.of(getOntology(app.get()));
    }
    
    public Optional<Application> getApplication(ContainerRequestContext crc)
    {
        return (Optional<Application>)crc.getProperty(LAPP.Application.getURI());
    }
    
}
