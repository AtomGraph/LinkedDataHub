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
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.GeneralSecurityException;
import java.security.KeyStore;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.time.Clock;
import java.util.Collections;
import java.util.function.Function;
import java.util.function.Supplier;
import org.apache.jena.fuseki.main.sys.FusekiAutoModule;
import org.apache.jena.sparql.service.ServiceExecutorRegistry;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * The Fuseki module that installs {@link DelegatingServiceExecutor} in the <code>SERVICE</code> chain. Found by
 * Fuseki's <code>ServiceLoader</code> when its jar is on the server's classpath (the image's <code>/fuseki/extra/</code>).
 * <p>
 * Configured from the environment, as the deployment's other services are:
 * <dl>
 *   <dt><code>LDH_DELEGATION_KEYSTORE</code>, <code>LDH_DELEGATION_KEYSTORE_PASSWORD_FILE</code></dt>
 *   <dd>the secretary's PKCS#12 keystore: its certificate checks the markers and its key answers a server that asks
 *       for a client certificate</dd>
 *   <dt><code>LDH_DELEGATION_TRUSTSTORE</code></dt>
 *   <dd>the deployment's server certificate (PEM), trusted for its own origins</dd>
 *   <dt><code>LDH_DELEGATION_HOST</code></dt>
 *   <dd>the deployment's host; it and its subdomains are its own origins</dd>
 *   <dt><code>LDH_DELEGATION_PROXY_HOST</code>, <code>LDH_DELEGATION_PROXY_PORT</code></dt>
 *   <dd>where the own origins are reached from inside the network (nginx's client-certificate listener)</dd>
 * </dl>
 * The keystore is read at the first marked call, not at start: the platform makes it, and starts after the store.
 * Without a keystore configured the module still runs and drops every marker before the call, so a marked query never
 * sends the agent's WebID or the signature to a target.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class DelegationModule implements FusekiAutoModule
{

    private static final Logger log = LoggerFactory.getLogger(DelegationModule.class);

    @Override
    public String name()
    {
        return "LinkedDataHub SERVICE delegation";
    }

    @Override
    public void start()
    {
        String keystore = System.getenv("LDH_DELEGATION_KEYSTORE");
        if (keystore == null || keystore.isBlank())
            log.warn("No LDH_DELEGATION_KEYSTORE: SERVICE calls the platform marked are made anonymously, the marker dropped");
        Supplier<DelegatingServiceExecutor.Delegation> delegation = keystore == null || keystore.isBlank() ? () -> null : new Loaded(System::getenv);
        ServiceExecutorRegistry.get().addSingleLink(new DelegatingServiceExecutor(delegation, Clock.systemUTC()));
    }

    /** The delegation read from the environment once it can be, then kept. */
    static final class Loaded implements Supplier<DelegatingServiceExecutor.Delegation>
    {
        private final Function<String, String> env;
        private volatile DelegatingServiceExecutor.Delegation loaded;

        Loaded(Function<String, String> env)
        {
            this.env = env;
        }

        @Override
        public DelegatingServiceExecutor.Delegation get()
        {
            DelegatingServiceExecutor.Delegation current = loaded;
            if (current != null) return current;
            synchronized (this)
            {
                if (loaded == null) loaded = load();
                return loaded;
            }
        }

        private DelegatingServiceExecutor.Delegation load()
        {
            try
            {
                Path keystore = Path.of(required("LDH_DELEGATION_KEYSTORE"));
                char[] password = Files.readString(Path.of(required("LDH_DELEGATION_KEYSTORE_PASSWORD_FILE")), StandardCharsets.UTF_8).strip().toCharArray();
                KeyStore secretary = KeyStore.getInstance("PKCS12");
                try (InputStream in = Files.newInputStream(keystore))
                {
                    secretary.load(in, password);
                }
                String alias = Collections.list(secretary.aliases()).stream().filter(a -> isKey(secretary, a)).findFirst()
                    .orElseThrow(() -> new GeneralSecurityException("No key in " + keystore));
                X509Certificate server;
                try (InputStream in = Files.newInputStream(Path.of(required("LDH_DELEGATION_TRUSTSTORE"))))
                {
                    server = (X509Certificate)CertificateFactory.getInstance("X.509").generateCertificate(in);
                }
                Routes routes = new Routes(required("LDH_DELEGATION_HOST"), required("LDH_DELEGATION_PROXY_HOST"),
                    Integer.parseInt(required("LDH_DELEGATION_PROXY_PORT")), secretary, password, server);
                X509Certificate certificate = (X509Certificate)secretary.getCertificate(alias);
                log.info("SERVICE calls the platform marked are made on behalf of their agent, as {}, where the target asks for a client certificate",
                    certificate.getSubjectX500Principal());
                return new DelegatingServiceExecutor.Delegation(certificate.getPublicKey(), routes);
            }
            catch (IOException | GeneralSecurityException ex)
            {
                throw new IllegalStateException("the secretary's keystore cannot be read: " + ex.getMessage(), ex);
            }
        }

        private String required(String name)
        {
            String value = env.apply(name);
            if (value == null || value.isBlank()) throw new IllegalStateException(name + " is not set, and LDH_DELEGATION_KEYSTORE is");
            return value;
        }

        private static boolean isKey(KeyStore store, String alias)
        {
            try
            {
                return store.isKeyEntry(alias);
            }
            catch (GeneralSecurityException ex)
            {
                return false;
            }
        }
    }

}
