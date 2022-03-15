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

/**
 * WebID URI exception.
 * Thrown when the WebID is not a valid URI.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class InvalidWebIDURIException extends RuntimeException
{
    
    private final String uri;
    
    /**
     * Constructs exception from WebID URI.
     * 
     * @param uri WebID URI
     */
    public InvalidWebIDURIException(String uri)
    {
        super("Could not parse WebID URI: '" + uri + "'");
        this.uri = uri;
    }
    
    /**
     * Returns WebID URI.
     * 
     * @return WebID URI
     */
    public String getURI()
    {
        return uri;
    }
    
}
