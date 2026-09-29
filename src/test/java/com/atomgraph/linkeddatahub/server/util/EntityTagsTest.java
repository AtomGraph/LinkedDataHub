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
import java.math.BigInteger;
import java.net.URI;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;

/**
 * The properties the entity tag is relied on for, and the two it is required NOT to have.
 *
 * The tag is handed to agents who may not read the graph it describes: HEAD is answered for any
 * access mode so that an agent with acl:Append and no acl:Read can obtain the validator its writes
 * have to quote. Everything below the first two assertions is about what such an agent must not be
 * able to work out from it.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class EntityTagsTest
{

    private static final URI GRAPH = URI.create("https://localhost:4443/inbox/");
    private static final URI OTHER_GRAPH = URI.create("https://localhost:4443/elsewhere/");

    private static Model modelOf(String... objects)
    {
        Model model = ModelFactory.createDefaultModel();
        Resource subject = model.createResource("https://localhost:4443/inbox/#review");
        for (String object : objects) subject.addProperty(model.createProperty("https://localhost:4443/ns#outcome"), object);
        return model;
    }

    private static BigInteger value(EntityTag tag)
    {
        return new BigInteger(tag.getValue(), 16);
    }

    @Test
    public void sameGraphAndContentGivesTheSameTag() // 304 revalidation and the GET -> If-Match -> write handshake need this
    {
        assertEquals(EntityTags.entityTag(GRAPH, modelOf("approved")), EntityTags.entityTag(GRAPH, modelOf("approved")));
    }

    @Test
    public void changedContentGivesADifferentTag()
    {
        assertNotEquals(EntityTags.entityTag(GRAPH, modelOf("approved")), EntityTags.entityTag(GRAPH, modelOf("rejected")));
    }

    @Test
    public void statementOrderDoesNotMatter() // the serialization is sorted, so two readings of one graph agree
    {
        Model forwards = modelOf("approved", "pending");
        Model backwards = modelOf("pending", "approved");

        assertEquals(EntityTags.entityTag(GRAPH, forwards), EntityTags.entityTag(GRAPH, backwards));
    }

    @Test
    public void identicalContentInTwoGraphsDoesNotShareATag()
    {
        // otherwise an agent that may write but not read could materialize a guess in a document it
        // CAN read, compare the two tags, and confirm the content of the one it cannot
        assertNotEquals(EntityTags.entityTag(GRAPH, modelOf("approved")), EntityTags.entityTag(OTHER_GRAPH, modelOf("approved")));
    }

    @Test
    public void addingATripleDoesNotMoveTheTagPredictably()
    {
        // The leak this replaces: with a hash that XOR-folds per-triple hashes, the tag is LINEAR in
        // the set of triples, and linearity satisfies
        //
        //     tag(G+a) (x) tag(G+b)  ==  tag(G) (x) tag(G+a+b)
        //
        // because both sides reduce to hash(a) (x) hash(b). An appender can therefore add a triple,
        // look at how far the tag moved, and learn whether it was already there - a set gains nothing
        // when you add a member it already has. That is a membership oracle over a document the
        // appender may not read, using only acl:Append. A digest satisfies the identity only by
        // coincidence, which is what this asserts.
        Model base = modelOf("approved");
        Model withA = modelOf("approved", "a");
        Model withB = modelOf("approved", "b");
        Model withBoth = modelOf("approved", "a", "b");

        BigInteger left = value(EntityTags.entityTag(GRAPH, withA)).xor(value(EntityTags.entityTag(GRAPH, withB)));
        BigInteger right = value(EntityTags.entityTag(GRAPH, base)).xor(value(EntityTags.entityTag(GRAPH, withBoth)));

        assertNotEquals(left, right, "the tag is linear in the triple set, which makes it a membership oracle");
    }

    @Test
    public void theTagIsLowercaseHex()
    {
        // it is parsed back as a BigInteger and added to downstream: by the variant and
        // acceptable-language folding in the internal response, and by the per-agent perturbation in
        // the XSLT writers. Anything but hex throws there.
        String tag = EntityTags.entityTag(GRAPH, modelOf("approved")).getValue();

        assertTrue(tag.matches("[0-9a-f]{32}"), "expected 32 lowercase hex characters, got '" + tag + "'");
        value(EntityTags.entityTag(GRAPH, modelOf("approved"))); // throws if it is not parseable
    }

}
