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
package com.atomgraph.linkeddatahub.client.grddl;

import com.atomgraph.core.io.ModelProvider;
import java.io.InputStream;
import java.lang.annotation.Annotation;
import java.lang.reflect.Type;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.ext.Provider;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.riot.Lang;

/**
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
@Provider
public class YoutubeModelReader extends ModelProvider
{

    public static String HOST = "youtube.googleapis.com";
    
    @Context HttpHeaders httpHeaders;
    
    @Override
    public boolean isWriteable(Class<?> type, Type genericType, Annotation[] annotations, MediaType mediaType)
    {
        return false;
    }

    @Override
    public boolean isReadable(Class<?> type, Type genericType, Annotation[] annotations, MediaType mediaType)
    {
        return getHttpHeaders().getHeaderString(HttpHeaders.HOST).equals(HOST) && mediaType.isCompatible(MediaType.APPLICATION_JSON_TYPE);
    }

    @Override
    public Model read(Model model, InputStream is, Lang lang, String baseURI)
    {
        return super.read(model, is, lang, baseURI);
    }

    public HttpHeaders getHttpHeaders()
    {
        return httpHeaders;
    }
    
}
