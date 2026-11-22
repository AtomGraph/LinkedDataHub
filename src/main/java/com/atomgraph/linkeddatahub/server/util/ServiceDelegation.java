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
package com.atomgraph.linkeddatahub.server.util;

import java.net.URLDecoder;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.PrivateKey;
import java.security.Signature;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;

/**
 * The marker the platform writes on a <code>SERVICE</code> IRI so the triplestore can make the call on behalf of the
 * agent who asked the query: {@value #ON_BEHALF_OF} (the agent's WebID), {@value #EXPIRES} (seconds since the epoch) and
 * {@value #SIGNATURE} (base64url, {@value #ALGORITHM} with the secretary's private key over {@link #canonical}).
 * <p>
 * The triplestore's side is LinkedDataHub's Fuseki module (<code>fuseki-module/</code>,
 * <code>com.atomgraph.linkeddatahub.fuseki.ServiceDelegation</code>), which checks the signature against the
 * secretary's certificate, removes the marker, and makes the call as the secretary with <code>On-Behalf-Of</code>
 * naming the agent - to an endpoint that asks for a client certificate, and anonymously to any other. The two sides
 * share the format through a test vector.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class ServiceDelegation
{

    /** The parameter carrying the agent's WebID */
    public static final String ON_BEHALF_OF = "ldh-on-behalf-of";
    /** The parameter carrying the marker's expiry, in seconds since the epoch */
    public static final String EXPIRES = "ldh-expires";
    /** The parameter carrying the signature */
    public static final String SIGNATURE = "ldh-signature";
    /** The prefix of every parameter the marker owns */
    public static final String PREFIX = "ldh-";
    /** The signature algorithm */
    public static final String ALGORITHM = "SHA256withRSA";

    private ServiceDelegation() { }

    /**
     * Returns the string the signature is over: the target, the agent and the expiry, one per line.
     *
     * @param target the <code>SERVICE</code> IRI without the marker's parameters
     * @param agent the agent's WebID
     * @param expires the expiry in seconds since the epoch
     * @return the signed string
     */
    public static String canonical(String target, String agent, long expires)
    {
        return target + "\n" + agent + "\n" + expires;
    }

    /**
     * Returns the IRI without the marker's parameters, every other parameter kept as written and in order. A query
     * author cannot supply a marker: every one is removed before the platform writes its own.
     *
     * @param iri a <code>SERVICE</code> IRI
     * @return the IRI without parameters starting with {@value #PREFIX}
     */
    public static String strip(String iri)
    {
        int q = iri.indexOf('?');
        if (q < 0) return iri;
        int hash = iri.indexOf('#', q);
        String query = hash < 0 ? iri.substring(q + 1) : iri.substring(q + 1, hash), fragment = hash < 0 ? "" : iri.substring(hash);
        List<String> kept = new ArrayList<>();
        for (String pair : query.split("&"))
        {
            int eq = pair.indexOf('=');
            String name = URLDecoder.decode(eq < 0 ? pair : pair.substring(0, eq), StandardCharsets.UTF_8);
            if (!pair.isEmpty() && !name.startsWith(PREFIX)) kept.add(pair);
        }
        return iri.substring(0, q) + (kept.isEmpty() ? "" : "?" + String.join("&", kept)) + fragment;
    }

    /**
     * Returns the target marked with the agent: its parameters with the marker's appended.
     *
     * @param target the <code>SERVICE</code> IRI, without a marker
     * @param agent the agent's WebID
     * @param expires when the marker expires
     * @param key the secretary's private key
     * @return the marked IRI
     * @throws IllegalStateException if the key cannot sign
     */
    public static String mark(String target, String agent, Instant expires, PrivateKey key)
    {
        try
        {
            Signature signer = Signature.getInstance(ALGORITHM);
            signer.initSign(key);
            signer.update(canonical(target, agent, expires.getEpochSecond()).getBytes(StandardCharsets.UTF_8));
            String signature = Base64.getUrlEncoder().withoutPadding().encodeToString(signer.sign());
            int hash = target.indexOf('#');
            String base = hash < 0 ? target : target.substring(0, hash), fragment = hash < 0 ? "" : target.substring(hash);
            return base + (base.contains("?") ? "&" : "?") +
                ON_BEHALF_OF + "=" + URLEncoder.encode(agent, StandardCharsets.UTF_8) + "&" +
                EXPIRES + "=" + expires.getEpochSecond() + "&" +
                SIGNATURE + "=" + signature + fragment;
        }
        catch (GeneralSecurityException ex)
        {
            throw new IllegalStateException("Could not sign the SERVICE delegation marker", ex);
        }
    }

}
