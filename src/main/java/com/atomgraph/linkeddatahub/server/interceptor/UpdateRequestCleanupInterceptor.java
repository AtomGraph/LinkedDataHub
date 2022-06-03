/**
 *  Copyright 2022 Martynas Jusevičius <martynas@atomgraph.com>
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
import java.io.IOException;
import java.io.StringWriter;
import java.nio.charset.StandardCharsets;
import javax.annotation.Priority;
import javax.ws.rs.Priorities;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.ext.ReaderInterceptor;
import javax.ws.rs.ext.ReaderInterceptorContext;
import org.apache.commons.io.IOUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Request interceptor that fixes XHTML content in SPARQL update payload.
  * <code>rdf:XMLLiteral</code> needs to be canonical XML, therefore we wrap the original XHTML into
 * a <code>&lt;div&gt;</code> element and canonicalize the document.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
@Priority(Priorities.ENTITY_CODER + 10)
public class UpdateRequestCleanupInterceptor implements ReaderInterceptor
{

    private static final Logger log = LoggerFactory.getLogger(UpdateRequestCleanupInterceptor.class);

    @Override
    public Object aroundReadFrom(ReaderInterceptorContext context) throws IOException, WebApplicationException
    {
        if (context.getMediaType() != null && context.getMediaType().isCompatible(MediaType.APPLICATION_SPARQL_UPDATE_TYPE)) // so far this only happens in PATCH requests
        {
            StringWriter writer = new StringWriter();
            IOUtils.copy(context.getInputStream(), writer, StandardCharsets.UTF_8);

            String updateString = writer.toString();
            if (updateString.contains("XMLLiteral")) log.debug("XMLLiteral in SPARQL update");
        }
        
        return context.proceed();
    }

}
