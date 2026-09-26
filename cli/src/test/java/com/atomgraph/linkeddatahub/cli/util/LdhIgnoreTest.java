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

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Tests for {@link LdhIgnore}: the gitignore-style semantics of an <code>.ldhignore</code> file.
 */
public class LdhIgnoreTest
{

    static final Path DIR = Path.of("/app").toAbsolutePath();

    static LdhIgnore ignore(String... lines)
    {
        return LdhIgnore.parse(DIR, List.of(lines));
    }

    @Test
    public void blankLinesAndCommentsAreIgnored()
    {
        assertTrue(ignore("", "   ", "# a comment", "#root.ttl").isEmpty());
        assertFalse(ignore("root.ttl").isEmpty());
    }

    @Test
    public void basenamePatternMatchesAtAnyDepth()
    {
        LdhIgnore ignore = ignore("*.sh", "Makefile");

        assertTrue(ignore.ignores(DIR.resolve("install.sh"), false));
        assertTrue(ignore.ignores(DIR.resolve("a/b/import-csv.sh"), false));
        assertTrue(ignore.ignores(DIR.resolve("x/Makefile"), false));
        assertFalse(ignore.ignores(DIR.resolve("x/Makefile.txt"), false));
        assertFalse(ignore.ignores(DIR.resolve("a.ttl"), false));
    }

    @Test
    public void slashPatternIsRelativeToTheIgnoreFilesDirectory()
    {
        LdhIgnore ignore = ignore("categories/unesco-mappings.ttl", "/root.ttl");

        assertTrue(ignore.ignores(DIR.resolve("categories/unesco-mappings.ttl"), false));
        assertFalse(ignore.ignores(DIR.resolve("x/categories/unesco-mappings.ttl"), false));
        assertFalse(ignore.ignores(DIR.resolve("unesco-mappings.ttl"), false));
        assertTrue(ignore.ignores(DIR.resolve("root.ttl"), false));
        assertFalse(ignore.ignores(DIR.resolve("a/root.ttl"), false));
    }

    @Test
    public void trailingSlashRestrictsToDirectories()
    {
        LdhIgnore ignore = ignore("admin/");

        assertTrue(ignore.ignores(DIR.resolve("admin"), true));
        assertTrue(ignore.ignores(DIR.resolve("x/admin"), true));
        assertFalse(ignore.ignores(DIR.resolve("admin"), false));
    }

    @Test
    public void globWildcardsWork()
    {
        LdhIgnore ignore = ignore("screenshot*.png", "[ab].ttl", "docs/**/*.md");

        assertTrue(ignore.ignores(DIR.resolve("screenshot-edit-mode.png"), false));
        assertTrue(ignore.ignores(DIR.resolve("a.ttl"), false));
        assertFalse(ignore.ignores(DIR.resolve("c.ttl"), false));
        assertTrue(ignore.ignores(DIR.resolve("docs/x/y.md"), false));
        assertFalse(ignore.ignores(DIR.resolve("other/x/y.md"), false));
    }

    @Test
    public void loadReturnsNoRulesWhenTheFileIsAbsent(@TempDir Path tmp) throws Exception
    {
        assertTrue(LdhIgnore.load(tmp).isEmpty());

        Files.writeString(tmp.resolve(LdhIgnore.FILE_NAME), "# generated\n*.md\n");
        LdhIgnore ignore = LdhIgnore.load(tmp);

        assertFalse(ignore.isEmpty());
        assertTrue(ignore.ignores(tmp.resolve("notes.md"), false));
    }

}
