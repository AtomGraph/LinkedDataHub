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

package com.atomgraph.linkeddatahub.cli.util;

import com.atomgraph.linkeddatahub.cli.util.PushPlan.Step;
import java.io.IOException;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

/**
 * Tests for {@link PushPlan}: the directory tree to document tree mapping, walk order, and skips.
 */
public class PushPlanTest
{

    static final URI TARGET = URI.create("https://localhost:4443/some/");

    /** Creates a file (and its parent directories) under the root. */
    static Path touch(Path root, String relative) throws IOException
    {
        Path file = root.resolve(relative);
        Files.createDirectories(file.getParent());
        return Files.writeString(file, "");
    }

    /** One line per step: kind, relative path and, for a write, the target. */
    static List<String> describe(List<Step> steps)
    {
        return steps.stream().
            map(step -> step.kind() + " " + step.relative() + (step.target() != null ? " -> " + step.target() : "")).
            toList();
    }

    static List<String> plan(Path root) throws IOException
    {
        return describe(PushPlan.plan(root, TARGET));
    }

    @Test
    public void rootDocumentMapsToTheTargetItself(@TempDir Path root) throws Exception
    {
        touch(root, "root.ttl");

        assertEquals(List.of("DOCUMENT root.ttl -> " + TARGET), plan(root));
    }

    @Test
    public void documentsMapToChildURLsByStem(@TempDir Path root) throws Exception
    {
        touch(root, "a.ttl");
        touch(root, "a/b.ttl");

        assertEquals(List.of("DOCUMENT a.ttl -> " + TARGET + "a/", "DOCUMENT a/b.ttl -> " + TARGET + "a/b/"), plan(root));
    }

    @Test
    public void jenaTellsDocumentsFromUploads(@TempDir Path root) throws Exception
    {
        touch(root, "nt.nt");
        touch(root, "rdf.rdf");
        touch(root, "upper.TTL");
        touch(root, "data.csv");
        touch(root, "query.rq");
        touch(root, "image.png");
        touch(root, "results.srj");

        assertEquals(List.of(
            "DOCUMENT nt.nt -> " + TARGET + "nt/",
            "DOCUMENT rdf.rdf -> " + TARGET + "rdf/",
            "DOCUMENT upper.TTL -> " + TARGET + "upper/",
            "UPLOAD data.csv -> " + TARGET,
            "UPLOAD image.png -> " + TARGET,
            "UPLOAD query.rq -> " + TARGET,
            "UPLOAD results.srj -> " + TARGET), plan(root));

        assertEquals("text/turtle", PushPlan.documentLang("x.ttl").getContentType().getContentTypeStr());
        assertNotNull(PushPlan.documentLang("x.jsonld"));
        assertNull(PushPlan.documentLang("x.csv"), "Jena names CSV but cannot parse it as RDF");
        assertNull(PushPlan.documentLang("x.json"));
    }

    @Test
    public void uploadsTargetTheirDirectorysDocument(@TempDir Path root) throws Exception
    {
        touch(root, "top.png");
        touch(root, "a/image.png");

        assertEquals(List.of("UPLOAD top.png -> " + TARGET, "UPLOAD a/image.png -> " + TARGET + "a/"), plan(root));
    }

    @Test
    public void orderIsRootDocumentThenDocumentsThenUploadsThenSubdirectories(@TempDir Path root) throws Exception
    {
        touch(root, "z.png");
        touch(root, "b.ttl");
        touch(root, "a.ttl");
        touch(root, "root.ttl");
        touch(root, "sub/e.ttl");
        touch(root, "a/d.png");
        touch(root, "a/c.ttl");

        assertEquals(List.of(
            "DOCUMENT root.ttl -> " + TARGET,
            "DOCUMENT a.ttl -> " + TARGET + "a/",
            "DOCUMENT b.ttl -> " + TARGET + "b/",
            "UPLOAD z.png -> " + TARGET,
            "DOCUMENT a/c.ttl -> " + TARGET + "a/c/",
            "UPLOAD a/d.png -> " + TARGET + "a/",
            "DOCUMENT sub/e.ttl -> " + TARGET + "sub/e/"), plan(root));
    }

    @Test
    public void hiddenEntriesProduceNoSteps(@TempDir Path root) throws Exception
    {
        touch(root, ".hidden");
        touch(root, ".git/config");
        touch(root, ".ldhignore");
        touch(root, "a.ttl");

        assertEquals(List.of("DOCUMENT a.ttl -> " + TARGET + "a/"), plan(root));
    }

    @Test
    public void ignoredEntriesAreSkipStepsInWalkOrderAndAnIgnoredDirectoryHasNothingBeneath(@TempDir Path root) throws Exception
    {
        Files.writeString(touch(root, ".ldhignore"), "*.md\nimg/\nb.ttl\n");
        touch(root, "notes.md");
        touch(root, "a.ttl");
        touch(root, "b.ttl");
        touch(root, "img/p.png");

        assertEquals(List.of("DOCUMENT a.ttl -> " + TARGET + "a/", "SKIP b.ttl", "SKIP notes.md", "SKIP img/"), plan(root));
    }

    @Test
    public void ignoreFileAppliesToItsWholeSubtree(@TempDir Path root) throws Exception
    {
        Files.writeString(touch(root, ".ldhignore"), "*.md\n");
        touch(root, "a/b/notes.md");
        touch(root, "a/b/c.ttl");

        assertEquals(List.of("DOCUMENT a/b/c.ttl -> " + TARGET + "a/b/c/", "SKIP a/b/notes.md"), plan(root));
    }

    @Test
    public void nestedIgnoreFileDoesNotLeakToSiblings(@TempDir Path root) throws Exception
    {
        Files.writeString(touch(root, "a/.ldhignore"), "c.ttl\n");
        touch(root, "a/c.ttl");
        touch(root, "b/c.ttl");

        assertEquals(List.of("SKIP a/c.ttl", "DOCUMENT b/c.ttl -> " + TARGET + "b/c/"), plan(root));
    }

    @Test
    public void rootDocumentInASubdirectoryIsAnOrdinaryDocument(@TempDir Path root) throws Exception
    {
        touch(root, "a/root.ttl");

        assertEquals(List.of("DOCUMENT a/root.ttl -> " + TARGET + "a/root/"), plan(root));
    }

    @Test
    public void namesArePercentEncoded(@TempDir Path root) throws Exception
    {
        touch(root, "my dir/x.ttl");
        touch(root, "ö.ttl");

        assertEquals(List.of("DOCUMENT ö.ttl -> " + TARGET + "%C3%B6/", "DOCUMENT my dir/x.ttl -> " + TARGET + "my%20dir/x/"), plan(root));
    }

    @Test
    public void symbolicLinkToADirectoryIsNotFollowedButToAFileIs(@TempDir Path root) throws Exception
    {
        touch(root, "real/x.ttl");
        boolean linked;
        try
        {
            Files.createSymbolicLink(root.resolve("link"), root.resolve("real"));
            Files.createSymbolicLink(root.resolve("y.ttl"), root.resolve("real/x.ttl"));
            linked = true;
        }
        catch (UnsupportedOperationException | IOException | SecurityException ex)
        {
            linked = false;
        }
        assumeTrue(linked, "symbolic links not supported here");

        assertEquals(List.of("DOCUMENT y.ttl -> " + TARGET + "y/", "DOCUMENT real/x.ttl -> " + TARGET + "real/x/"), plan(root));
    }

}
