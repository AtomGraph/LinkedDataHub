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
package com.atomgraph.linkeddatahub.resource.oauth2.google;

import com.atomgraph.linkeddatahub.resource.oauth2.LoginBase;
import com.atomgraph.linkeddatahub.vocabulary.Google;
import com.auth0.jwt.interfaces.DecodedJWT;
import java.net.URI;
import java.util.Map;
import jakarta.inject.Inject;
import jakarta.servlet.ServletConfig;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.UriInfo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS resource that handles OAuth2 login.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Path("oauth2/login/google")
public class Login extends LoginBase
{

    private static final Logger log = LoggerFactory.getLogger(Login.class);

    /** OAuth token endpoint URL */
    public static final URI TOKEN_ENDPOINT = URI.create("https://oauth2.googleapis.com/token");

    /** JWKS endpoint URL for JWT signature verification */
    public static final URI JWKS_ENDPOINT = URI.create("https://www.googleapis.com/oauth2/v3/certs");

    /** Valid Google issuers */
    private static final java.util.List<String> ISSUERS = java.util.Arrays.asList("https://accounts.google.com", "accounts.google.com");

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
            (String)system.getProperty(Google.clientID.getURI()), (String)system.getProperty(Google.clientSecret.getURI()));
    }

    /**
     * Returns Google's OAuth token endpoint URL.
     *
     * @return Google token endpoint URI
     */
    @Override
    public URI getTokenEndpoint()
    {
        return TOKEN_ENDPOINT;
    }

    /**
     * Returns Google's JWKS endpoint URL for fetching public keys.
     *
     * @return Google JWKS endpoint URI
     */
    @Override
    protected URI getJwksEndpoint()
    {
        return JWKS_ENDPOINT;
    }

    /**
     * Returns the list of valid Google issuers.
     *
     * @return list of valid issuer URLs
     */
    @Override
    protected java.util.List<String> getIssuers()
    {
        return ISSUERS;
    }

    /**
     * Retrieves user information from Google ID token JWT claims.
     * Google includes all user data (email, name, given_name, family_name, picture) directly in the ID token,
     * so no additional API call is needed.
     *
     * @param jwt the decoded JWT ID token
     * @param accessToken the OAuth access token (not used for Google)
     * @return map of user information claims
     */
    @Override
    protected Map<String, String> getUserInfo(DecodedJWT jwt, String accessToken)
    {
        // Google includes all user information in the ID token JWT claims
        return jwt.getClaims().entrySet().stream().
            filter(e -> e.getValue().asString() != null).
            collect(java.util.stream.Collectors.toMap(
                java.util.Map.Entry::getKey,
                e -> e.getValue().asString()
            ));
    }

}
