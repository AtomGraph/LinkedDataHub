// Copyright 2019 Martynas Jusevičius <martynas@atomgraph.com>
// SPDX-FileCopyrightText: 2017-2022 2017 Martynas Jusevicius, <martynas@atomgraph.com> et al.
//
// SPDX-License-Identifier: Apache-2.0


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

import org.apache.jena.rdf.model.Resource;

/**
 * WebID delegation exception.
 * Thrown if it cannot be verified that an agent delegates a principal agent.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class WebIDDelegationException extends RuntimeException
{
    
    /**
     * Constructs exception.
     * 
     * @param agent delegating agent resource
     * @param principal delegated agent resource
     */
    public WebIDDelegationException(Resource agent, Resource principal)
    {
        super("Agent '" + agent.getURI() + "' does not delegate (acl:delegates) the agent '" + principal.getURI() + "'");
    }
    
}
