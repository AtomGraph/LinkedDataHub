/*
 * Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.atomgraph.linkeddatahub.server.util;

import com.auth0.jwt.JWT;
import com.auth0.jwt.JWTCreator;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.interfaces.DecodedJWT;
import jakarta.json.Json;
import jakarta.json.JsonObject;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.client.Invocation;
import jakarta.ws.rs.client.WebTarget;
import jakarta.ws.rs.core.Response;
import java.math.BigInteger;
import java.net.URI;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.NoSuchAlgorithmException;
import java.security.interfaces.RSAPrivateKey;
import java.security.interfaces.RSAPublicKey;
import java.time.Instant;
import java.util.Base64;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit tests for JWKS-based JWT verification.
 * The JWKS is supplied through the cache argument so verification runs offline (no HTTP client needed).
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class JWTVerifierTest
{

    private static final String ISSUER = "https://accounts.example.com";
    private static final String CLIENT_ID = "client-abc";
    private static final String KID = "test-key-1";
    private static final String SUBJECT = "user-123";
    private static final URI JWKS_ENDPOINT = URI.create("https://accounts.example.com/jwks");

    private static KeyPair keyPair; // published in the JWKS
    private static KeyPair otherKeyPair; // not published
    private static List<String> allowedIssuers;
    private static Map<String, JsonObject> jwksCache;

    @BeforeAll
    public static void init() throws NoSuchAlgorithmException
    {
        KeyPairGenerator generator = KeyPairGenerator.getInstance("RSA");
        generator.initialize(2048);
        keyPair = generator.generateKeyPair();
        otherKeyPair = generator.generateKeyPair();

        allowedIssuers = List.of(ISSUER);

        JsonObject jwk = Json.createObjectBuilder().
            add("kty", "RSA").
            add("use", "sig").
            add("alg", "RS256").
            add("kid", KID).
            add("n", base64Url(((RSAPublicKey) keyPair.getPublic()).getModulus())).
            add("e", base64Url(((RSAPublicKey) keyPair.getPublic()).getPublicExponent())).
            build();
        JsonObject jwks = Json.createObjectBuilder().add("keys", Json.createArrayBuilder().add(jwk)).build();

        jwksCache = new HashMap<>();
        jwksCache.put(JWKS_ENDPOINT.toString(), jwks);
    }

    @Test
    public void testValidTokenVerifies()
    {
        DecodedJWT jwt = JWT.decode(createToken(ISSUER, CLIENT_ID, KID, Instant.now().plusSeconds(300), keyPair));
        assertTrue(JWTVerifier.verify(jwt, JWKS_ENDPOINT, allowedIssuers, CLIENT_ID, null, jwksCache));
    }

    @Test
    public void testWrongIssuerRejected()
    {
        DecodedJWT jwt = JWT.decode(createToken("https://evil.example", CLIENT_ID, KID, Instant.now().plusSeconds(300), keyPair));
        assertFalse(JWTVerifier.verify(jwt, JWKS_ENDPOINT, allowedIssuers, CLIENT_ID, null, jwksCache));
    }

    @Test
    public void testWrongAudienceRejected()
    {
        DecodedJWT jwt = JWT.decode(createToken(ISSUER, "some-other-client", KID, Instant.now().plusSeconds(300), keyPair));
        assertFalse(JWTVerifier.verify(jwt, JWKS_ENDPOINT, allowedIssuers, CLIENT_ID, null, jwksCache));
    }

    @Test
    public void testExpiredTokenRejected()
    {
        DecodedJWT jwt = JWT.decode(createToken(ISSUER, CLIENT_ID, KID, Instant.now().minusSeconds(300), keyPair));
        assertFalse(JWTVerifier.verify(jwt, JWKS_ENDPOINT, allowedIssuers, CLIENT_ID, null, jwksCache));
    }

    @Test
    public void testMissingKeyIdRejected()
    {
        DecodedJWT jwt = JWT.decode(createToken(ISSUER, CLIENT_ID, null, Instant.now().plusSeconds(300), keyPair));
        assertFalse(JWTVerifier.verify(jwt, JWKS_ENDPOINT, allowedIssuers, CLIENT_ID, null, jwksCache));
    }

    @Test
    public void testBadSignatureRejected()
    {
        // token references the published kid but is signed with a different key
        DecodedJWT jwt = JWT.decode(createToken(ISSUER, CLIENT_ID, KID, Instant.now().plusSeconds(300), otherKeyPair));
        assertFalse(JWTVerifier.verify(jwt, JWKS_ENDPOINT, allowedIssuers, CLIENT_ID, null, jwksCache));
    }

    /** An expired token with a valid signature passes the signature check */
    @Test
    public void testSignatureOfExpiredTokenVerifies()
    {
        DecodedJWT jwt = JWT.decode(createToken(ISSUER, CLIENT_ID, KID, Instant.now().minusSeconds(3600), keyPair));
        assertTrue(JWTVerifier.verifySignature(jwt, JWKS_ENDPOINT, allowedIssuers, CLIENT_ID, null, jwksCache));
    }

    @Test
    public void testSignatureWithWrongKeyRejected()
    {
        DecodedJWT jwt = JWT.decode(createToken(ISSUER, CLIENT_ID, KID, Instant.now().minusSeconds(3600), otherKeyPair));
        assertFalse(JWTVerifier.verifySignature(jwt, JWKS_ENDPOINT, allowedIssuers, CLIENT_ID, null, jwksCache));
    }

    @Test
    public void testUnsignedTokenRejected()
    {
        DecodedJWT jwt = JWT.decode(createToken(ISSUER, CLIENT_ID, KID, Instant.now().minusSeconds(3600), Algorithm.none()));
        assertFalse(JWTVerifier.verifySignature(jwt, JWKS_ENDPOINT, allowedIssuers, CLIENT_ID, null, jwksCache));
        assertFalse(JWTVerifier.verify(jwt, JWKS_ENDPOINT, allowedIssuers, CLIENT_ID, null, jwksCache));
    }

    /** An HS256 token is rejected */
    @Test
    public void testHmacTokenRejected()
    {
        byte[] secret = ((RSAPublicKey) keyPair.getPublic()).getModulus().toByteArray();
        DecodedJWT jwt = JWT.decode(createToken(ISSUER, CLIENT_ID, KID, Instant.now().plusSeconds(300), Algorithm.HMAC256(secret)));
        assertFalse(JWTVerifier.verifySignature(jwt, JWKS_ENDPOINT, allowedIssuers, CLIENT_ID, null, jwksCache));
        assertFalse(JWTVerifier.verify(jwt, JWKS_ENDPOINT, allowedIssuers, CLIENT_ID, null, jwksCache));
    }

    @Test
    public void testSignatureWithWrongIssuerRejected()
    {
        DecodedJWT jwt = JWT.decode(createToken("https://evil.example", CLIENT_ID, KID, Instant.now().plusSeconds(300), keyPair));
        assertFalse(JWTVerifier.verifySignature(jwt, JWKS_ENDPOINT, allowedIssuers, CLIENT_ID, null, jwksCache));
    }

    @Test
    public void testSignatureWithWrongAudienceRejected()
    {
        DecodedJWT jwt = JWT.decode(createToken(ISSUER, "some-other-client", KID, Instant.now().plusSeconds(300), keyPair));
        assertFalse(JWTVerifier.verifySignature(jwt, JWKS_ENDPOINT, allowedIssuers, CLIENT_ID, null, jwksCache));
    }

    @Test
    public void testSignatureWithUnknownKeyIdRejected()
    {
        // the re-fetched JWKS does not have the key either
        URI endpoint = URI.create("https://accounts.example.com/jwks-unknown");
        Map<String, JsonObject> cache = new HashMap<>(Map.of(endpoint.toString(), jwks(KID, keyPair)));
        Client client = mockClient(jwks(KID, keyPair));

        DecodedJWT jwt = JWT.decode(createToken(ISSUER, CLIENT_ID, "unknown-key", Instant.now().plusSeconds(300), keyPair));
        assertFalse(JWTVerifier.verifySignature(jwt, endpoint, allowedIssuers, CLIENT_ID, client, cache));
    }

    /** A key ID missing from the cached JWKS re-fetches it, and the new key verifies */
    @Test
    public void testRotatedKeyRefetchesJWKS()
    {
        URI endpoint = URI.create("https://accounts.example.com/jwks-rotated");
        Map<String, JsonObject> cache = new HashMap<>(Map.of(endpoint.toString(), jwks(KID, keyPair)));
        JsonObject rotated = jwks("rotated-key", otherKeyPair);
        Client client = mockClient(rotated);

        DecodedJWT jwt = JWT.decode(createToken(ISSUER, CLIENT_ID, "rotated-key", Instant.now().plusSeconds(300), otherKeyPair));
        assertTrue(JWTVerifier.verifySignature(jwt, endpoint, allowedIssuers, CLIENT_ID, client, cache));
        assertTrue(JWTVerifier.verify(jwt, endpoint, allowedIssuers, CLIENT_ID, client, cache)); // now from the cache
        assertEquals(rotated, cache.get(endpoint.toString()));
        verify(client, times(1)).target(endpoint);
    }

    /** Unknown key IDs re-fetch the JWKS at most once per interval */
    @Test
    public void testJWKSRefetchRateLimited()
    {
        URI endpoint = URI.create("https://accounts.example.com/jwks-rate-limited");
        Map<String, JsonObject> cache = new HashMap<>(Map.of(endpoint.toString(), jwks(KID, keyPair)));
        Client client = mockClient(jwks(KID, keyPair));

        for (int i = 0; i < 3; i++)
        {
            DecodedJWT jwt = JWT.decode(createToken(ISSUER, CLIENT_ID, "unknown-key-" + i, Instant.now().plusSeconds(300), keyPair));
            assertFalse(JWTVerifier.verifySignature(jwt, endpoint, allowedIssuers, CLIENT_ID, client, cache));
        }
        verify(client, times(1)).target(endpoint);
    }

    private static JsonObject jwks(String kid, KeyPair publishedKeyPair)
    {
        JsonObject jwk = Json.createObjectBuilder().
            add("kty", "RSA").
            add("alg", "RS256").
            add("kid", kid).
            add("n", base64Url(((RSAPublicKey) publishedKeyPair.getPublic()).getModulus())).
            add("e", base64Url(((RSAPublicKey) publishedKeyPair.getPublic()).getPublicExponent())).
            build();
        return Json.createObjectBuilder().add("keys", Json.createArrayBuilder().add(jwk)).build();
    }

    private static Client mockClient(JsonObject jwks)
    {
        Client client = mock(Client.class);
        WebTarget target = mock(WebTarget.class);
        Invocation.Builder builder = mock(Invocation.Builder.class);
        Response response = mock(Response.class);
        when(client.target(any(URI.class))).thenReturn(target);
        when(target.request()).thenReturn(builder);
        when(builder.get()).thenReturn(response);
        when(response.getStatusInfo()).thenReturn(Response.Status.OK);
        when(response.readEntity(JsonObject.class)).thenReturn(jwks);
        return client;
    }

    private static String createToken(String issuer, String audience, String kid, Instant expiresAt, KeyPair signingKeyPair)
    {
        return createToken(issuer, audience, kid, expiresAt,
            Algorithm.RSA256((RSAPublicKey) signingKeyPair.getPublic(), (RSAPrivateKey) signingKeyPair.getPrivate()));
    }

    private static String createToken(String issuer, String audience, String kid, Instant expiresAt, Algorithm algorithm)
    {
        JWTCreator.Builder builder = JWT.create().
            withIssuer(issuer).
            withAudience(audience).
            withSubject(SUBJECT).
            withExpiresAt(expiresAt);
        if (kid != null) builder = builder.withKeyId(kid);

        return builder.sign(algorithm);
    }

    private static String base64Url(BigInteger value)
    {
        byte[] bytes = value.toByteArray();
        if (bytes.length > 1 && bytes[0] == 0) // drop the sign byte so the magnitude round-trips
        {
            byte[] trimmed = new byte[bytes.length - 1];
            System.arraycopy(bytes, 1, trimmed, 0, trimmed.length);
            bytes = trimmed;
        }
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

}
