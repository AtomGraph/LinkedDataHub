/*
 * Copyright 2019 Martynas Jusevičius <martynas@atomgraph.com>.
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

import com.atomgraph.core.io.DatasetProvider;
import java.io.IOException;
import java.io.InputStream;
import java.lang.annotation.Annotation;
import java.lang.reflect.Type;
import java.util.Iterator;
import jakarta.inject.Inject;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.ext.Providers;
import org.apache.jena.ontapi.model.OntModel;
import org.apache.jena.query.Dataset;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.util.Optional;

/**
 * Dataset provider that validates read triples in each graph against SPIN constraints in an ontology.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ValidatingDatasetProvider extends DatasetProvider
{

    private static final Logger log = LoggerFactory.getLogger(ValidatingDatasetProvider.class);
    
    @Context private Providers providers;
    
    @Inject jakarta.inject.Provider<Optional<OntModel>> ontology;

    @Override
    public Dataset readFrom(Class<Dataset> type, Type genericType, Annotation[] annotations, MediaType mediaType, MultivaluedMap<String, String> httpHeaders, InputStream entityStream) throws IOException
    {
        return process(super.readFrom(type, genericType, annotations, mediaType, httpHeaders, entityStream));
    }

    public Dataset process(Dataset dataset)
    {
        return validate(dataset);
    }
    
    public Dataset validate(Dataset dataset)
    {
        if (getOntology().isPresent())
        {
            ValidatingModelProvider.checkConstraints(getOntology().get(), dataset.getDefaultModel(), null);

            Iterator<String> it = dataset.listNames();
            while (it.hasNext())
            {
                String graphURI = it.next();
                ValidatingModelProvider.checkConstraints(getOntology().get(), dataset.getNamedModel(graphURI), graphURI);
            }
        }
        
        return dataset;
    }
        
    public Optional<OntModel> getOntology()
    {
        return ontology.get();
    }

    public Providers getProviders()
    {
        return providers;
    }
    
}
