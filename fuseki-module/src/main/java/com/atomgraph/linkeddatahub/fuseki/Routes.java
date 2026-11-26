/**
 *  Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.fuseki;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.ProxySelector;
import java.net.Socket;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.security.GeneralSecurityException;
import java.security.KeyStore;
import java.security.Principal;
import java.security.PrivateKey;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.time.Duration;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicBoolean;
import javax.net.ssl.KeyManager;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLEngine;
import javax.net.ssl.TrustManager;
import javax.net.ssl.TrustManagerFactory;
import javax.net.ssl.X509ExtendedKeyManager;
import javax.net.ssl.X509ExtendedTrustManager;
import javax.net.ssl.X509TrustManager;

/**
 * How a delegated <code>SERVICE</code> call reaches its target, and whether the target asks for a client certificate.
 * <p>
 * Two routes, as the platform's own client has them:
 * <ul>
 *   <li><b>this deployment</b> - a target on the platform's host or a subdomain of it. Its public name is no route
 *       from inside the network, so the call goes to the internal proxy (nginx's client-certificate listener) with the
 *       original <code>Host</code>, and the proxy's certificate is checked against the deployment's own server
 *       certificate rather than by name, as the platform's client does
 *       (<code>ClientUriRewriteFilter</code>, <code>NoopHostnameVerifier</code>); no egress proxy;</li>
 *   <li><b>anywhere else</b> - the target as named, through the JVM's proxy (the egress proxy), with the JDK's trust
 *       and name checks.</li>
 * </ul>
 * Both present the secretary's certificate when the server asks for one, and only then: that is what makes the call the
 * secretary's. Whether a server asks is found out first by an anonymous handshake ({@link #asksForCertificate}), so the
 * agent's identity is never sent to an endpoint that does not want one (LinkedDataHub's own origins ask; a public SPARQL
 * service does not).
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class Routes
{

    /** How long whether an origin asks for a certificate is remembered */
    public static final Duration PROBE_TTL = Duration.ofMinutes(10);

    /**
     * Where a call goes and how.
     *
     * @param url the URL called
     * @param host the <code>Host</code> header to send, or null to send the URL's own
     * @param own whether it is this deployment's
     */
    public record Route(URI url, String host, boolean own) { }

    private final String deploymentHost;
    private final String proxyHost;
    private final int proxyPort;
    private final HttpClient ownClient, remoteClient;
    private final TrustManager[] ownTrust, remoteTrust;
    private final Map<String, Probed> probed = new ConcurrentHashMap<>();

    private record Probed(boolean asks, long at) { }

    /**
     * Constructs the routes.
     *
     * @param deploymentHost the platform's host, whose subdomains are its dataspaces (e.g. <code>localhost</code>)
     * @param proxyHost the internal proxy's host (e.g. <code>nginx</code>)
     * @param proxyPort the internal proxy's client-certificate port (e.g. <code>9443</code>)
     * @param secretary the keystore holding the secretary's key and certificate
     * @param secretaryPassword the keystore's password
     * @param server the deployment's server certificate, trusted for its own origins
     * @throws GeneralSecurityException if a key or certificate cannot be used
     */
    public Routes(String deploymentHost, String proxyHost, int proxyPort, KeyStore secretary, char[] secretaryPassword, X509Certificate server) throws GeneralSecurityException
    {
        this.deploymentHost = deploymentHost;
        this.proxyHost = proxyHost;
        this.proxyPort = proxyPort;

        KeyManagerFactory kmf = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
        kmf.init(secretary, secretaryPassword);
        ownTrust = new TrustManager[] { pinned(server) };
        remoteTrust = defaultTrust();

        ownClient = client(kmf.getKeyManagers(), ownTrust, true, null);
        remoteClient = client(kmf.getKeyManagers(), remoteTrust, false, null);
    }

    private static HttpClient client(KeyManager[] keys, TrustManager[] trust, boolean own, HttpClient.Version version) throws GeneralSecurityException
    {
        SSLContext context = SSLContext.getInstance("TLS");
        context.init(keys, trust, null);
        HttpClient.Builder builder = HttpClient.newBuilder().sslContext(context).connectTimeout(Duration.ofSeconds(10))
            .proxy(own ? HttpClient.Builder.NO_PROXY : ProxySelector.getDefault());
        if (version != null) builder.version(version);
        return builder.build();
    }

    /**
     * Returns the route to a target.
     *
     * @param target the <code>SERVICE</code> IRI, without the marker
     * @return its route
     */
    public Route route(URI target)
    {
        String host = target.getHost();
        if (host != null && (host.equals(deploymentHost) || host.endsWith("." + deploymentHost)))
        {
            URI url = URI.create("https://" + proxyHost + ":" + proxyPort + target.getRawPath() + (target.getRawQuery() != null ? "?" + target.getRawQuery() : ""));
            return new Route(url, host + (target.getPort() != -1 ? ":" + target.getPort() : ""), true);
        }
        return new Route(target, null, false);
    }

    /**
     * Returns the client that makes a call on a route: it presents the secretary's certificate when asked.
     *
     * @param route the route
     * @return the client
     */
    public HttpClient client(Route route)
    {
        return route.own() ? ownClient : remoteClient;
    }

    /**
     * Returns whether the server on a route asks for a client certificate, by an anonymous handshake (a
     * <code>HEAD</code> with no certificate to give), remembered for {@link #PROBE_TTL} per origin.
     *
     * @param route the route
     * @return true if it asks
     */
    public boolean asksForCertificate(Route route)
    {
        if (!"https".equalsIgnoreCase(route.url().getScheme())) return false;
        String key = route.url().getScheme() + "://" + route.url().getAuthority() + "|" + route.host();
        Probed known = probed.get(key);
        long now = System.nanoTime();
        if (known != null && now - known.at() < PROBE_TTL.toNanos()) return known.asks();

        boolean asks = probe(route);
        probed.put(key, new Probed(asks, now));
        return asks;
    }

    /**
     * Makes the anonymous handshake.
     *
     * @param route the route
     * @return whether the server asked for a client certificate
     */
    protected boolean probe(Route route)
    {
        AtomicBoolean asked = new AtomicBoolean();
        try
        {
            // the route's trust, with a key manager that has no key and only records the question
            HttpClient client = client(new KeyManager[] { new Asked(asked) }, route.own() ? ownTrust : remoteTrust, route.own(), HttpClient.Version.HTTP_1_1);
            HttpRequest.Builder request = HttpRequest.newBuilder(route.url()).method("HEAD", HttpRequest.BodyPublishers.noBody()).timeout(Duration.ofSeconds(10));
            if (route.host() != null) request.header("Host", route.host());
            client.send(request.build(), HttpResponse.BodyHandlers.discarding());
        }
        catch (IOException | GeneralSecurityException ex)
        {
            // a server that asked and then refused the anonymous handshake still asked
            if (!asked.get()) return false;
        }
        catch (InterruptedException ex)
        {
            Thread.currentThread().interrupt();
        }
        return asked.get();
    }

    /**
     * A trust manager that accepts exactly the chains the server certificate's trust accepts, without checking the
     * name: the call goes to the internal proxy under its internal name, for a certificate issued to the public one.
     */
    private static X509ExtendedTrustManager pinned(X509Certificate server) throws GeneralSecurityException
    {
        KeyStore store = KeyStore.getInstance(KeyStore.getDefaultType());
        try
        {
            store.load(null, null);
        }
        catch (IOException ex)
        {
            throw new GeneralSecurityException(ex);
        }
        store.setCertificateEntry("server", server);
        TrustManagerFactory tmf = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
        tmf.init(store);
        X509TrustManager chains = (X509TrustManager)tmf.getTrustManagers()[0];
        return new X509ExtendedTrustManager()
        {
            @Override public void checkServerTrusted(X509Certificate[] chain, String authType, SSLEngine engine) throws CertificateException { chains.checkServerTrusted(chain, authType); }
            @Override public void checkServerTrusted(X509Certificate[] chain, String authType, Socket socket) throws CertificateException { chains.checkServerTrusted(chain, authType); }
            @Override public void checkServerTrusted(X509Certificate[] chain, String authType) throws CertificateException { chains.checkServerTrusted(chain, authType); }
            @Override public void checkClientTrusted(X509Certificate[] chain, String authType, SSLEngine engine) throws CertificateException { throw new CertificateException("Not a server"); }
            @Override public void checkClientTrusted(X509Certificate[] chain, String authType, Socket socket) throws CertificateException { throw new CertificateException("Not a server"); }
            @Override public void checkClientTrusted(X509Certificate[] chain, String authType) throws CertificateException { throw new CertificateException("Not a server"); }
            @Override public X509Certificate[] getAcceptedIssuers() { return chains.getAcceptedIssuers(); }
        };
    }

    private static TrustManager[] defaultTrust() throws GeneralSecurityException
    {
        TrustManagerFactory tmf = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
        tmf.init((KeyStore)null);
        return tmf.getTrustManagers();
    }

    /** A key manager with no key, which records whether the server asked for one. */
    private static final class Asked extends X509ExtendedKeyManager
    {
        private final AtomicBoolean asked;

        Asked(AtomicBoolean asked) { this.asked = asked; }

        @Override public String chooseEngineClientAlias(String[] keyType, Principal[] issuers, SSLEngine engine) { asked.set(true); return null; }
        @Override public String chooseClientAlias(String[] keyType, Principal[] issuers, Socket socket) { asked.set(true); return null; }
        @Override public String[] getClientAliases(String keyType, Principal[] issuers) { return null; }
        @Override public String[] getServerAliases(String keyType, Principal[] issuers) { return null; }
        @Override public String chooseServerAlias(String keyType, Principal[] issuers, Socket socket) { return null; }
        @Override public X509Certificate[] getCertificateChain(String alias) { return null; }
        @Override public PrivateKey getPrivateKey(String alias) { return null; }
    }

    /**
     * Returns the deployment's host.
     *
     * @return host
     */
    public String getDeploymentHost()
    {
        return deploymentHost;
    }

    /**
     * Returns the address of the internal proxy.
     *
     * @return host and port
     */
    public InetSocketAddress getProxy()
    {
        return InetSocketAddress.createUnresolved(proxyHost, proxyPort);
    }

}
