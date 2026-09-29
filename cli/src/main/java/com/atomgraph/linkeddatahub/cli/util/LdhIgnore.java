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

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.PathMatcher;
import java.util.ArrayList;
import java.util.List;

/**
 * The ignore rules of one directory, read from its <code>.ldhignore</code> file. They apply to the
 * directory's whole subtree, gitignore-style: a pattern without a slash matches an entry's name at
 * any depth, a pattern with a slash matches the path relative to this directory (a leading slash
 * anchors it the same way), and a trailing slash restricts the pattern to directories. Patterns are
 * globs; blank lines and <code>#</code> comments are skipped; negation is not supported.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class LdhIgnore
{

    /** Name of the ignore file */
    public static final String FILE_NAME = ".ldhignore";

    private record Rule(PathMatcher matcher, boolean anchored, boolean dirOnly) { }

    private final Path dir;
    private final List<Rule> rules;

    private LdhIgnore(Path dir, List<Rule> rules)
    {
        this.dir = dir;
        this.rules = rules;
    }

    /**
     * Reads the ignore rules of a directory. A directory without an ignore file has no rules.
     *
     * @param dir directory
     * @return ignore rules
     * @throws IOException read error
     */
    public static LdhIgnore load(Path dir) throws IOException
    {
        Path file = dir.resolve(FILE_NAME);

        return parse(dir, Files.isRegularFile(file) ? Files.readAllLines(file) : List.of());
    }

    /**
     * Parses ignore rules from the lines of an ignore file.
     *
     * @param dir directory the rules belong to
     * @param lines lines of the ignore file
     * @return ignore rules
     */
    public static LdhIgnore parse(Path dir, List<String> lines)
    {
        List<Rule> rules = new ArrayList<>();

        for (String line : lines)
        {
            String pattern = line.strip();
            if (pattern.isEmpty() || pattern.startsWith("#")) continue;

            boolean dirOnly = pattern.endsWith("/");
            if (dirOnly) pattern = pattern.substring(0, pattern.length() - 1);
            boolean anchored = pattern.contains("/");
            if (pattern.startsWith("/")) pattern = pattern.substring(1);
            if (pattern.isEmpty()) continue;

            try
            {
                rules.add(new Rule(dir.getFileSystem().getPathMatcher("glob:" + pattern), anchored, dirOnly));
            }
            catch (IllegalArgumentException ex)
            {
                throw new IllegalArgumentException("Invalid pattern '" + line + "' in " + dir.resolve(FILE_NAME), ex);
            }
        }

        return new LdhIgnore(dir, rules);
    }

    /**
     * Tells whether an entry beneath the directory is ignored.
     *
     * @param path entry path
     * @param directory whether the entry is a directory
     * @return true if ignored
     */
    public boolean ignores(Path path, boolean directory)
    {
        for (Rule rule : rules)
        {
            if (rule.dirOnly() && !directory) continue;

            Path subject = rule.anchored() ? dir.relativize(path) : path.getFileName();
            if (rule.matcher().matches(subject)) return true;
        }

        return false;
    }

    /**
     * Tells whether there are no rules.
     *
     * @return true if empty
     */
    public boolean isEmpty()
    {
        return rules.isEmpty();
    }

    /**
     * Returns the directory the rules belong to.
     *
     * @return directory
     */
    public Path getDir()
    {
        return dir;
    }

}
