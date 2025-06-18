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
package com.atomgraph.linkeddatahub.server.interceptor;

import com.atomgraph.core.MediaType;
import com.atomgraph.core.riot.lang.TokenizerRDFPost;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.StringWriter;
import java.nio.charset.StandardCharsets;
import jakarta.annotation.Priority;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.ext.ReaderInterceptor;
import jakarta.ws.rs.ext.ReaderInterceptorContext;
import org.apache.commons.io.IOUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Request interceptor that fixes RDF/POST media type.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Priority(Priorities.ENTITY_CODER)
public class RDFPostMediaTypeInterceptor implements ReaderInterceptor
{

    private static final Logger log = LoggerFactory.getLogger(RDFPostMediaTypeInterceptor.class);

    @Override
    public Object aroundReadFrom(ReaderInterceptorContext context) throws IOException, WebApplicationException
    {
        // cannot use the RDF/POST-specific MediaType.APPLICATION_RDF_URLENCODED_TYPE because browsers do not support it as form/@enctype: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/form#attr-enctype -->
        if (context.getMediaType() != null && context.getMediaType().isCompatible(MediaType.APPLICATION_FORM_URLENCODED_TYPE))
        {
            StringWriter writer = new StringWriter();
            IOUtils.copy(context.getInputStream(), writer, StandardCharsets.UTF_8);
            
            String formData = writer.toString();
            
            if (formData.startsWith(TokenizerRDFPost.RDF))
                // replace the generic "application/x-www-form-urlencoded" media type with RDF/POST
                context.setMediaType(MediaType.APPLICATION_RDF_URLENCODED_TYPE);
            
            context.setInputStream(new ByteArrayInputStream(formData.getBytes(StandardCharsets.UTF_8))); // restore the request entity
        }
        
        return context.proceed();
    }
    
}
