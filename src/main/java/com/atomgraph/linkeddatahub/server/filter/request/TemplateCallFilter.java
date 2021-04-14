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

import com.atomgraph.processor.model.Template;
import com.atomgraph.processor.model.TemplateCall;
import com.atomgraph.processor.model.impl.TemplateCallImpl;
import com.atomgraph.processor.util.TemplateMatcher;
import com.atomgraph.processor.vocabulary.LDT;
import java.io.IOException;
import java.net.URI;
import java.util.Optional;
import javax.annotation.Priority;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.ContainerRequestFilter;
import javax.ws.rs.container.PreMatching;
import javax.ws.rs.core.MultivaluedMap;
import javax.ws.rs.core.UriInfo;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.vocabulary.OWL;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@PreMatching
@Priority(900)
public class TemplateCallFilter implements ContainerRequestFilter
{

    @Override
    public void filter(ContainerRequestContext crc) throws IOException
    {
        crc.setProperty(LDT.TemplateCall.getURI(), getTemplateCall(crc));
    }
    
    public Optional<TemplateCall> getTemplateCall(ContainerRequestContext crc)
    {
        Template template = getTemplate(crc);
        if (template != null) return getTemplateCall(template, crc.getUriInfo().getAbsolutePath(), crc.getUriInfo().getQueryParameters());
        
        return Optional.empty();
    }
    
    public Optional<TemplateCall> getTemplateCall(Template template, URI absolutePath, MultivaluedMap<String, String> queryParams)
    {
        if (template == null) throw new IllegalArgumentException("Template cannot be null");
        if (absolutePath == null) throw new IllegalArgumentException("URI cannot be null");
        if (queryParams == null) throw new IllegalArgumentException("MultivaluedMap cannot be null");

        //if (log.isDebugEnabled()) log.debug("Building Optional<TemplateCall> from Template {}", template);
        TemplateCall templateCall = new TemplateCallImpl(ModelFactory.createDefaultModel().createResource(absolutePath.toString()), template).
            applyArguments(queryParams). // apply URL query parameters
            applyDefaults().
            validateOptionals(); // validate (non-)optional arguments
        templateCall.build(); // build state URI
        
        return Optional.of(templateCall);
    }

    public Template getTemplate(ContainerRequestContext crc)
    {
        if (getOntology(crc) != null) return getTemplate(getOntology(crc), crc.getUriInfo());
        
        return null;
    }

    public Template getTemplate(Ontology ontology, UriInfo uriInfo)
    {
        return new TemplateMatcher(ontology).match(uriInfo.getAbsolutePath(), uriInfo.getBaseUri());
    }
    
    public Ontology getOntology(ContainerRequestContext crc)
    {
        //return (Ontology)crc.getProperty(OWL.Ontology.getURI());
        return (Ontology)crc.getProperty("OptionalOntology");
    }
    
}
