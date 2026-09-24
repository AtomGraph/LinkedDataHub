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

import jakarta.ws.rs.core.EntityTag;
import java.io.ByteArrayOutputStream;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFDataMgr;

/**
 * Entity tags for RDF graphs, and the canonical serialization they are taken over.
 *
 * The tag is a digest of the graph URI and the graph's triples. Content-derived, because the
 * alternatives do not hold here: <code>If-Match</code> uses the strong comparison function, so a
 * mandatory precondition needs a validator that changes whenever the representation does; graphs are
 * written by paths that bypass the document resource, so a stored revision would desynchronize; and
 * there is no store for per-document server state to keep one in.
 *
 * What it is NOT is a hash the holder can compute or relate to another. The tag is handed to agents
 * who may not read the graph: <code>HEAD</code> is answered for any access mode, so that an agent
 * with <code>acl:Append</code> and no <code>acl:Read</code> - a dropbox depositor - can obtain the
 * validator its writes have to quote. Two properties follow from that:
 *
 * <ul>
 * <li>the graph URI is digested with the content, so the same triples in two documents do not share
 * a tag, and a guess cannot be materialized somewhere readable and compared;</li>
 * <li>the digest is not linear in the set of triples. An XOR fold is: appending a triple moves the
 * tag by a value the appender can compute, which turns a dropbox into a membership oracle - append
 * a triple, see whether the tag moved by its hash, learn whether it was already there. A set gains
 * nothing when you add a member it already has, and that is the leak.</li>
 * </ul>
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class EntityTags
{

    /** Digest algorithm the validator is taken with */
    public static final String DIGEST_ALGORITHM = "SHA-256";
    /** Bytes of digest kept, rendered as hex. 16 gives a 32-character tag */
    public static final int TAG_BYTES = 16;

    /**
     * Returns the entity tag of a graph.
     *
     * The value is lowercase hex and nothing else: it is parsed back as a {@link java.math.BigInteger}
     * and added to downstream - by the variant and acceptable-language folding in the internal
     * response, and by the per-agent perturbation in the XSLT writers.
     *
     * @param graphURI the graph's URI, digested with the content so tags are not comparable across documents
     * @param model the graph
     * @return entity tag
     */
    public static EntityTag entityTag(URI graphURI, Model model)
    {
        try
        {
            MessageDigest digest = MessageDigest.getInstance(DIGEST_ALGORITHM); // per call: MessageDigest is not thread-safe
            digest.update(graphURI.toString().getBytes(StandardCharsets.UTF_8));
            digest.update((byte)0); // separator, so a URI ending in the first triple's bytes cannot collide with a shorter one
            digest.update(toSortedNTriples(model));

            byte[] hash = digest.digest();
            StringBuilder hex = new StringBuilder(TAG_BYTES * 2);
            for (int i = 0; i < TAG_BYTES; i++) hex.append(String.format("%02x", hash[i]));

            return new EntityTag(hex.toString());
        }
        catch (NoSuchAlgorithmException ex)
        {
            throw new IllegalStateException(DIGEST_ALGORITHM + " is required of every JVM", ex);
        }
    }

    /**
     * Serializes a model as N-Triples with sorted lines, so successive serializations
     * of the same graph are byte-identical and git diffs are minimal.
     *
     * Canonical only because the graphs this writes are blank-node-free: every write through the
     * document resource skolemizes. Jena's <code>_:bN</code> labels are not stable across reads, so a
     * stored blank node would serialize differently each time - a different entity tag on every read,
     * and a conditional request that can never be satisfied.
     *
     * @param model the model
     * @return sorted N-Triples bytes
     */
    public static byte[] toSortedNTriples(Model model)
    {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        RDFDataMgr.write(out, model, Lang.NTRIPLES);

        String[] lines = out.toString(StandardCharsets.UTF_8).split("\n");
        Arrays.sort(lines);

        StringBuilder sorted = new StringBuilder();
        for (String line : lines)
            if (!line.isBlank()) sorted.append(line.stripTrailing()).append('\n');

        return sorted.toString().getBytes(StandardCharsets.UTF_8);
    }

}
