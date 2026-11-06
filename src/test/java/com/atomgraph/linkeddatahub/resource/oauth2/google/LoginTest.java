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
package com.atomgraph.linkeddatahub.resource.oauth2.google;

import com.auth0.jwt.JWT;
import com.auth0.jwt.algorithms.Algorithm;
import java.util.Map;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * Unit tests for the claims a Google ID token gives the first login: <code>email_verified</code> is a boolean claim,
 * and the login reads it, so it has to survive with the string ones.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class LoginTest
{

    @Test
    public void testBooleanClaimsKept()
    {
        String token = JWT.create().withSubject("subject").withClaim("email", "owner@example.org").withClaim("email_verified", true).sign(Algorithm.none());
        Map<String, String> claims = Login.claims(JWT.decode(token));

        assertEquals("subject", claims.get("sub"));
        assertEquals("owner@example.org", claims.get("email"));
        assertEquals("true", claims.get("email_verified"));
    }

    @Test
    public void testUnverifiedClaimKept()
    {
        String token = JWT.create().withClaim("email", "owner@example.org").withClaim("email_verified", false).sign(Algorithm.none());

        assertEquals("false", Login.claims(JWT.decode(token)).get("email_verified"));
    }

}
