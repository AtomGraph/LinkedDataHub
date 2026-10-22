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
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import jakarta.ws.rs.ProcessingException;
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

    /** The only signature algorithm accepted: the one Google and ORCID sign their ID tokens with */
    public static final String ALGORITHM = "RS256";
    /** Minimum interval between fetches of the same JWKS endpoint triggered by an unknown key ID */
    public static final long JWKS_REFETCH_INTERVAL_MILLIS = 60_000L;
    /** Time of the last fetch per JWKS endpoint */
    private static final ConcurrentMap<String, Long> JWKS_FETCHED_AT = new ConcurrentHashMap<>();

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

            RSAPublicKey publicKey = getPublicKey(jwt, jwksEndpoint, client, jwksCache);
            if (publicKey == null) return false;

            // Create algorithm and verifier. JWT.require() also refuses a token whose header names another algorithm
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

    /**
     * Verifies that a JWT ID token was issued to this client by a trusted provider, without checking its expiry.
     * The header must name {@value #ALGORITHM}; the signature must verify against the provider's published key; the
     * issuer must be allowed and the audience must contain the client ID. An expired token that passes may be refreshed.
     *
     * @param jwt decoded JWT ID token to verify
     * @param jwksEndpoint JWKS endpoint URI
     * @param allowedIssuers list of allowed issuer URIs
     * @param clientID OAuth client ID
     * @param client JAX-RS client for HTTP requests
     * @param jwksCache optional cache for JWKS responses (key: jwksEndpoint.toString(), value: JsonObject)
     * @return true if the algorithm, signature, issuer and audience verify, false otherwise
     */
    public static boolean verifySignature(DecodedJWT jwt, URI jwksEndpoint, List<String> allowedIssuers, String clientID,
        Client client, Map<String, JsonObject> jwksCache)
    {
        try
        {
            if (!ALGORITHM.equals(jwt.getAlgorithm()))
            {
                if (log.isErrorEnabled()) log.error("JWT algorithm '{}' is not {}", jwt.getAlgorithm(), ALGORITHM);
                return false;
            }

            RSAPublicKey publicKey = getPublicKey(jwt, jwksEndpoint, client, jwksCache);
            if (publicKey == null) return false;

            // throws SignatureVerificationException if the signature does not verify
            com.auth0.jwt.algorithms.Algorithm.RSA256(publicKey, null).verify(jwt);

            if (!allowedIssuers.contains(jwt.getIssuer()))
            {
                if (log.isErrorEnabled()) log.error("JWT issuer '{}' not in allowed list: {}", jwt.getIssuer(), allowedIssuers);
                return false;
            }
            if (jwt.getAudience() == null || !jwt.getAudience().contains(clientID))
            {
                if (log.isErrorEnabled()) log.error("JWT audience {} does not contain the client ID", jwt.getAudience());
                return false;
            }

            return true;
        }
        catch (com.auth0.jwt.exceptions.JWTVerificationException ex)
        {
            if (log.isErrorEnabled()) log.error("JWT signature verification failed: {}", ex.getMessage());
            return false;
        }
        catch (IllegalArgumentException | NoSuchAlgorithmException | InvalidKeySpecException ex)
        {
            if (log.isErrorEnabled()) log.error("Error during JWT signature verification", ex);
            return false;
        }
    }

    /**
     * Fetches the JWKS from the provider and caches it.
     *
     * @param jwksEndpoint JWKS endpoint URI
     * @param client JAX-RS client for HTTP requests
     * @param jwksCache optional cache for JWKS responses
     * @return the JWKS, or null if it could not be fetched
     */
    private static JsonObject fetchJWKS(URI jwksEndpoint, Client client, Map<String, JsonObject> jwksCache)
    {
        JWKS_FETCHED_AT.put(jwksEndpoint.toString(), System.currentTimeMillis());

        try (Response jwksResponse = client.target(jwksEndpoint).request().get())
        {
            if (!jwksResponse.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
            {
                if (log.isErrorEnabled()) log.error("Failed to fetch JWKS from {}", jwksEndpoint);
                return null;
            }

            JsonObject jwks = jwksResponse.readEntity(JsonObject.class);
            if (jwksCache != null)
            {
                jwksCache.put(jwksEndpoint.toString(), jwks);
                if (log.isDebugEnabled()) log.debug("Cached JWKS for endpoint: {}", jwksEndpoint);
            }
            return jwks;
        }
        catch (ProcessingException ex)
        {
            if (log.isErrorEnabled()) log.error("Failed to fetch JWKS from {}", jwksEndpoint, ex);
            return null;
        }
    }

    /**
     * Returns true, and records the time, if the JWKS endpoint was last fetched at least
     * {@value #JWKS_REFETCH_INTERVAL_MILLIS} ms ago or never.
     *
     * @param jwksEndpoint JWKS endpoint URI
     * @return true if a re-fetch may go ahead
     */
    private static boolean isRefetchAllowed(URI jwksEndpoint)
    {
        long now = System.currentTimeMillis();
        boolean[] allowed = { false };
        JWKS_FETCHED_AT.compute(jwksEndpoint.toString(), (endpoint, fetchedAt) ->
        {
            if (fetchedAt != null && now - fetchedAt < JWKS_REFETCH_INTERVAL_MILLIS) return fetchedAt;
            allowed[0] = true;
            return now;
        });
        return allowed[0];
    }

    /**
     * Returns the key with the given ID from a JWKS.
     *
     * @param jwks JWKS
     * @param kid key ID
     * @return the key, or null if there is none
     */
    private static JsonObject findKey(JsonObject jwks, String kid)
    {
        JsonArray keys = jwks.getJsonArray("keys");
        if (keys == null)
        {
            if (log.isErrorEnabled()) log.error("JWKS does not contain 'keys' array");
            return null;
        }

        for (int i = 0; i < keys.size(); i++)
        {
            JsonObject key = keys.getJsonObject(i);
            if (kid.equals(key.getString("kid", null))) return key;
        }

        return null;
    }

    /**
     * Returns the provider's public key named by the JWT's <code>kid</code> header.
     * A <code>kid</code> missing from the cached JWKS re-fetches it, at most once per
     * {@value #JWKS_REFETCH_INTERVAL_MILLIS} ms per endpoint.
     *
     * @param jwt decoded JWT
     * @param jwksEndpoint JWKS endpoint URI
     * @param client JAX-RS client for HTTP requests
     * @param jwksCache optional cache for JWKS responses (key: jwksEndpoint.toString(), value: JsonObject)
     * @return RSA public key, or null if the JWKS cannot be read or holds no key with that ID
     * @throws NoSuchAlgorithmException if RSA is not supported
     * @throws InvalidKeySpecException if the key components are invalid
     */
    private static RSAPublicKey getPublicKey(DecodedJWT jwt, URI jwksEndpoint, Client client, Map<String, JsonObject> jwksCache)
        throws NoSuchAlgorithmException, InvalidKeySpecException
    {
        // Find the key that matches the JWT's key ID
        String kid = jwt.getKeyId();
        if (kid == null)
        {
            if (log.isErrorEnabled()) log.error("JWT does not contain 'kid' (key ID) header");
            return null;
        }

        // Get JWKS (from cache or fetch)
        JsonObject jwks = jwksCache != null ? jwksCache.get(jwksEndpoint.toString()) : null;
        boolean cached = jwks != null;
        if (!cached) jwks = fetchJWKS(jwksEndpoint, client, jwksCache);
        if (jwks == null) return null;

        JsonObject matchingKey = findKey(jwks, kid);

        // the provider may have rotated its keys since the JWKS was cached
        if (matchingKey == null && cached && isRefetchAllowed(jwksEndpoint))
        {
            if (log.isDebugEnabled()) log.debug("No key in cached JWKS for kid: {}, re-fetching {}", kid, jwksEndpoint);
            jwks = fetchJWKS(jwksEndpoint, client, jwksCache);
            if (jwks != null) matchingKey = findKey(jwks, kid);
        }

        if (matchingKey == null)
        {
            if (log.isErrorEnabled()) log.error("No matching key found in JWKS for kid: {}", kid);
            return null;
        }

        // Extract RSA public key components
        String n = matchingKey.getString("n"); // modulus
        String e = matchingKey.getString("e"); // exponent

        // Create RSA public key
        BigInteger modulus = new BigInteger(1, Base64.getUrlDecoder().decode(n));
        BigInteger exponent = new BigInteger(1, Base64.getUrlDecoder().decode(e));

        RSAPublicKeySpec spec = new RSAPublicKeySpec(modulus, exponent);
        KeyFactory factory = KeyFactory.getInstance("RSA");
        return (RSAPublicKey) factory.generatePublic(spec);
    }

}
