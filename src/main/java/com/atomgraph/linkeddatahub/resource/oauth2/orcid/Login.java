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
package com.atomgraph.linkeddatahub.resource.oauth2.orcid;

import com.atomgraph.linkeddatahub.resource.oauth2.LoginBase;
import com.atomgraph.linkeddatahub.vocabulary.ORCID;
import com.auth0.jwt.interfaces.DecodedJWT;
import java.net.URI;
import java.util.HashMap;
import java.util.Map;
import jakarta.inject.Inject;
import jakarta.json.JsonObject;
import jakarta.servlet.ServletConfig;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS resource that handles ORCID OAuth2 login.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Path("oauth2/login/orcid")
public class Login extends LoginBase
{

    private static final Logger log = LoggerFactory.getLogger(Login.class);

    /** OAuth token endpoint URL */
    public static final URI TOKEN_ENDPOINT = URI.create("https://sandbox.orcid.org/oauth/token"); // URI.create("https://orcid.org/oauth/token");

    /** User info endpoint URL */
    public static final URI USER_INFO_ENDPOINT = URI.create("https://sandbox.orcid.org/oauth/userinfo"); // URI.create("https://orcid.org/oauth/userinfo");

    /**
     * Constructs endpoint.
     *
     * @param request current request
     * @param uriInfo URI information of the current request
     * @param httpHeaders HTTP headers
     * @param application current application
     * @param system system application
     * @param servletConfig servlet config
     */
    @Inject
    public Login(@Context Request request, @Context UriInfo uriInfo, @Context HttpHeaders httpHeaders,
            com.atomgraph.linkeddatahub.apps.model.Application application,
            com.atomgraph.linkeddatahub.Application system, @Context ServletConfig servletConfig)
    {
        super(request, uriInfo, httpHeaders, application, system, servletConfig,
            (String)system.getProperty(ORCID.clientID.getURI()), (String)system.getProperty(ORCID.clientSecret.getURI()));
    }

    /**
     * Returns ORCID's OAuth token endpoint URL.
     *
     * @return ORCID token endpoint URI
     */
    @Override
    public URI getTokenEndpoint()
    {
        return TOKEN_ENDPOINT;
    }

    /**
     * Retrieves user information from ORCID UserInfo endpoint.
     * ORCID requires a separate API call to the UserInfo endpoint to get user details,
     * as they are not included in the ID token JWT claims.
     *
     * @param jwt the decoded JWT ID token (not used for user info retrieval)
     * @param accessToken the OAuth access token used to authenticate the UserInfo endpoint call
     * @return map of user information from the UserInfo endpoint (email, name, given_name, family_name)
     */
    @Override
    protected Map<String, String> getUserInfo(DecodedJWT jwt, String accessToken)
    {
        // ORCID requires a separate UserInfo endpoint call to get user details
        try (Response userInfoResponse = getSystem().getClient().target(USER_INFO_ENDPOINT).
                request().
                header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken).
                get())
        {
            JsonObject json = userInfoResponse.readEntity(JsonObject.class);
            Map<String, String> userInfo = new HashMap<>();
            json.forEach((key, value) -> userInfo.put(key, json.getString(key)));

            return userInfo;
        }
    }

}
