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
package com.atomgraph.linkeddatahub.model.dydra.impl;

import com.sun.jersey.api.client.ClientHandlerException;
import com.sun.jersey.api.client.ClientRequest;
import com.sun.jersey.api.client.ClientResponse;
import com.sun.jersey.api.client.filter.ClientFilter;
import java.net.URI;
import javax.ws.rs.core.UriBuilder;

/**
 *
 * @author Martynas Jusevičius <martynas@atomgraph.com>
 */
public class AuthTokenFilter extends ClientFilter
{

    static final String AUTH_TOKEN_PARAM_NAME = "auth_token";

    private final String token;
    
    public AuthTokenFilter(String token)
    {
        this.token = token;
    
    }
    
    @Override
    public ClientResponse handle(ClientRequest cr) throws ClientHandlerException
    {
        URI withToken = UriBuilder.fromUri(cr.getURI()).queryParam(AUTH_TOKEN_PARAM_NAME, getToken()).build();
        cr.setURI(withToken);
        
        return getNext().handle(cr);
    }
    
    public String getToken()
    {
        return token;
    }
    
}
