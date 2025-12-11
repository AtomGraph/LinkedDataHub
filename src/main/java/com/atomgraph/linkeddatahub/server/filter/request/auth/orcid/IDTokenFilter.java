/**
 *  Copyright 2025 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.server.filter.request.auth.orcid;

import com.atomgraph.linkeddatahub.resource.oauth2.orcid.Authorize;
import com.atomgraph.linkeddatahub.resource.oauth2.orcid.Login;
import static com.atomgraph.linkeddatahub.resource.oauth2.orcid.Login.TOKEN_ENDPOINT;
import com.atomgraph.linkeddatahub.server.filter.request.auth.IDTokenFilterBase;
import com.atomgraph.linkeddatahub.vocabulary.ORCID;
import java.net.URI;
import java.util.Arrays;
import java.util.List;
import jakarta.annotation.Priority;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.container.PreMatching;
import jakarta.ws.rs.core.UriBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * ORCID-specific authentication filter that matches OIDC JWT tokens against application's user accounts.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@PreMatching
@Priority(Priorities.USER + 10) // has to execute after WebIDFilter
public class IDTokenFilter extends IDTokenFilterBase
{
    private static final Logger log = LoggerFactory.getLogger(IDTokenFilter.class);

    /** White-list of OIDC issuers (supports both production and sandbox) */
    private static final List<String> ISSUERS = Arrays.asList("https://orcid.org", "https://sandbox.orcid.org");

    @Override
    protected void initClientCredentials()
    {
        setClientID((String)getSystem().getProperty(ORCID.clientID.getURI()));
        setClientSecret((String)getSystem().getProperty(ORCID.clientSecret.getURI()));
    }

    @Override
    protected List<String> getIssuers()
    {
        return ISSUERS;
    }

    @Override
    protected URI getJWKSEndpoint()
    {
        return Login.JWKS_ENDPOINT;
    }

    @Override
    protected URI getTokenEndpoint()
    {
        return TOKEN_ENDPOINT;
    }

    @Override
    protected URI getLoginURL()
    {
        return UriBuilder.fromUri(getContextURI()).path(Login.class).build();
    }

    @Override
    protected URI getAuthorizeURL()
    {
        return UriBuilder.fromUri(getContextURI()).path(Authorize.class).build();
    }

}
