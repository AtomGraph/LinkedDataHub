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
package com.atomgraph.linkeddatahub.server.filter.request.auth;

import jakarta.ws.rs.container.ContainerRequestContext;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.when;

/**
 * Unit tests for {@link ProxiedWebIDFilter}, which extracts the client certificate from the
 * {@code Client-Cert} request header (URL-encoded PEM) instead of the TLS connection.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@ExtendWith(MockitoExtension.class)
public class ProxiedWebIDFilterTest
{

    private static final String CLIENT_CERT_HEADER_NAME = "Client-Cert";

    /** A self-signed X.509 certificate (CN=Test WebID, O=LinkedDataHub) in PEM form. */
    private static final String CERT_PEM =
        "-----BEGIN CERTIFICATE-----\n" +
        "MIIC1jCCAb4CCQD35LqgLKP0ATANBgkqhkiG9w0BAQsFADAtMRMwEQYDVQQDDApU\n" +
        "ZXN0IFdlYklEMRYwFAYDVQQKDA1MaW5rZWREYXRhSHViMB4XDTI2MDYxODA4Mzkz\n" +
        "OFoXDTI2MDYxOTA4MzkzOFowLTETMBEGA1UEAwwKVGVzdCBXZWJJRDEWMBQGA1UE\n" +
        "CgwNTGlua2VkRGF0YUh1YjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB\n" +
        "AMRsMfh0IikmxDbZ0kca2FRI+WXelczdi+dU9ZC42cAZJM6pEu9icvCdTKBKipYE\n" +
        "07PkfAgsmkS3qzly1iQzyXZFzopndg9FdFvWZyn8SdxNSKCcQt13NTp8sXflkdxK\n" +
        "SfOseUx1cZ0T4ylGNwkqxcqZo5b06CJqiZqjgO4x7kYWWrli44AgzMkT3AgJqq5X\n" +
        "iSo5j8gOjicR+ZywLAEvWH0ITja4sIgsQzZHxbquOuPEevnT+135M33wHxsY5MHJ\n" +
        "Ykxid7C4ifVm4jXf81CmnoCifR9UeBnMZ0QBPBP/Exv+CpTgb3TBAfF1o1QsEuM3\n" +
        "60fYmqLcwLiKgZqDJ7ZH80UCAwEAATANBgkqhkiG9w0BAQsFAAOCAQEAeYJGVnFq\n" +
        "CARK15JQQk1YBAUPspkFWAeXH9UzYyxpqt0bLlYO9g4KExJVJvE9Qub2lHXBs36j\n" +
        "/elRF+PR5Zt/6LD26OnSu+QWkFSqbO6Otul7g9ikMufuhNrZyyOOzidqFfcfkhWx\n" +
        "FZh+yZhGoo2f+ddMuYbK3lKI+/DMswfdNN6VN++EOYskjWBB85GKUxEJTLEF2yE+\n" +
        "yRtqnQfX3ucvO2Zd1XHsgknzoSfG8CXZF3GDcqzzEZ6Aa//xtwYRCmNmj9E9SdMY\n" +
        "xuCHnQP3cV/vBBhxt1BWdIRtcU6xpasNMfWGgAxqrCTz+GnT7FExbe5qt6CgX7yl\n" +
        "JLw8c9VNQzsM9g==\n" +
        "-----END CERTIFICATE-----\n";

    @Mock private ContainerRequestContext requestContext;

    private ProxiedWebIDFilter filter;

    @BeforeEach
    public void setUp()
    {
        filter = new ProxiedWebIDFilter();
    }

    @Test
    public void testCertificateFactoryIsX509()
    {
        assertNotNull(filter.getCertificateFactory());
        assertEquals("X.509", filter.getCertificateFactory().getType());
    }

    /** No {@code Client-Cert} header — no certificate. */
    @Test
    public void testNoHeaderReturnsNull() throws Exception
    {
        when(requestContext.getHeaderString(CLIENT_CERT_HEADER_NAME)).thenReturn(null);
        assertNull(filter.getWebIDCertificate(requestContext));
    }

    /** A URL-encoded PEM certificate in the header is decoded and parsed into an X509Certificate. */
    @Test
    public void testValidHeaderParsesCertificate() throws Exception
    {
        String encoded = URLEncoder.encode(CERT_PEM, StandardCharsets.UTF_8);
        when(requestContext.getHeaderString(CLIENT_CERT_HEADER_NAME)).thenReturn(encoded);

        X509Certificate cert = filter.getWebIDCertificate(requestContext);

        assertNotNull(cert);
        assertTrue(cert.getSubjectX500Principal().getName().contains("Test WebID"));
    }

    /** A header that is not a valid certificate must surface as a CertificateException. */
    @Test
    public void testMalformedHeaderThrows()
    {
        when(requestContext.getHeaderString(CLIENT_CERT_HEADER_NAME)).thenReturn("garbage-not-a-cert");
        assertThrows(CertificateException.class, () -> filter.getWebIDCertificate(requestContext));
    }

}
