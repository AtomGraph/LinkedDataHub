/**
 *  Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */
package com.atomgraph.linkeddatahub.server.util;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.stream.Collectors;
import net.sf.saxon.s9api.Processor;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import static com.atomgraph.linkeddatahub.server.util.PackageContract.AC_NS;
import static com.atomgraph.linkeddatahub.server.util.PackageContract.IXSL_NS;
import static com.atomgraph.linkeddatahub.server.util.PackageContract.LDH_NS;
import static com.atomgraph.linkeddatahub.server.util.PackageContract.UNNAMED_MODE;
import static com.atomgraph.linkeddatahub.server.util.PackageContract.clark;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The package contract against a small platform laid out the way the real one is: the Web-Client layer, then the
 * composition marker and the open modes below it, then the sealed modules. Each package probe breaks one rule, or keeps
 * all of them, so a rule that stops being enforced fails its own test.
 */
public class PackageContractTest
{

    private static final String NAMESPACES =
        "xmlns:xsl=\"http://www.w3.org/1999/XSL/Transform\" " +
        "xmlns:ixsl=\"" + IXSL_NS + "\" " +
        "xmlns:ldh=\"" + LDH_NS + "\" " +
        "xmlns:ac=\"" + AC_NS + "\" " +
        "xmlns:pkg=\"https://example.org/package#\"";

    @TempDir
    static Path platform;

    static PackageContract contract;

