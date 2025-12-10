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
package com.atomgraph.linkeddatahub.server.filter.request.auth.google;

import com.atomgraph.linkeddatahub.resource.oauth2.google.Authorize;
import com.atomgraph.linkeddatahub.resource.oauth2.google.Login;
import static com.atomgraph.linkeddatahub.resource.oauth2.google.Login.TOKEN_ENDPOINT;
import com.atomgraph.linkeddatahub.server.filter.request.auth.IDTokenFilterBase;
import com.atomgraph.linkeddatahub.vocabulary.Google;
import com.auth0.jwt.interfaces.DecodedJWT;
import java.net.URI;
import java.util.Arrays;
import java.util.List;
import jakarta.annotation.Priority;
import jakarta.json.JsonObject;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.container.PreMatching;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Google-specific authentication filter that matches OIDC JWT tokens against application's user accounts.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@PreMatching
@Priority(Priorities.USER + 10) // has to execute after WebIDFilter
public class IDTokenFilter extends IDTokenFilterBase
{
    private static final Logger log = LoggerFactory.getLogger(IDTokenFilter.class);

    /** White-list of OIDC issuers */
    private static final List<String> ISSUERS = Arrays.asList("https://accounts.google.com");

    @Override
    protected void initClientCredentials()
    {
        setClientID((String)getSystem().getProperty(Google.clientID.getURI()));
        setClientSecret((String)getSystem().getProperty(Google.clientSecret.getURI()));
    }

    @Override
    protected List<String> getIssuers()
    {
        return ISSUERS;
    }

    @Override
    protected boolean verify(DecodedJWT idToken)
    {
        // TO-DO: use keys, this is for debugging purposes only: https://developers.google.com/identity/protocols/oauth2/openid-connect#validatinganidtoken
        try (Response cr = getSystem().getNoCertClient().
            target("https://oauth2.googleapis.com/tokeninfo").
            queryParam("id_token", idToken.getToken()).
            request(MediaType.APPLICATION_JSON_TYPE).
            get())
        {
            if (!cr.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
            {
                if (log.isDebugEnabled()) log.debug("Could not verify JWT token for subject '{}'", idToken.getSubject());
                return false;
            }

            JsonObject verifiedIdToken = cr.readEntity(JsonObject.class);
            if (idToken.getIssuer().equals(verifiedIdToken.getString("iss")) &&
                idToken.getSubject().equals(verifiedIdToken.getString("sub")) &&
                idToken.getKeyId().equals(verifiedIdToken.getString("kid")))
                return true;
        }

        return false;
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
