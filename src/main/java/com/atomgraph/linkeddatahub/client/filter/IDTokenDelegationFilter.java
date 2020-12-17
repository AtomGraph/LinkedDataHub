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
package com.atomgraph.linkeddatahub.client.filter;

import com.atomgraph.linkeddatahub.server.filter.request.authn.IDTokenFilter;
import java.io.IOException;
import javax.ws.rs.client.ClientRequestContext;
import javax.ws.rs.client.ClientRequestFilter;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.NewCookie;

/**
 *
 * @author Martynas Jusevičius <martynas@atomgraph.com>
 */
public class IDTokenDelegationFilter implements ClientRequestFilter
{
    
    private final String idToken;
    
    public IDTokenDelegationFilter(String idToken)
    {
        this.idToken = idToken;
    }

    @Override
    public void filter(ClientRequestContext cr) throws IOException
    {
        NewCookie jwtCookie = new NewCookie(IDTokenFilter.COOKIE_NAME, getIdToken(),
            "/", null,
            NewCookie.DEFAULT_VERSION, null, NewCookie.DEFAULT_MAX_AGE, false);
        
//        cr.getCookies().put(JWTFilter.COOKIE_NAME, jwtCookie); // read-only map -- cannot add
        cr.getHeaders().add(HttpHeaders.COOKIE, IDTokenFilter.COOKIE_NAME + "=" + jwtCookie.getValue());
    }
    
    public String getIdToken()
    {
        return idToken;
    }
    
}
