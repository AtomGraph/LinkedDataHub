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
package com.atomgraph.linkeddatahub.client.filter.auth;

import java.io.IOException;
import javax.ws.rs.client.ClientRequestContext;
import javax.ws.rs.client.ClientRequestFilter;
import javax.ws.rs.core.Cookie;
import javax.ws.rs.core.HttpHeaders;
import com.atomgraph.linkeddatahub.server.filter.request.auth.IDTokenFilter;

/**
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class IDTokenDelegationFilter implements ClientRequestFilter
{

    private final String jwtToken;
    private final String path;
    private final String domain;
    
    public IDTokenDelegationFilter(String jwtToken, String path, String domain)
    {
        this.jwtToken = jwtToken;
        this.path = path;
        this.domain = domain;
    }

    @Override
    public void filter(ClientRequestContext cr) throws IOException
    {
        Cookie jwtCookie = new Cookie(IDTokenFilter.COOKIE_NAME, getJwtToken(), getPath(), getDomain());
        cr.getHeaders().add(HttpHeaders.COOKIE, jwtCookie.toString());
    }
    
    public String getJwtToken()
    {
        return jwtToken;
    }

    public String getPath()
    {
        return path;
    }

    public String getDomain()
    {
        return domain;
    }
    
}
