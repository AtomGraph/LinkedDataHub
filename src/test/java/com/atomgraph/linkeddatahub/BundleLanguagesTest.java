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
package com.atomgraph.linkeddatahub;

import com.atomgraph.linkeddatahub.server.util.LanguageNegotiator;
import com.atomgraph.linkeddatahub.writer.XSLTWriterBase;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Locale;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;

/**
 * Tests that the supported UI languages are derived from the translation bundle rather than declared separately.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class BundleLanguagesTest
{

    /** The shipped bundle, read from the webapp source tree rather than through a servlet context. */
    public static final Path TRANSLATIONS = Path.of("src/main/webapp", XSLTWriterBase.TRANSLATIONS_PATH);

    @Test
    public void testShippedBundle() throws IOException
    {
        try (InputStream is = Files.newInputStream(TRANSLATIONS))
        {
            List<Locale> languages = Application.readBundleLanguages(is);

            // the bundle is tagged with full BCP 47 tags, not primary subtags - the retired config said "en,es"
            assertEquals(List.of(Locale.forLanguageTag("en-US"), Locale.forLanguageTag("es-ES")), languages);
        }
    }

    /**
     * A language counts as supported only if the bundle carries labels in it. This is the property the derivation exists to
     * guarantee, and the one a hand-maintained config cannot.
     */
    @Test
    public void testOnlyLanguagesPresentAreReported()
    {
        String bundle = """
            <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
              <rdf:Description rdf:nodeID="save">
                <rdfs:label xml:lang="en-US">Save</rdfs:label>
                <rdfs:label xml:lang="es-ES">Guardar</rdfs:label>
              </rdf:Description>
              <rdf:Description rdf:nodeID="close">
                <rdfs:label xml:lang="en-US">Close</rdfs:label>
              </rdf:Description>
            </rdf:RDF>
            """;

        List<Locale> languages = Application.readBundleLanguages(new ByteArrayInputStream(bundle.getBytes(StandardCharsets.UTF_8)));

        // es-ES appears once and is still reported: partial coverage still counts, the missing keys fall back per-key
        assertEquals(List.of(Locale.forLanguageTag("en-US"), Locale.forLanguageTag("es-ES")), languages);
    }

    /** Untagged labels contribute no language - they are not a language the UI can be rendered in. */
    @Test
    public void testUntaggedLabelsIgnored()
    {
        String bundle = """
            <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
              <rdf:Description rdf:nodeID="save">
                <rdfs:label>Save</rdfs:label>
                <rdfs:label xml:lang="en-US">Save</rdfs:label>
              </rdf:Description>
            </rdf:RDF>
            """;

        List<Locale> languages = Application.readBundleLanguages(new ByteArrayInputStream(bundle.getBytes(StandardCharsets.UTF_8)));

        assertEquals(List.of(Locale.forLanguageTag("en-US")), languages);
    }

    /**
     * The derived tags are region-qualified (<code>en-US</code>) while Accept-Language arrives as primary subtags
     * (<code>en</code>), so matching must be RFC 4647 <em>Basic Filtering</em>, not Lookup.
     *
     * Lookup truncates the <em>range</em> and so only ever returns a tag equal to or less specific than it: the range
     * <code>en</code> does not match the tag <code>en-US</code>, and <code>Locale.lookupTag</code> returns null for exactly
     * the case we need. Basic Filtering matches in the direction the bundle requires.
     */
    @Test
    public void testPrimarySubtagMatchesRegionQualifiedBundleTag() throws IOException
    {
        try (InputStream is = Files.newInputStream(TRANSLATIONS))
        {
            List<Locale> bundle = Application.readBundleLanguages(is);

            assertEquals("en-US", firstMatch("en", bundle));
            assertEquals("es-ES", firstMatch("es", bundle));
            assertEquals("en-US", firstMatch("en-US,en;q=0.9,da;q=0.8,lt;q=0.7", bundle));
            // preference order is honoured, not just membership
            assertEquals("es-ES", firstMatch("es,en;q=0.9", bundle));
            // a reader whose languages the bundle has none of gets no match, and the caller falls back
            assertEquals(null, firstMatch("lt,de;q=0.9", bundle));

            // Lookup would fail this, which is why it is not what the effective-language computation uses
            assertTrue(Locale.lookupTag(Locale.LanguageRange.parse("en"), bundle.stream().map(Locale::toLanguageTag).toList()) == null);
        }
    }

    /** RFC 4647 Basic Filtering, taking the highest-priority match. */
    private static String firstMatch(String acceptLanguage, List<Locale> bundle)
    {
        List<Locale> matches = Locale.filter(Locale.LanguageRange.parse(acceptLanguage), bundle);

        return matches.isEmpty() ? null : matches.get(0).toLanguageTag();
    }

    /**
     * The effective language is what the page is composed in, not what the reader asked for. These are the cases that were
     * wrong before: a reader asking for a language the bundle lacks got that language reported anyway.
     */
    @Test
    public void testEffectiveLanguage()
    {
        List<Locale> bundle = List.of(Locale.forLanguageTag("en-US"), Locale.forLanguageTag("es-ES"));

        // primary subtag matches the region-qualified bundle tag
        assertEquals("en-US", effective("en", bundle));
        assertEquals("es-ES", effective("es", bundle));

        // a real browser header: en wins because it is the first accepted language the bundle has
        assertEquals("en-US", effective("en-US,en;q=0.9,da;q=0.8,lt;q=0.7", bundle));

        // Lithuanian first, but the bundle has no Lithuanian - the page is composed in the next language it does have
        assertEquals("en-US", effective("lt,en-US;q=0.9,en;q=0.8", bundle));

        // preference order is honoured over bundle order
        assertEquals("es-ES", effective("es,en;q=0.9", bundle));

        // none of the reader's languages are available: fall back rather than report a language the page is not in.
        // This is the lang="de" bug - "de" used to be reported for this request
        assertEquals("en-US", effective("de,fr;q=0.9", bundle));

        // no preference expressed at all
        assertEquals("en-US", LanguageNegotiator.negotiate(List.of(), bundle).toLanguageTag());
    }

    /** With no bundle there is nothing to compose in; English is the documented floor rather than an empty header. */
    @Test
    public void testEffectiveLanguageWithoutBundle()
    {
        assertEquals(Locale.ENGLISH, LanguageNegotiator.negotiate(List.of(Locale.forLanguageTag("lt")), List.of()));
    }

    /**
     * What goes on the wire is not the bundle key. BCP 47 says a region subtag "MAY be omitted, as when it adds no
     * distinguishing value to the tag" (RFC 5646 section 2.2.4), and the region in en-US records how translations.rdf is
     * keyed rather than a claim that the page is American English.
     */
    @Test
    public void testPublishedTagDropsAnUndistinguishingRegion()
    {
        List<Locale> bundle = List.of(Locale.forLanguageTag("en-US"), Locale.forLanguageTag("es-ES"));

        assertEquals("en", published("en-US,en;q=0.9,da;q=0.8,lt;q=0.7", bundle));
        assertEquals("es", published("es", bundle));
        assertEquals("en", published("lt,en;q=0.9", bundle));
        assertEquals("en", published("de,fr;q=0.9", bundle));
        assertEquals("en", LanguageNegotiator.publishedTag(List.of(), bundle));

        // and with no bundle at all, still a tag rather than an empty header
        assertEquals("en", LanguageNegotiator.publishedTag(List.of(Locale.forLanguageTag("lt")), List.of()));
    }

    /**
     * Where the bundle really does distinguish two variants of one language, the region carries information and stays. This
     * is what a blanket Locale#getLanguage would get wrong.
     */
    @Test
    public void testPublishedTagKeepsADistinguishingRegion()
    {
        List<Locale> bundle = List.of(Locale.forLanguageTag("pt-BR"), Locale.forLanguageTag("pt-PT"), Locale.forLanguageTag("en-US"));

        assertEquals("pt-BR", published("pt-BR", bundle));
        assertEquals("pt-PT", published("pt-PT", bundle));
        // English is unambiguous in the same bundle, so it still loses its region
        assertEquals("en", published("en", bundle));
    }

    /**
     * The cost of over-specifying, in RFC 4647 terms: a reader asking for es-MX reaches a page tagged es by truncating their
     * own range under Lookup, and never reaches one tagged es-ES.
     */
    @Test
    public void testShorterTagStaysReachableForOtherRegions()
    {
        List<String> overSpecified = List.of("es-ES");
        List<String> published = List.of("es");

        assertEquals(null, Locale.lookupTag(Locale.LanguageRange.parse("es-MX"), overSpecified));
        assertEquals("es", Locale.lookupTag(Locale.LanguageRange.parse("es-MX"), published));
    }

    private static String published(String acceptLanguage, List<Locale> bundle)
    {
        List<Locale> acceptable = Locale.LanguageRange.parse(acceptLanguage).stream().
            map(range -> Locale.forLanguageTag(range.getRange())).
            toList();

        return LanguageNegotiator.publishedTag(acceptable, bundle);
    }

    private static String effective(String acceptLanguage, List<Locale> bundle)
    {
        List<Locale> acceptable = Locale.LanguageRange.parse(acceptLanguage).stream().
            map(range -> Locale.forLanguageTag(range.getRange())).
            toList();

        return LanguageNegotiator.negotiate(acceptable, bundle).toLanguageTag();
    }

}
