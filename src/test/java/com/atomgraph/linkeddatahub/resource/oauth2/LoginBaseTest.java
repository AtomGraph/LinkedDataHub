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

import com.atomgraph.linkeddatahub.dataspaces.model.AdminDataspace;
import com.atomgraph.linkeddatahub.dataspaces.model.Dataspace;
import com.atomgraph.linkeddatahub.dataspaces.model.EndUserDataspace;
import com.atomgraph.linkeddatahub.model.Service;
import com.auth0.jwt.interfaces.DecodedJWT;
import jakarta.servlet.ServletConfig;
import java.net.URI;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.RETURNS_DEEP_STUBS;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Unit tests for the first login: the email it links by, which is only an address the provider verified, since an
 * unverified one is anyone's to claim and would link the new account to the agent whose <code>foaf:mbox</code> it is;
 * and the stores it reads and writes, which are this dataspace's admin and the root admin, never another dataspace's.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class LoginBaseTest
{

    private final Service localService = mock(Service.class);
    private final Service rootService = mock(Service.class);
    private TestLogin login;

    @BeforeEach
    public void setUp()
    {
        Dataspace dataspace = mock(Dataspace.class);
        when(dataspace.canAs(EndUserDataspace.class)).thenReturn(true);
        ServletConfig servletConfig = mock(ServletConfig.class, RETURNS_DEEP_STUBS);
        when(servletConfig.getServletContext().getInitParameter(anyString())).thenReturn("configured");

        AdminDataspace localAdmin = mock(AdminDataspace.class);
        when(localAdmin.getService()).thenReturn(localService);
        AdminDataspace rootAdmin = mock(AdminDataspace.class);
        when(rootAdmin.getService()).thenReturn(rootService);

        login = new TestLogin(dataspace, servletConfig, localAdmin, rootAdmin);
    }

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

    /** New accounts and agents are written to the root admin dataspace */
    @Test
    public void testAgentServiceIsRoot()
    {
        assertEquals(rootService, login.getAgentService());
    }

    /** An account in the root admin dataspace makes the subject known on any dataspace */
    @Test
    public void testRootAccountKnown()
    {
        login.accounts.add(rootService);

        assertTrue(login.isKnownSubject("subject", "https://accounts.example.com"));
    }

    /** An account this dataspace made before accounts moved to root makes the subject known here */
    @Test
    public void testLegacyAccountKnown()
    {
        login.accounts.add(localService);

        assertTrue(login.isKnownSubject("subject", "https://accounts.example.com"));
    }

    /** An account in another dataspace's admin is not read: the subject is new here, and gets its account in root */
    @Test
    public void testOtherDataspaceAccountUnknown()
    {
        login.accounts.add(mock(Service.class));

        assertFalse(login.isKnownSubject("subject", "https://accounts.example.com"));
    }

    /** A login whose services hold the subject's account as {@link #accounts} says, and whose provider is never reached */
    private static class TestLogin extends LoginBase
    {

        private final AdminDataspace localAdmin, rootAdmin;
        private final Set<Service> accounts = new HashSet<>();

        TestLogin(Dataspace dataspace, ServletConfig servletConfig, AdminDataspace localAdmin, AdminDataspace rootAdmin)
        {
            super(null, null, null, dataspace, null, servletConfig, "client-abc", "secret");
            this.localAdmin = localAdmin;
            this.rootAdmin = rootAdmin;
        }

        @Override
        public AdminDataspace getAdminDataspace()
        {
            return localAdmin;
        }

        @Override
        public AdminDataspace getRootAdminDataspace()
        {
            return rootAdmin;
        }

        @Override
        protected boolean userAccountExists(String subjectId, String issuer, Service service)
        {
            return accounts.contains(service);
        }

        @Override
        protected Map<String, String> getUserInfo(DecodedJWT jwt, String accessToken)
        {
            throw new UnsupportedOperationException();
        }

        @Override
        protected URI getJWKSEndpoint()
        {
            throw new UnsupportedOperationException();
        }

        @Override
        protected List<String> getIssuers()
        {
            throw new UnsupportedOperationException();
        }

        @Override
        public URI getTokenEndpoint()
        {
            throw new UnsupportedOperationException();
        }

    }

}
