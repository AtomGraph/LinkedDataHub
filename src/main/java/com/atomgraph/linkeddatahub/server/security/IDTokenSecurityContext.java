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
package com.atomgraph.linkeddatahub.server.security;

import com.atomgraph.linkeddatahub.model.auth.Agent;

/**
 * Security context that carries the OAuth ID token.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class IDTokenSecurityContext extends AgentSecurityContext
{

    private final String jwtToken;
    
    /**
     * Constructs security context from user account and ID token.
     * 
     * @param authScheme authentication scheme ID
     * @param account user account resource
     * @param jwtToken JWT token content
     */
    public IDTokenSecurityContext(String authScheme, Agent account, String jwtToken)
    {
        super(authScheme, account);
        this.jwtToken = jwtToken;
    }
    
    /**
     * Returns JWT ID token content.
     * 
     * @return ID token content
     */
    public String getJWTToken()
    {
        return jwtToken;
    }
    
}