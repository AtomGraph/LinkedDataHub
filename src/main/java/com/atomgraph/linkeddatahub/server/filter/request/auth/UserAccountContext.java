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
package com.atomgraph.linkeddatahub.server.filter.request.auth;

import com.atomgraph.linkeddatahub.model.Agent;
import com.atomgraph.linkeddatahub.model.UserAccount;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Security context for a user account.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see com.atomgraph.linkeddatahub.model.UserAccount
 */
public class UserAccountContext extends AgentContext
{
    private static final Logger log = LoggerFactory.getLogger(UserAccountContext.class);

    private final UserAccount account;
    
    public UserAccountContext(String authScheme, Agent agent, UserAccount account)
    {
        super(authScheme, agent);
        this.account = account;
    }

    public UserAccount getUserAccount()
    {
        return account;
    }

}
