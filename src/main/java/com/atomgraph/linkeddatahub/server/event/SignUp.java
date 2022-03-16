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
package com.atomgraph.linkeddatahub.server.event;

import java.net.URI;

/**
 * Event that signals a successful WebID signup.
 * Can be subscribed to by an event listener.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class SignUp
{
    
    private final URI secretaryWebID;
    
    /**
     * Constructs signup event.
     * 
     * @param secretaryWebID URI of the secretary agent
     */
    public SignUp(URI secretaryWebID)
    {
        this.secretaryWebID = secretaryWebID;
    }
    
    /**
     * Returns the application's secretary agent's URI.
     * 
     * @return secretary URI
     */
    public URI getSecretaryWebID()
    {
        return secretaryWebID;
    }
    
}
