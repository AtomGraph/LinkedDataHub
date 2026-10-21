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
package com.atomgraph.linkeddatahub.server.filter.request.auth;

import com.auth0.jwt.JWT;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.exceptions.TokenExpiredException;
import jakarta.json.Json;
import jakarta.json.JsonObject;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.core.Cookie;
import java.math.BigInteger;
import java.net.URI;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.NoSuchAlgorithmException;
import java.security.interfaces.RSAPrivateKey;
import java.security.interfaces.RSAPublicKey;
import java.time.Instant;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import net.jodah.expiringmap.ExpiringMap;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit tests for the ID token authentication of {@link IDTokenFilterBase}: no claim of a token is acted upon, the
 * expiry included, before its signature verifies.
 * The JWKS is supplied through the cache so verification runs offline.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@ExtendWith(MockitoExtension.class)
public class IDTokenFilterBaseTest
{

    private static final String ISSUER = "https://accounts.example.com";
    private static final String CLIENT_ID = "client-abc";
    private static final String KID = "test-key-1";
    private static final String SUBJECT = "registered-user-123";
    private static final URI JWKS_ENDPOINT = URI.create("https://accounts.example.com/jwks");

    private static KeyPair keyPair; // published in the JWKS
    private static KeyPair otherKeyPair; // not published

    @Mock private com.atomgraph.linkeddatahub.Application system;
    @Mock private ContainerRequestContext request;

    private IDTokenFilterBase filter;

    @BeforeAll
    public static void initKeys() throws NoSuchAlgorithmException
    {
        KeyPairGenerator generator = KeyPairGenerator.getInstance("RSA");
        generator.initialize(2048);
        keyPair = generator.generateKeyPair();
        otherKeyPair = generator.generateKeyPair();
    }

    @BeforeEach
    public void setUp()
    {
        JsonObject jwk = Json.createObjectBuilder().
            add("kty", "RSA").
            add("alg", "RS256").
            add("kid", KID).
            add("n", base64Url(((RSAPublicKey) keyPair.getPublic()).getModulus())).
            add("e", base64Url(((RSAPublicKey) keyPair.getPublic()).getPublicExponent())).
            build();
        ExpiringMap<String, JsonObject> jwksCache = ExpiringMap.builder().build();
        jwksCache.put(JWKS_ENDPOINT.toString(), Json.createObjectBuilder().add("keys", Json.createArrayBuilder().add(jwk)).build());
        lenient().when(system.getJWKSCache()).thenReturn(jwksCache);
        // a refresh token is stored for the subject, so reading it would let a forged token be "refreshed"
        lenient().when(system.getRefreshToken(anyString())).thenReturn("stored-refresh-token");

        filter = new TestIDTokenFilter(system);
    }

    /** A forged unsigned token with a past expiry, naming a registered subject: not authenticated, refresh token untouched */
    @Test
    public void testUnsignedExpiredTokenNotAuthenticated()
    {
        sendCookie(createToken(Instant.now().minusSeconds(3600), Algorithm.none()));

        assertNull(filter.authenticate(request));
        verify(system, never()).getRefreshToken(anyString());
    }

    /** A token signed with a key the provider does not publish: not authenticated, refresh token untouched */
    @Test
    public void testWrongKeyExpiredTokenNotAuthenticated()
    {
        sendCookie(createToken(Instant.now().minusSeconds(3600), rsa(otherKeyPair)));

        assertNull(filter.authenticate(request));
        verify(system, never()).getRefreshToken(anyString());
    }

    @Test
    public void testWrongKeyValidTokenNotAuthenticated()
    {
        sendCookie(createToken(Instant.now().plusSeconds(3600), rsa(otherKeyPair)));

        assertNull(filter.authenticate(request));
    }

    /** An HMAC token keyed with the published modulus: not authenticated, refresh token untouched */
    @Test
    public void testHmacExpiredTokenNotAuthenticated()
    {
        byte[] secret = ((RSAPublicKey) keyPair.getPublic()).getModulus().toByteArray();
        sendCookie(createToken(Instant.now().minusSeconds(3600), Algorithm.HMAC256(secret)));

        assertNull(filter.authenticate(request));
        verify(system, never()).getRefreshToken(anyString());
    }

    @Test
    public void testMalformedTokenNotAuthenticated()
    {
        sendCookie("not-a-jwt");

        assertNull(filter.authenticate(request));
        verify(system, never()).getRefreshToken(anyString());
    }

    /** A genuine but expired token reaches the refresh: with no refresh token stored, the expiry is reported */
    @Test
    public void testGenuineExpiredTokenIsRefreshable()
    {
        when(system.getRefreshToken(SUBJECT)).thenReturn(null);
        sendCookie(createToken(Instant.now().minusSeconds(3600), rsa(keyPair)));

        assertThrows(TokenExpiredException.class, () -> filter.authenticate(request));
        verify(system).getRefreshToken(SUBJECT);
    }

    private void sendCookie(String token)
    {
        when(request.getCookies()).thenReturn(Map.of(IDTokenFilterBase.COOKIE_NAME, new Cookie.Builder(IDTokenFilterBase.COOKIE_NAME).value(token).build()));
    }

    private static Algorithm rsa(KeyPair signingKeyPair)
    {
        return Algorithm.RSA256((RSAPublicKey) signingKeyPair.getPublic(), (RSAPrivateKey) signingKeyPair.getPrivate());
    }

    private static String createToken(Instant expiresAt, Algorithm algorithm)
    {
        return JWT.create().
            withKeyId(KID).
            withIssuer(ISSUER).
            withAudience(CLIENT_ID).
            withSubject(SUBJECT).
            withExpiresAt(expiresAt).
            sign(algorithm);
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

    /** A provider whose endpoints are fixed and whose system is the mock; the token endpoint is never reachable */
    private static class TestIDTokenFilter extends IDTokenFilterBase
    {

        private final com.atomgraph.linkeddatahub.Application system;

        TestIDTokenFilter(com.atomgraph.linkeddatahub.Application system)
        {
            this.system = system;
            setClientID(CLIENT_ID);
            setClientSecret("secret");
        }

        @Override
        public com.atomgraph.linkeddatahub.Application getSystem()
        {
            return system;
        }

        @Override
        protected void initClientCredentials()
        {
        }

        @Override
        protected List<String> getIssuers()
        {
            return List.of(ISSUER);
        }

        @Override
        protected URI getJWKSEndpoint()
        {
            return JWKS_ENDPOINT;
        }

        @Override
        protected URI getTokenEndpoint()
        {
            return URI.create("https://accounts.example.com/token");
        }

        @Override
        protected URI getLoginURL()
        {
            return URI.create("https://localhost:4443/oauth2/login/example");
        }

        @Override
        protected URI getAuthorizeURL()
        {
            return URI.create("https://localhost:4443/oauth2/authorize/example");
        }

    }

}