    @BeforeAll
    public static void platform() throws IOException
    {
        write("entry.xsl",
            "<xsl:import href=\"webclient.xsl\"/>" +
            "<xsl:import href=\"hooks.xsl\"/>" +
            "<xsl:import href=\"sealed.xsl\"/>" +
            "<xsl:include href=\"included.xsl\"/>");
        // below the marker: not open, though packages outrank it
        write("webclient.xsl",
            "<xsl:template match=\"*\" mode=\"ac:label\"><xsl:value-of select=\"ldh:href(.)\"/></xsl:template>" +
            "<xsl:template match=\"*\" mode=\"ac:FieldShell\"/>");
        // the marker: open modes, their fallbacks, and the value tier it imports
        write("hooks.xsl",
            "<xsl:import href=\"values.xsl\"/>" +
            "<xsl:mode name=\"ldh:TreeNode\"/>" +
            "<xsl:mode name=\"ldh:DrawerSections\" on-no-match=\"deep-skip\" ldh:collecting=\"true\"/>" +
            "<xsl:template match=\"*\" mode=\"ldh:TreeNode\"><li/></xsl:template>");
        write("values.xsl",
            "<xsl:template match=\"@rdf:resource\" xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"><a/></xsl:template>");
        // sealed: the platform's own code acts on the page and reads, which is its business
        write("sealed.xsl",
            "<xsl:mode name=\"ldh:Sealed\"/>" +
            "<xsl:mode name=\"ldh:RowHook\" on-no-match=\"deep-skip\"/>" +
            "<xsl:function name=\"ldh:href\"><xsl:param name=\"x\"/><xsl:sequence select=\"ixsl:call(ixsl:window(), 'decodeURIComponent', [ $x ])\"/></xsl:function>" +
            "<xsl:function name=\"ldh:render\" ixsl:updating=\"yes\"><xsl:param name=\"e\"/><xsl:for-each select=\"$e\"><ixsl:set-attribute name=\"class\" select=\"'x'\"/></xsl:for-each></xsl:function>" +
            "<xsl:function name=\"ldh:labels\"><xsl:sequence select=\"document('https://localhost/sparql')\"/></xsl:function>" +
            "<xsl:template name=\"ldh:Label\"><xsl:apply-templates select=\".\" mode=\"ac:label\"/></xsl:template>" +
            "<xsl:template match=\"button\" mode=\"ixsl:onclick\"><ixsl:set-attribute name=\"inert\" select=\"''\"/></xsl:template>");
        write("included.xsl",
            "<xsl:template match=\"*\" mode=\"ldh:Included\"/>");

        contract = PackageContract.fromPlatform(new Processor(false), List.of(platform.resolve("entry.xsl").toUri().toURL()));
    }

    // THE PLATFORM SIDE

    @Test
    public void testOpenModesAreTheMarkersAndBelow()
    {
        assertTrue(contract.getOpenModes().contains(clark(LDH_NS, "TreeNode")));
        assertTrue(contract.getOpenModes().contains(clark(LDH_NS, "DrawerSections")));
        assertTrue(contract.getOpenModes().contains(UNNAMED_MODE), "the value tier's mode-less rules open the unnamed mode");
        assertFalse(contract.getOpenModes().contains(clark(AC_NS, "label")), "the Web-Client layer is not open");
        assertFalse(contract.getOpenModes().contains(clark(LDH_NS, "Sealed")));
        assertFalse(contract.getOpenModes().contains(clark(LDH_NS, "RowHook")), "declared above the marker");
        assertFalse(contract.getOpenModes().contains(clark(LDH_NS, "Included")));
    }

    @Test
    public void testCollectingModesAreMarked()
    {
        assertEquals(java.util.Set.of(clark(LDH_NS, "DrawerSections")), contract.getCollectingModes());
    }

    // THE PACKAGE SIDE

    @Test
    public void testKeepingPackagePasses() throws Exception
    {
        // calls into the platform are free: a rule with no ixsl: and no I/O can only compute with what they return
        assertEquals(List.of(), check(
            "<xsl:template match=\"*[@about]\" mode=\"ldh:TreeNode\"><li><xsl:value-of select=\"pkg:href(@about)\"/></li><xsl:next-match/></xsl:template>" +
            "<xsl:template match=\"@rdf:resource\" xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"><a href=\"{ldh:href(.)}\"><xsl:apply-templates select=\"..\" mode=\"ac:label\"/></a></xsl:template>" +
            "<xsl:template match=\"div\" mode=\"ldh:DrawerSections\"><div class=\"sb-section\"/><xsl:next-match/></xsl:template>" +
            "<xsl:function name=\"pkg:href\"><xsl:param name=\"x\"/><xsl:sequence select=\"ldh:href($x), ldh:labels()\"/></xsl:function>" +
            "<xsl:template name=\"pkg:Children\"><xsl:call-template name=\"ldh:Label\"/></xsl:template>" +
            "<xsl:template name=\"pkg:Query\" use-when=\"system-property('xsl:product-name') = 'SaxonJS'\"><xsl:sequence select=\"map{ 'parent-properties': xs:anyURI('urn:p') }\" xmlns:xs=\"http://www.w3.org/2001/XMLSchema\"/></xsl:template>" +
            "<xsl:variable name=\"pkg:query\" select=\"'SELECT * { ?s ?p ?o } # doc() ixsl:page()'\"/>"));
    }

    @Test
    public void testModes() throws Exception
    {
        assertRules(List.of("modes"), "<xsl:template match=\"*\" mode=\"ac:label\"/>");
        assertRules(List.of("modes"), "<xsl:template match=\"*\" mode=\"ldh:Sealed\"/>");
        assertRules(List.of("modes"), "<xsl:template match=\"*\" mode=\"ldh:RowHook\"><xsl:next-match/></xsl:template>");
        assertRules(List.of("modes"), "<xsl:template match=\"*\" mode=\"#all\"/>");
        assertRules(List.of("modes", "ixsl"), "<xsl:template match=\"button\" mode=\"ixsl:onclick\"><ixsl:set-attribute name=\"x\" select=\"1\"/></xsl:template>");
        assertRules(List.of(), "<xsl:template match=\"*\"/>");
    }

    @Test
    public void testNames() throws Exception
    {
        assertRules(List.of("names"), "<xsl:function name=\"ldh:own\"><xsl:sequence select=\"1\"/></xsl:function>");
        assertRules(List.of("names"), "<xsl:template name=\"unprefixed\"/>");
        assertRules(List.of("names"), "<xsl:variable name=\"ac:x\" select=\"1\"/>");
        assertRules(List.of("names"), "<xsl:key name=\"resources\" match=\"*\" use=\"@about\"/>");
    }

    @Test
    public void testGlobals() throws Exception
    {
        assertRules(List.of("globals"), "<xsl:output method=\"text\"/>");
        assertRules(List.of("globals"), "<xsl:strip-space elements=\"*\"/>");
        assertRules(List.of("globals"), "<xsl:mode name=\"ldh:TreeNode\" on-no-match=\"shallow-copy\"/>");
        assertRules(List.of("globals"), "<xsl:mode on-no-match=\"shallow-copy\"/>");
        assertRules(List.of(), "<xsl:mode name=\"pkg:Walk\"/>");
    }

    @Test
    public void testImports() throws Exception
    {
        assertRules(List.of("imports"), "<xsl:import href=\"other.xsl\"/>");
        assertRules(List.of("imports"), "<xsl:include href=\"other.xsl\"/>");
    }

    @Test
    public void testIxsl() throws Exception
    {
        // instructions
        assertRules(List.of("ixsl"), "<xsl:template name=\"pkg:T\"><ixsl:set-style name=\"display\" select=\"'none'\"/></xsl:template>");
        assertRules(List.of("ixsl"), "<xsl:template name=\"pkg:T\"><ixsl:schedule-action wait=\"1\"><xsl:call-template name=\"pkg:T\"/></ixsl:schedule-action></xsl:template>");
        assertRules(List.of("ixsl"), "<xsl:template name=\"pkg:T\"><ixsl:promise select=\"()\"/></xsl:template>");
        // attributes
        assertRules(List.of("ixsl"), "<xsl:function name=\"pkg:f\" ixsl:updating=\"yes\"><xsl:sequence select=\"()\"/></xsl:function>");
        // functions, reading as well as writing: the whole namespace
        assertRules(List.of("ixsl"), "<xsl:variable name=\"pkg:v\" select=\"ixsl:page()//div\"/>");
        assertRules(List.of("ixsl"), "<xsl:variable name=\"pkg:v\" select=\"ixsl:get(ixsl:window(), 'navigator.languages')\"/>");
        assertRules(List.of("ixsl"), "<xsl:template name=\"pkg:T\"><xsl:sequence select=\"$e => ixsl:call('remove', [])\"/></xsl:template>");
        assertRules(List.of("ixsl"), "<xsl:template name=\"pkg:T\"><xsl:sequence select=\"ixsl:http-request(map{})\"/></xsl:template>");
        assertRules(List.of("ixsl"), "<xsl:template name=\"pkg:T\"><xsl:sequence select=\"ixsl:resolve(()) => ixsl:then(pkg:f#1)\"/></xsl:template>");
        assertRules(List.of("ixsl"), "<xsl:variable name=\"pkg:v\" select=\"Q{" + IXSL_NS + "}page()\"/>");
        assertRules(List.of("ixsl"), "<xsl:variable name=\"pkg:v\" select=\"i:page()\" xmlns:i=\"" + IXSL_NS + "\"/>");
        // a guard on the product is not ixsl:
        assertRules(List.of(), "<xsl:template name=\"pkg:T\" use-when=\"system-property('xsl:product-name') = 'SaxonJS'\"/>");
    }

    @Test
    public void testIo() throws Exception
    {
        assertRules(List.of("io"), "<xsl:template name=\"pkg:T\"><xsl:result-document href=\"#tab-bar\"/></xsl:template>");
        assertRules(List.of("io"), "<xsl:variable name=\"pkg:v\" select=\"doc('http://169.254.169.254/')\"/>");
        assertRules(List.of("io"), "<xsl:variable name=\"pkg:v\" select=\"document('translations.rdf')\"/>");
        assertRules(List.of("io"), "<xsl:variable name=\"pkg:v\" select=\"Q{http://www.w3.org/2005/xpath-functions}unparsed-text('/etc/passwd')\"/>");
        assertRules(List.of("io"), "<xsl:variable name=\"pkg:v\" select=\"fn:environment-variable('SECRET')\" xmlns:fn=\"http://www.w3.org/2005/xpath-functions\"/>");
        assertRules(List.of("io"), "<xsl:variable name=\"pkg:v\" select=\"doc#1\"/>");
        assertRules(List.of("io"), "<xsl:template name=\"pkg:T\"><a href=\"{doc('x')}\"/></xsl:template>");
        assertRules(List.of("io"), "<xsl:template name=\"pkg:T\" expand-text=\"yes\"><p>{json-doc('x')}</p></xsl:template>");
        assertRules(List.of(), "<xsl:template name=\"pkg:T\"><p>{doc('x')}</p></xsl:template>"); // no text value templates without expand-text
        assertRules(List.of(), "<xsl:variable name=\"pkg:v\" select=\"'doc(x)', (: doc('x') :) 1\"/>");
    }

    @Test
    public void testDynamic() throws Exception
    {
        assertRules(List.of("dynamic"), "<xsl:variable name=\"pkg:v\" select=\"function-lookup(xs:QName('fn:doc'), 1)\" xmlns:xs=\"http://www.w3.org/2001/XMLSchema\"/>");
        assertRules(List.of("dynamic"), "<xsl:template name=\"pkg:T\"><xsl:evaluate xpath=\"'doc(1)'\"/></xsl:template>");
        assertRules(List.of("dynamic"), "<xsl:template name=\"pkg:T\"><xsl:sequence _select=\"{$pkg:expr}\"/></xsl:template>");
    }

    @Test
    public void testIds() throws Exception
    {
        assertRules(List.of("ids"), "<xsl:template name=\"pkg:T\"><div id=\"tab-content\"/></xsl:template>");
        assertRules(List.of("ids"), "<xsl:template name=\"pkg:T\"><div><xsl:attribute name=\"id\" select=\"'x'\"/></div></xsl:template>");
    }

    @Test
    public void testCollectingModeRuleMustEndWithNextMatch() throws Exception
    {
        assertRules(List.of("collecting"), "<xsl:template match=\"div\" mode=\"ldh:DrawerSections\"><xsl:sequence select=\"()\"/></xsl:template>");
        assertRules(List.of("collecting"), "<xsl:template match=\"div\" mode=\"ldh:DrawerSections\"><xsl:next-match/><xsl:sequence select=\"()\"/></xsl:template>");
        assertRules(List.of(), "<xsl:template match=\"div\" mode=\"ldh:DrawerSections\"><xsl:param name=\"p\"/><xsl:sequence select=\"()\"/><xsl:next-match/></xsl:template>");
        assertRules(List.of(), "<xsl:template match=\"div\" mode=\"ldh:TreeNode\"><li/></xsl:template>"); // replacing, not collecting
    }

    @Test
    public void testLineNumbers() throws Exception
    {
        List<PackageContract.Violation> violations = check("\n\n<xsl:output method=\"text\"/>");
        assertEquals(3, violations.get(0).line());
    }

    // LEXING

    @Test
    public void testNames_skipVariablesAxesStringsAndComments()
    {
        assertEquals(List.of("doc", "ldh:f", "Q{urn:x}g", "ixsl:then"), PackageContract.names(
            "$doc, child::text(), 'doc(1)', \"x(\" , (: doc() :) doc ('a'), ldh:f#2, Q{urn:x}g(), $p => ixsl:then(1)")
            .stream().filter(n -> !n.equals("text")).collect(Collectors.toList()));
        assertEquals(List.of(), PackageContract.names("$a/doc[1] , 1e5, @doc"));
        assertEquals(List.of("unparsed-text"), PackageContract.names("map{'a': unparsed-text('b')}"), "map{ is not a call; what is inside it is");
    }

    @Test
    public void testAvt()
    {
        assertEquals(List.of("a", " map{'b': 1} "), PackageContract.avt("x{a}{{y}}{ map{'b': 1} }z"));
        assertEquals(List.of(), PackageContract.avt("{{literal}}"));
        assertEquals(List.of("'}'"), PackageContract.avt("{'}'}"));
    }

    // HELPERS

    private static void assertRules(List<String> expected, String declarations) throws Exception
    {
        List<PackageContract.Violation> violations = check(declarations);
        assertEquals(expected, violations.stream().map(PackageContract.Violation::rule).distinct().collect(Collectors.toList()), violations.toString());
    }

    private static List<PackageContract.Violation> check(String declarations) throws Exception
    {
        Path file = Files.createTempFile(platform, "package", ".xsl");
        Files.writeString(file, stylesheet(declarations), StandardCharsets.UTF_8);
        return contract.check(file.toUri().toURL());
    }

    private static void write(String name, String declarations) throws IOException
    {
        Files.writeString(platform.resolve(name), stylesheet(declarations), StandardCharsets.UTF_8);
    }

    private static String stylesheet(String declarations)
    {
        return "<xsl:stylesheet version=\"3.0\" " + NAMESPACES + ">" + declarations + "</xsl:stylesheet>";
    }

}
