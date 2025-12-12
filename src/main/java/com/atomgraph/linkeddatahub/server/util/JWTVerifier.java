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
package com.atomgraph.linkeddatahub.server.util;

import com.auth0.jwt.JWT;
import com.auth0.jwt.interfaces.DecodedJWT;
import jakarta.json.JsonArray;
import jakarta.json.JsonObject;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.core.Response;
import java.math.BigInteger;
import java.net.URI;
import java.security.KeyFactory;
import java.security.NoSuchAlgorithmException;
import java.security.interfaces.RSAPublicKey;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.RSAPublicKeySpec;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Utility class for verifying JWT ID tokens using JWKS (JSON Web Key Set).
 * Provides JWKS-based signature verification for OAuth 2.0 / OpenID Connect ID tokens.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class JWTVerifier
{
    private static final Logger log = LoggerFactory.getLogger(JWTVerifier.class);

    /**
     * Verifies a JWT ID token using JWKS-based signature verification.
     * Performs the following validations:
     * 1. Fetches public keys from the JWKS endpoint (or uses cached JWKS)
     * 2. Verifies the JWT signature using RSA256 algorithm
     * 3. Validates the issuer is in the allowed list
     * 4. Validates the audience matches the client ID
     * 5. Validates the token has not expired
     *
     * @param jwt decoded JWT ID token to verify
     * @param jwksEndpoint JWKS endpoint URI
     * @param allowedIssuers list of allowed issuer URIs
     * @param clientID OAuth client ID
     * @param client JAX-RS client for HTTP requests
     * @param jwksCache optional cache for JWKS responses (key: jwksEndpoint.toString(), value: JsonObject)
     * @return true if verification succeeds, false otherwise
     */
    public static boolean verify(DecodedJWT jwt, URI jwksEndpoint, List<String> allowedIssuers, String clientID,
        Client client, Map<String, JsonObject> jwksCache)
    {
        try
        {
            // Verify issuer first (before fetching JWKS)
            if (!allowedIssuers.contains(jwt.getIssuer()))
            {
                if (log.isErrorEnabled()) log.error("JWT issuer '{}' not in allowed list: {}", jwt.getIssuer(), allowedIssuers);
                return false;
            }

            // Get JWKS (from cache or fetch)
            JsonObject jwks;
            String cacheKey = jwksEndpoint.toString();

            if (jwksCache != null && jwksCache.containsKey(cacheKey))
            {
                jwks = jwksCache.get(cacheKey);
                if (log.isDebugEnabled()) log.debug("Using cached JWKS for endpoint: {}", jwksEndpoint);
            }
            else
            {
                // Fetch JWKS from the provider
                try (Response jwksResponse = client.target(jwksEndpoint).request().get())
                {
                    if (!jwksResponse.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
                    {
                        if (log.isErrorEnabled()) log.error("Failed to fetch JWKS from {}", jwksEndpoint);
                        return false;
                    }

                    jwks = jwksResponse.readEntity(JsonObject.class);

                    // Cache the JWKS if cache is provided
                    if (jwksCache != null)
                    {
                        jwksCache.put(cacheKey, jwks);
                        if (log.isDebugEnabled()) log.debug("Cached JWKS for endpoint: {}", jwksEndpoint);
                    }
                }
            }

            // Find the key that matches the JWT's key ID
            String kid = jwt.getKeyId();
            if (kid == null)
            {
                if (log.isErrorEnabled()) log.error("JWT does not contain 'kid' (key ID) header");
                return false;
            }

            JsonArray keys = jwks.getJsonArray("keys");
            if (keys == null)
            {
                if (log.isErrorEnabled()) log.error("JWKS does not contain 'keys' array");
                return false;
            }

            // Find matching key
            JsonObject matchingKey = null;
            for (int i = 0; i < keys.size(); i++)
            {
                JsonObject key = keys.getJsonObject(i);
                if (kid.equals(key.getString("kid", null)))
                {
                    matchingKey = key;
                    break;
                }
            }

            if (matchingKey == null)
            {
                if (log.isErrorEnabled()) log.error("No matching key found in JWKS for kid: {}", kid);
                return false;
            }

            // Extract RSA public key components
            String n = matchingKey.getString("n"); // modulus
            String e = matchingKey.getString("e"); // exponent

            // Create RSA public key
            BigInteger modulus = new BigInteger(1, Base64.getUrlDecoder().decode(n));
            BigInteger exponent = new BigInteger(1, Base64.getUrlDecoder().decode(e));

            RSAPublicKeySpec spec = new RSAPublicKeySpec(modulus, exponent);
            KeyFactory factory = KeyFactory.getInstance("RSA");
            RSAPublicKey publicKey = (RSAPublicKey) factory.generatePublic(spec);

            // Create algorithm and verifier
            com.auth0.jwt.algorithms.Algorithm algorithm = com.auth0.jwt.algorithms.Algorithm.RSA256(publicKey, null);
            com.auth0.jwt.JWTVerifier verifier = JWT.require(algorithm).
                withIssuer(jwt.getIssuer()).
                withAudience(clientID).
                build();

            // Verify the token (this will throw if verification fails)
            verifier.verify(jwt.getToken());

            if (log.isDebugEnabled()) log.debug("Successfully verified JWT for subject '{}'", jwt.getSubject());
            return true;
        }
        catch (com.auth0.jwt.exceptions.JWTVerificationException ex)
        {
            if (log.isErrorEnabled()) log.error("JWT verification failed: {}", ex.getMessage());
            return false;
        }
        catch (IllegalArgumentException | NoSuchAlgorithmException | InvalidKeySpecException ex)
        {
            if (log.isErrorEnabled()) log.error("Error during JWT verification", ex);
            return false;
        }
    }

}
