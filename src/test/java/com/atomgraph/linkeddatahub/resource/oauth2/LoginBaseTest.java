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
package com.atomgraph.linkeddatahub.resource.oauth2;

import java.util.Map;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * Unit tests for the email the first login links by: only an address the provider verified, since an unverified one
 * is anyone's to claim and would link the new account to the agent whose <code>foaf:mbox</code> it is.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class LoginBaseTest
{

    @Test
    public void testVerifiedEmailKept()
    {
        assertEquals(Optional.of("owner@example.org"), LoginBase.verifiedEmail(Map.of("email", "owner@example.org", "email_verified", "true")));
    }

    @Test
    public void testUnverifiedEmailIgnored()
    {
        assertEquals(Optional.empty(), LoginBase.verifiedEmail(Map.of("email", "owner@example.org", "email_verified", "false")));
    }

    @Test
    public void testEmailWithoutVerificationIgnored()
    {
        assertEquals(Optional.empty(), LoginBase.verifiedEmail(Map.of("email", "owner@example.org")));
    }

    @Test
    public void testNoEmail()
    {
        assertEquals(Optional.empty(), LoginBase.verifiedEmail(Map.of("email_verified", "true")));
    }

}
