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

import com.atomgraph.core.MediaTypes;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.InetAddress;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.security.cert.X509Certificate;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.atomic.AtomicReference;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SNIHostName;
import javax.net.ssl.SNIMatcher;
import javax.net.ssl.SNIServerName;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLParameters;
import javax.net.ssl.SSLServerSocket;
import javax.net.ssl.SSLSocket;
import javax.net.ssl.StandardConstants;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * The TLS server name the client sends through a proxy. A proxy that verifies client certificates (nginx with
 * <code>ssl_verify_client</code>) answers <code>421</code> when it differs from the <code>Host</code> header.
 */
public class ProxySNITest
{

    /** What a TLS stub server saw: the handshake's server name and the request's <code>Host</code>. */
    private record Exchange(String serverName, String host) { }

    @Test
    public void proxySendsLogicalHostAsServerName() throws Exception
    {
        List<Exchange> exchanges = new CopyOnWriteArrayList<>();

        // asks for a client certificate as nginx's optional_no_ca does, so the client authenticates as it does in production
        KeyManagerFactory kmf = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
        kmf.init(Credentials.load(ClientFactoryTest.keyStorePath(), "changeit"), "changeit".toCharArray());
        SSLContext ctx = SSLContext.getInstance("TLS");
        ctx.init(kmf.getKeyManagers(), new TrustManager[] { TRUST_ALL }, new SecureRandom());

        try (SSLServerSocket server = (SSLServerSocket) ctx.getServerSocketFactory().createServerSocket(0, 0, InetAddress.getLoopbackAddress()))
        {
            server.setWantClientAuth(true);
            Thread acceptor = new Thread(() -> serve(server, exchanges));
            acceptor.setDaemon(true);
            acceptor.start();

            URI proxy = URI.create("https://127.0.0.1:" + server.getLocalPort() + "/");
            LDHClient client = new LDHClient(ClientFactory.createClient(ClientFactoryTest.keyStorePath(), "changeit", proxy), new MediaTypes());
            // the end-user dataspace, its admin dataspace, then the end-user one again: what make-public does
            for (String uri : List.of("https://docs.example.org/", "https://admin.docs.example.org/", "https://docs.example.org/"))
                try (Response response = client.head(URI.create(uri), new MediaType[] { MediaType.WILDCARD_TYPE }))
                {
                    assertEquals(200, response.getStatus());
                }
        }

        assertEquals(List.of(new Exchange("docs.example.org", "docs.example.org"),
            new Exchange("admin.docs.example.org", "admin.docs.example.org"),
            new Exchange("docs.example.org", "docs.example.org")), exchanges);
    }

    /** Answers every request on every connection with an empty <code>200</code>, keeping the connections alive. */
    private static void serve(SSLServerSocket server, List<Exchange> exchanges)
    {
        while (!server.isClosed())
        {
            try
            {
                SSLSocket socket = (SSLSocket) server.accept();
                Thread connection = new Thread(() -> converse(socket, exchanges));
                connection.setDaemon(true);
                connection.start();
            }
            catch (java.io.IOException ex)
            {
                return; // closed
            }
        }
    }

    private static void converse(SSLSocket socket, List<Exchange> exchanges)
    {
        try (socket)
        {
            // read from the ClientHello: a resumed session reports the server names of the handshake that created it
            AtomicReference<String> serverName = new AtomicReference<>();
            SSLParameters params = socket.getSSLParameters();
            params.setSNIMatchers(List.of(new SNIMatcher(StandardConstants.SNI_HOST_NAME)
            {

                @Override
                public boolean matches(SNIServerName name)
                {
                    serverName.set(((SNIHostName) name).getAsciiName());
                    return true;
                }

            }));
            socket.setSSLParameters(params);
            socket.startHandshake();
            BufferedReader in = new BufferedReader(new InputStreamReader(socket.getInputStream(), StandardCharsets.ISO_8859_1));
            OutputStream out = socket.getOutputStream();

            // the requests carry no body, so each ends at its blank line
            for (String line = in.readLine(); line != null; line = in.readLine())
            {
                String host = null;
                for (; line != null && !line.isEmpty(); line = in.readLine())
                    if (line.toLowerCase(Locale.ROOT).startsWith("host:")) host = line.substring(5).trim();
                exchanges.add(new Exchange(serverName.get(), host));
                out.write("HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n".getBytes(StandardCharsets.ISO_8859_1));
                out.flush();
            }
        }
        catch (java.io.IOException ex)
        {
            // the client went away
        }
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
