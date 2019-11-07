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
package com.atomgraph.linkeddatahub.server.model.impl;

import java.util.List;
import java.util.Locale;
import java.util.Map;
import javax.ws.rs.core.Cookie;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.MultivaluedMap;

/**
 * A client-side implementation of an HTTP header map.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see HttpHeaders
 */
public class ClientHttpHeaders implements HttpHeaders
{

    private final MultivaluedMap<String, String> headers;

    public ClientHttpHeaders(MultivaluedMap<String, String> headers)
    {
        this.headers = headers;
    }
    
    @Override
    public List<String> getRequestHeader(String name)
    {
        return headers.get(name);
    }

    @Override
    public MultivaluedMap<String, String> getRequestHeaders()
    {
        return headers;
    }

    @Override
    public List<MediaType> getAcceptableMediaTypes()
    {
        throw new UnsupportedOperationException();
    }

    @Override
    public List<Locale> getAcceptableLanguages()
    {
        throw new UnsupportedOperationException();
    }

    @Override
    public MediaType getMediaType()
    {
        throw new UnsupportedOperationException();
    }

    @Override
    public Locale getLanguage()
    {
        throw new UnsupportedOperationException();
    }

    @Override
    public Map<String, Cookie> getCookies()
    {
        throw new UnsupportedOperationException();
    }
    
}
