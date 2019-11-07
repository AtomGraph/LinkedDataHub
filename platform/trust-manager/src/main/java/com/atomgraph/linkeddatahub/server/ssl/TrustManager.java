/**
 *  Copyright 2019 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.server.ssl;

import java.security.KeyStore;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import javax.net.ssl.TrustManagerFactory;
import javax.net.ssl.X509TrustManager;

/**
 * LinkedDataHub trust manager.
 * Configured in Tomcat's <code>server.xml</code> as <code>Connector/@trustManagerClassName</code>.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see <a href="https://tomcat.apache.org/tomcat-8.0-doc/config/http.html#SSL_Support_-_BIO,_NIO_and_NIO2">SSL Support - BIO, NIO and NIO2</a>
 * @see <a href="https://docs.oracle.com/javase/8/docs/technotes/guides/security/jsse/JSSERefGuide.html#X509TrustManager">Creating an X509TrustManager</a>
 */
public class TrustManager implements X509TrustManager
{

    private final X509TrustManager pkcsTrustManager;

    public TrustManager() throws Exception
    {
        TrustManagerFactory tmf = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
        tmf.init((KeyStore)null); // use default keystore - secretary WebID certificate is added to it by Docker entrypoint script

        javax.net.ssl.TrustManager tms[] = tmf.getTrustManagers();

        for (javax.net.ssl.TrustManager tm : tms)
            if (tm instanceof X509TrustManager)
            {
                pkcsTrustManager = (X509TrustManager)tm;
                return;
            }

         throw new Exception("Couldn't initialize TrustManager - default X509TrustManager implementation missing");
    }
    
    @Override
    public void checkClientTrusted(X509Certificate[] chain, String authType) throws CertificateException
    {
        // allow all client certificates - we validate WebIDs in <code>WebIDFilter</code>, ignore others
    }

    @Override
    public void checkServerTrusted(X509Certificate[] chain, String authType) throws CertificateException
    {
        pkcsTrustManager.checkServerTrusted(chain, authType);
    }

    @Override
    public X509Certificate[] getAcceptedIssuers()
    {
        return new X509Certificate[] {}; // accept all issuers
    }
    
}
