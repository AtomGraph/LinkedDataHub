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
package com.atomgraph.linkeddatahub.server.exception.auth.webid;

import java.net.URI;
import jakarta.ws.rs.core.Response;

/**
 * 
 * WebID loading exception.
 * Thrown if WebID URI cannot be successfully dereferenced to an RDF document.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class WebIDLoadingException extends RuntimeException
{
    
    /**
     * Constructs exception.
     * 
     * @param webID WebID URI
     * @param response client response
     */
    public WebIDLoadingException(URI webID, Response response)
    {
        super("WebID profile could not be loaded: " + webID);
    }
    
}
