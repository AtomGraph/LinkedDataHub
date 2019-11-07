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

import java.security.Principal;
import javax.ws.rs.core.SecurityContext;
import com.atomgraph.linkeddatahub.model.UserAccount;
import com.atomgraph.processor.vocabulary.SIOC;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Security context for a user account.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see com.atomgraph.linkeddatahub.model.UserAccount
 */
public class UserAccountContext implements SecurityContext
{
    private static final Logger log = LoggerFactory.getLogger(UserAccountContext.class);

    private final UserAccount account;
    private final String authScheme;
    
    public UserAccountContext(UserAccount account, String authScheme)
    {
	this.account = account;
        this.authScheme = authScheme;
    }

    public UserAccount getUserAccount()
    {
	return account;
    }
    
    @Override
    public Principal getUserPrincipal()
    {
	return getUserAccount();
    }

    // http://docs.oracle.com/javaee/5/tutorial/doc/bncbe.html
    // http://docs.oracle.com/javaee/6/tutorial/doc/gijrp.html
    // http://docs.oracle.com/javaee/6/tutorial/doc/gmmku.html
    @Override
    public boolean isUserInRole(String roleURI)
    {
	if (log.isDebugEnabled()) log.debug("Checking UserAccount: {} for role: {}", this, roleURI);
	return getUserAccount().hasProperty(SIOC.HAS_FUNCTION, getUserAccount().getModel().createResource(roleURI));
    }

    @Override
    public boolean isSecure()
    {
	return true;
    }

    @Override
    public String getAuthenticationScheme()
    {
	return authScheme;
    }

}
