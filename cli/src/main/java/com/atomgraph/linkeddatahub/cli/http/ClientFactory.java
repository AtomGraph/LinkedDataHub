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
import java.nio.file.Path;
import java.security.GeneralSecurityException;
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
 * Builds a Jersey HTTP client authenticated with the agent's WebID client certificate, read from a
 * PKCS12 keystore or a PEM file by {@link Credentials}.
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
     * @param certFile PKCS12 keystore or PEM file with the WebID certificate and private key
     * @param certPassword keystore password, or the passphrase of an encrypted PEM key; null for an unencrypted PEM
     * @return client instance
     */
    public static Client createClient(Path certFile, String certPassword)
    {
        SSLContext ctx;
        // a PEM with an unencrypted key has no password: its in-memory keystore is protected with an empty one
        char[] password = certPassword != null ? certPassword.toCharArray() : new char[0];
        try
        {
            // for client authentication
            KeyManagerFactory kmf = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
            kmf.init(Credentials.load(certFile, certPassword), password);

            ctx = SSLContext.getInstance("TLS");
            ctx.init(kmf.getKeyManagers(), new TrustManager[] { TRUST_ALL }, new SecureRandom());
        }
        catch (GeneralSecurityException ex)
        {
            throw new IllegalArgumentException("Could not set up client authentication with '" + certFile + "': " + ex.getMessage(), ex);
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
