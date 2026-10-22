/**
 *  Copyright 2020 Martynas Jusevičius <martynas@atomgraph.com>
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

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.net.URISyntaxException;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.security.cert.CertificateParsingException;
import java.security.cert.X509Certificate;
import jakarta.annotation.Priority;
import jakarta.ws.rs.InternalServerErrorException;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.PreMatching;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * WebID authentication filter subclass that receives the client certificate as HTTP request header value.
 * The header is accepted only on a request that carries the proxy secret in the <code>Proxy-Secret</code> header,
 * which the reverse proxy sets. The secret is read from the file named by the
 * <code>com.atomgraph.linkeddatahub.proxySecretFile</code> system property; without one, the header is never accepted.
 * <code>Proxy-Secret</code> is removed from the request once checked, so nothing downstream can pass it on.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@PreMatching
@Priority(Priorities.USER) // has to execute after HttpMethodOverrideFilter which has @Priority(Priorities.HEADER_DECORATOR + 50)
public class ProxiedWebIDFilter extends WebIDFilter
{
    private static final Logger log = LoggerFactory.getLogger(ProxiedWebIDFilter.class);

    /** Name of the request header that carries the client certificate */
    public static final String CLIENT_CERT_HEADER_NAME = "Client-Cert"; // https://tools.ietf.org/id/draft-bdc-something-something-certificate-01.html
    /** Name of the request header that carries the proxy secret */
    public static final String PROXY_SECRET_HEADER_NAME = "Proxy-Secret";
    /** System property naming the file that holds the proxy secret */
    public static final String PROXY_SECRET_FILE_PROPERTY = "com.atomgraph.linkeddatahub.proxySecretFile";

    private final CertificateFactory certFactory;
    private final byte[] proxySecret;

    /**
     * Constructs filter with the proxy secret read from the file named by the {@value #PROXY_SECRET_FILE_PROPERTY} system property.
     */
    public ProxiedWebIDFilter()
    {
        super();

        this.proxySecret = readProxySecret(System.getProperty(PROXY_SECRET_FILE_PROPERTY));
        if (proxySecret == null && log.isWarnEnabled()) log.warn("No proxy secret configured: the {} header will be ignored", CLIENT_CERT_HEADER_NAME);
        try
        {
            this.certFactory = CertificateFactory.getInstance("X.509");
        }
        catch (CertificateException ex)
        {
            throw new InternalServerErrorException(ex);
        }
    }
    
    /**
     * Reads the proxy secret from a file. Surrounding whitespace is ignored.
     *
     * @param path file path, or null
     * @return secret bytes, or null if no path is given
     * @throws IllegalStateException if the file cannot be read or is empty
     */
    public static byte[] readProxySecret(String path)
    {
        if (path == null) return null;

        try
        {
            String secret = Files.readString(Path.of(path), StandardCharsets.UTF_8).strip();
            if (secret.isEmpty()) throw new IllegalStateException("Proxy secret file '" + path + "' is empty");
            return secret.getBytes(StandardCharsets.UTF_8);
        }
        catch (IOException ex)
        {
            throw new IllegalStateException("Could not read proxy secret file '" + path + "'", ex);
        }
    }

    /**
     * Returns true if the given <code>Proxy-Secret</code> value equals the configured secret. Constant-time.
     *
     * @param value header value, or null
     * @return true if the secret is configured and matches
     */
    public boolean isProxySecret(String value)
    {
        return proxySecret != null && value != null && MessageDigest.isEqual(proxySecret, value.getBytes(StandardCharsets.UTF_8));
    }

    /**
     * Removes <code>Proxy-Secret</code> from the request, and <code>Client-Cert</code> as well unless the secret matched,
     * then authenticates.
     *
     * @param request request context
     * @throws IOException I/O error
     */
    @Override
    public void filter(ContainerRequestContext request) throws IOException
    {
        boolean fromProxy = isProxySecret(request.getHeaderString(PROXY_SECRET_HEADER_NAME));
        request.getHeaders().remove(PROXY_SECRET_HEADER_NAME);
        if (!fromProxy) request.getHeaders().remove(CLIENT_CERT_HEADER_NAME);

        super.filter(request);
    }

    @Override
    public X509Certificate getWebIDCertificate(ContainerRequestContext request) throws URISyntaxException, CertificateException, CertificateParsingException
    {
        if (request.getHeaderString(CLIENT_CERT_HEADER_NAME) != null)
        {
            String pemString = URLDecoder.decode(request.getHeaderString(CLIENT_CERT_HEADER_NAME), StandardCharsets.UTF_8);
            return (X509Certificate)getCertificateFactory().generateCertificate(new ByteArrayInputStream(pemString.getBytes()));
        }
        
        return null;
    }
    
    /**
     * Returns certificate factory.
     * 
     * @return certificate factory
     */
    public CertificateFactory getCertificateFactory()
    {
        return certFactory;
    }
    
}
