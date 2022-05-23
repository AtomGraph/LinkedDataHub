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
package com.atomgraph.linkeddatahub.client.filter;

import java.io.IOException;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.client.ClientRequestContext;
import javax.ws.rs.client.ClientRequestFilter;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.ext.ReaderInterceptor;
import javax.ws.rs.ext.ReaderInterceptorContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class YouTubeReaderInterceptor implements ClientRequestFilter, ReaderInterceptor
{

    private static final Logger log = LoggerFactory.getLogger(YouTubeReaderInterceptor.class);

    public static String HOST = "youtube.googleapis.com";

    @Override
    public void filter(ClientRequestContext crc) throws IOException
    {
    }

    @Override
    public Object aroundReadFrom(ReaderInterceptorContext context) throws IOException, WebApplicationException
    {
        if (context.getHeaders().getFirst(HttpHeaders.HOST) != null && context.getHeaders().getFirst(HttpHeaders.HOST).equals(HOST) &&
            context.getMediaType().isCompatible(MediaType.APPLICATION_JSON_TYPE))
        {
            log.debug("YOUTUBE!");
        }
        
        return context.proceed();
    }

}
