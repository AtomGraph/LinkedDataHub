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
package com.atomgraph.linkeddatahub.server.exception.auth;

import com.atomgraph.linkeddatahub.model.auth.Agent;
import org.apache.jena.rdf.model.Resource;
import java.net.URI;

/**
 * Authorization exception.
 * Thrown when request authorization fails.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class AuthorizationException extends RuntimeException
{
    
    /** URL of the current request (without the query string) */
    private final URI absolutePath;
    /** Access mode resource */
    private final Resource mode;
    /** Authenticated agent resource */
    private final Resource agent;

    /**
     * Constructs exception with agent.
     * 
     * @param message exception message
     * @param absolutePath request URL without query string
     * @param mode ACL access mode
     * @param agent authenticated agent
     */
    public AuthorizationException(String message, URI absolutePath, Resource mode, Agent agent)
    {
        super(message);
    
        if (absolutePath == null) throw new IllegalArgumentException("Request URI cannot be null");
        if (mode == null) throw new IllegalArgumentException("Request mode Resource cannot be null");
        this.absolutePath = absolutePath;
        this.mode = mode;
        this.agent = agent;
    }

    /**
     * Constructs exception without agent.
     *
     * @param message exception message
     * @param absolutePath request URL without query string
     * @param mode ACL access mode
     */
    public AuthorizationException(String message, URI absolutePath, Resource mode)
    {
        this(message, absolutePath, mode, null);
    }
    
    /**
     * Returns request URL without query string.
     * 
     * @return absolute path
     */
    public URI getAbsolutePath()
    {
        return absolutePath;
    }

    /**
     * Returns ACL access mode.
     * 
     * @return access mode resource
     */
    public Resource getMode()
    {
        return mode;
    }

    /**
     * Returns authenticated agent.
     * 
     * @return agent resource or null
     */
    public Resource getAgent()
    {
        return agent;
    }
    
}