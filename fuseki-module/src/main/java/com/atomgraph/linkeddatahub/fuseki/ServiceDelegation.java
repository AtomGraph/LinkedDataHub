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

import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.PublicKey;
import java.security.Signature;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Optional;

/**
 * The marker the platform writes on a <code>SERVICE</code> IRI to say who asked the query, and its check.
 * <p>
 * The platform knows the agent who sent a query to its endpoint; the store that runs the query does not, and opens the
 * <code>SERVICE</code> call itself. So the platform appends three parameters to each <code>SERVICE</code> IRI before the
 * query goes to the store: {@value #ON_BEHALF_OF} (the agent's WebID), {@value #EXPIRES} (seconds since the epoch) and
 * {@value #SIGNATURE} (base64url, {@value #ALGORITHM} with the secretary's private key over {@link #canonical}). ARQ
 * keeps a query string already on a <code>SERVICE</code> IRI, so the marker reaches this module, which checks it against
 * the secretary's certificate, removes it, and calls the target as the secretary on the agent's behalf
 * ({@link DelegatingServiceExecutor}). The signature is what lets the store trust the marker: anything that can send the
 * store a query - not only the platform - could write the parameters, but only the platform holds the key.
 * <p>
 * The platform writes the same format (<code>com.atomgraph.linkeddatahub.server.util.ServiceDelegation</code>); the
 * two are kept in step by a shared test vector.
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
     * A <code>SERVICE</code> IRI as the platform marked it.
     *
     * @param target the IRI without the marker's parameters: what is called
     * @param agent the agent's WebID
     * @param expires when the marker expires
     * @param signature the signature over {@link #canonical}
     */
    public record Marked(URI target, URI agent, Instant expires, byte[] signature) { }

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
     * Returns the IRI without the marker's parameters, every other parameter kept as written and in order.
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
            if (!pair.isEmpty() && !name(pair).startsWith(PREFIX)) kept.add(pair);
        return iri.substring(0, q) + (kept.isEmpty() ? "" : "?" + String.join("&", kept)) + fragment;
    }

    /**
     * Returns the marker of a <code>SERVICE</code> IRI, or nothing if it carries none. A partial marker is no marker
     * to trust and is refused.
     *
     * @param iri a <code>SERVICE</code> IRI
     * @return the marker, or empty
     * @throws IllegalArgumentException if the IRI carries some of the marker's parameters but not all, or malformed ones
     */
    public static Optional<Marked> parse(String iri)
    {
        int q = iri.indexOf('?');
        if (q < 0) return Optional.empty();
        int hash = iri.indexOf('#', q);
        String query = hash < 0 ? iri.substring(q + 1) : iri.substring(q + 1, hash);
        String agent = null, expires = null, signature = null;
        boolean any = false;
        for (String pair : query.split("&"))
        {
            String name = name(pair);
            if (!name.startsWith(PREFIX)) continue;
            any = true;
            String value = pair.contains("=") ? URLDecoder.decode(pair.substring(pair.indexOf('=') + 1), StandardCharsets.UTF_8) : "";
            switch (name)
            {
                case ON_BEHALF_OF -> agent = value;
                case EXPIRES -> expires = value;
                case SIGNATURE -> signature = value;
                default -> throw new IllegalArgumentException("Unknown delegation parameter: " + name);
            }
        }
        if (!any) return Optional.empty();
        if (agent == null || expires == null || signature == null) throw new IllegalArgumentException("Incomplete delegation marker on <" + strip(iri) + ">");
        try
        {
            return Optional.of(new Marked(URI.create(strip(iri)), URI.create(agent), Instant.ofEpochSecond(Long.parseLong(expires)),
                Base64.getUrlDecoder().decode(signature)));
        }
        catch (IllegalArgumentException ex) // NumberFormatException included
        {
            throw new IllegalArgumentException("Malformed delegation marker on <" + strip(iri) + ">", ex);
        }
    }

    /**
     * Returns whether the marker was signed by the holder of the key and has not expired.
     *
     * @param marked the marker
     * @param key the secretary's public key
     * @param now the current time
     * @return true if it holds
     */
    public static boolean verify(Marked marked, PublicKey key, Instant now)
    {
        if (!now.isBefore(marked.expires())) return false;
        try
        {
            Signature verifier = Signature.getInstance(ALGORITHM);
            verifier.initVerify(key);
            verifier.update(canonical(marked.target().toString(), marked.agent().toString(), marked.expires().getEpochSecond()).getBytes(StandardCharsets.UTF_8));
            return verifier.verify(marked.signature());
        }
        catch (GeneralSecurityException ex)
        {
            return false;
        }
    }

    private static String name(String pair)
    {
        int eq = pair.indexOf('=');
        return URLDecoder.decode(eq < 0 ? pair : pair.substring(0, eq), StandardCharsets.UTF_8);
    }

}
