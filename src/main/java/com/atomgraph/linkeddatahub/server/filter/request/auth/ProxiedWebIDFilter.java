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
import java.net.URISyntaxException;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.security.cert.CertificateParsingException;
import java.security.cert.X509Certificate;
import jakarta.annotation.Priority;
import jakarta.ws.rs.InternalServerErrorException;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.PreMatching;

/**
 * WebID authentication filter subclass that receives the client certificate as HTTP request header value.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@PreMatching
@Priority(Priorities.USER) // has to execute after HttpMethodOverrideFilter which has @Priority(Priorities.HEADER_DECORATOR + 50)
public class ProxiedWebIDFilter extends WebIDFilter
{
    private static final String CLIENT_CERT_HEADER_NAME = "Client-Cert"; // https://tools.ietf.org/id/draft-bdc-something-something-certificate-01.html
            
    private final CertificateFactory certFactory;

    /**
     * Constructs filter.
     */
    public ProxiedWebIDFilter()
    {
        super();
        
        try
        {
            this.certFactory = CertificateFactory.getInstance("X.509");
        }
        catch (CertificateException ex)
        {
            throw new InternalServerErrorException(ex);
        }
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
