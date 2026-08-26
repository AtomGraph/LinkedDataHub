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

package com.atomgraph.linkeddatahub.cli.http;

import com.atomgraph.core.io.ModelProvider;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.client.ClientBuilder;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.GeneralSecurityException;
import java.security.KeyStore;
import java.security.SecureRandom;
import java.security.cert.X509Certificate;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;
import org.apache.http.config.Registry;
import org.apache.http.config.RegistryBuilder;
import org.apache.http.conn.socket.ConnectionSocketFactory;
import org.apache.http.conn.socket.PlainConnectionSocketFactory;
import org.apache.http.conn.ssl.NoopHostnameVerifier;
import org.apache.http.conn.ssl.SSLConnectionSocketFactory;
import org.apache.http.impl.conn.PoolingHttpClientConnectionManager;
import org.glassfish.jersey.apache.connector.ApacheClientProperties;
import org.glassfish.jersey.apache.connector.ApacheConnectorProvider;
import org.glassfish.jersey.client.ClientConfig;
import org.glassfish.jersey.client.ClientProperties;
import org.glassfish.jersey.client.RequestEntityProcessing;
import org.glassfish.jersey.media.multipart.MultiPartFeature;

/**
 * Builds a Jersey HTTP client authenticated with a WebID client certificate from a PKCS12 keystore.
 * Mirrors <code>Application.getClient()</code> in LinkedDataHub, with server certificate checks
 * disabled (equivalent of <code>curl -k</code> against self-signed dev instances).
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class ClientFactory
{

    private ClientFactory() { }

    /**
     * Builds the client instance.
     *
     * @param keyStoreFile PKCS12 (.p12) keystore file with the WebID certificate
     * @param keyStorePassword keystore password
     * @return client instance
     */
    public static Client createClient(Path keyStoreFile, String keyStorePassword)
    {
        SSLContext ctx;
        try
        {
            KeyStore keyStore = KeyStore.getInstance("PKCS12");
            try (InputStream is = Files.newInputStream(keyStoreFile))
            {
                keyStore.load(is, keyStorePassword.toCharArray());
            }

            // for client authentication
            KeyManagerFactory kmf = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
            kmf.init(keyStore, keyStorePassword.toCharArray());

            ctx = SSLContext.getInstance("TLS");
            ctx.init(kmf.getKeyManagers(), new TrustManager[] { TRUST_ALL }, new SecureRandom());
        }
        catch (IOException | GeneralSecurityException ex)
        {
            throw new IllegalArgumentException("Could not load PKCS12 keystore '" + keyStoreFile + "': " + ex.getMessage() + " (wrong password?)", ex);
        }

        Registry<ConnectionSocketFactory> socketFactoryRegistry = RegistryBuilder.<ConnectionSocketFactory>create().
            register("https", new SSLConnectionSocketFactory(ctx, NoopHostnameVerifier.INSTANCE)).
            register("http", new PlainConnectionSocketFactory()).
            build();

        ClientConfig config = new ClientConfig();
        config.connectorProvider(new ApacheConnectorProvider());
        config.register(MultiPartFeature.class);
        config.register(new ModelProvider());
        config.property(ClientProperties.FOLLOW_REDIRECTS, false); // scripts use curl without -L
        config.property(ClientProperties.REQUEST_ENTITY_PROCESSING, RequestEntityProcessing.BUFFERED);
        config.property(ApacheClientProperties.CONNECTION_MANAGER, new PoolingHttpClientConnectionManager(socketFactoryRegistry));

        return ClientBuilder.newBuilder().
            withConfig(config).
            sslContext(ctx).
            hostnameVerifier(NoopHostnameVerifier.INSTANCE).
            build();
    }

    private static final X509TrustManager TRUST_ALL = new X509TrustManager()
    {

        @Override
        public void checkClientTrusted(X509Certificate[] chain, String authType) { }

        @Override
        public void checkServerTrusted(X509Certificate[] chain, String authType) { }

        @Override
        public X509Certificate[] getAcceptedIssuers()
        {
            return new X509Certificate[0];
        }

    };

}
