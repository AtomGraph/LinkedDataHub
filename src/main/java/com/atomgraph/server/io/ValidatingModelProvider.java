/*
 * Copyright 2015 Martynas Jusevičius <martynas@atomgraph.com>.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.atomgraph.server.io;

import org.apache.jena.ontology.Ontology;
import org.apache.jena.rdf.model.Model;
import java.io.IOException;
import java.io.InputStream;
import java.lang.annotation.Annotation;
import java.lang.reflect.Type;
import java.util.List;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.ext.Providers;
import com.atomgraph.server.exception.SPINConstraintViolationException;
import com.atomgraph.server.util.Validator;
import com.atomgraph.server.exception.SHACLConstraintViolationException;
import jakarta.inject.Inject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.atomgraph.spinrdf.constraints.ConstraintViolation;
import java.io.OutputStream;
import java.util.Optional;
import org.apache.jena.shacl.ShaclValidator;
import org.apache.jena.shacl.Shapes;
import org.apache.jena.shacl.ValidationReport;

/**
 * Model provider that validates read triples against SPIN constraints in an ontology.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ValidatingModelProvider extends BasedModelProvider
{
    private static final Logger log = LoggerFactory.getLogger(ValidatingModelProvider.class);
    
    @Context private Providers providers;
    
    @Inject jakarta.inject.Provider<Optional<Ontology>> ontology;

    @Override
    public Model readFrom(Class<Model> type, Type genericType, Annotation[] annotations, MediaType mediaType, MultivaluedMap<String, String> httpHeaders, InputStream entityStream) throws IOException
    {
        return processRead(super.readFrom(type, genericType, annotations, mediaType, httpHeaders, entityStream));
    }

    public Model processRead(Model model)
    {
        return validate(model);
    }
    
    public Model validate(Model model)
    {
        if (getOntology().isPresent())
        {
            // SPIN validation
            List<ConstraintViolation> cvs = new Validator(getOntology().get().getOntModel()).validate(model);
            if (!cvs.isEmpty())
            {
                if (log.isDebugEnabled()) log.debug("SPIN constraint violations: {}", cvs);
                throw new SPINConstraintViolationException(cvs, model);
            }

            // SHACL validation
            Shapes shapes = Shapes.parse(getOntology().get().getOntModel().getGraph());
            ValidationReport report = ShaclValidator.get().validate(shapes, model.getGraph());
            if (!report.conforms())
            {
                if (log.isDebugEnabled()) log.debug("SHACL constraint violations: {}", report);
                throw new SHACLConstraintViolationException(report, model);
            }
        }
    
        return model;
    }
        
    @Override
    public void writeTo(Model model, Class<?> type, Type genericType, Annotation[] annotations, MediaType mediaType, MultivaluedMap<String, Object> httpHeaders, OutputStream entityStream) throws IOException
    {
        super.writeTo(processWrite(model), type, genericType, annotations, mediaType, httpHeaders, entityStream);
    }
    
    public Model processWrite(Model model)
    {
        return model;
    }
    
    public Optional<Ontology> getOntology()
    {
        return ontology.get();
    }

    public Providers getProviders()
    {
        return providers;
    }

}
