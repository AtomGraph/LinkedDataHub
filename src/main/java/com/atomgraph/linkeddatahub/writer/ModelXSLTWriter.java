/*
 * Copyright 2020 Martynas Jusevičius <martynas@atomgraph.com>.
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
package com.atomgraph.linkeddatahub.writer;

import com.atomgraph.client.util.DataManager;
import java.lang.annotation.Annotation;
import java.lang.reflect.Type;
import java.security.MessageDigest;
import javax.inject.Singleton;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.ext.MessageBodyWriter;
import javax.ws.rs.ext.Provider;
import net.sf.saxon.s9api.XsltExecutable;
import org.apache.jena.ontology.OntModelSpec;
import org.apache.jena.rdf.model.Model;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Provider
@Singleton
@Produces({MediaType.TEXT_HTML + ";charset=UTF-8", MediaType.APPLICATION_XHTML_XML + ";charset=UTF-8"})
public class ModelXSLTWriter extends ModelXSLTWriterBase implements MessageBodyWriter<Model>
{

    public ModelXSLTWriter(XsltExecutable xsltExec, OntModelSpec ontModelSpec, DataManager dataManager, MessageDigest messageDigest)
    {
        super(xsltExec, ontModelSpec, dataManager, messageDigest);
    }

    @Override
    public boolean isWriteable(Class<?> type, Type genericType, Annotation[] annotations, MediaType mediaType)
    {
        return Model.class.isAssignableFrom(type);
    }
    
}
