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
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.Deque;
import java.util.List;
import java.util.stream.Stream;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFLanguages;
import org.apache.jena.riot.RDFParserRegistry;

/**
 * Maps a directory tree onto a document tree. A file Jena can parse as RDF is a document: the one
 * named <code>root</code> at the top of the tree describes the target document itself, any other
 * <code>name.ext</code> in a directory describes the child document <code>name/</code> of that
 * directory's document. Every other file is uploaded into its directory's document. Subdirectory
 * <code>name</code> maps to that same child document <code>name/</code>, so a directory's document
 * is described by the RDF file beside it. Hidden entries are dropped, ignored ones (see
 * {@link LdhIgnore}) are reported as skipped.
 *
 * Within a directory the order is the root document, then documents, then uploads, then
 * subdirectories, each group sorted by name, so a subdirectory's document exists before anything is
 * uploaded into it.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class PushPlan
{

    /** Stem of the file at the top of the tree that describes the target document itself */
    public static final String ROOT_STEM = "root";

    /** What a step does with its file */
    public enum Kind { DOCUMENT, UPLOAD, SKIP }

    /**
     * One entry of the plan.
     *
     * @param kind what happens to the file
     * @param file absolute path of the entry
     * @param relative path of the entry relative to the pushed directory, slash-separated, with a
     * trailing slash for a directory
     * @param target the document written (<code>DOCUMENT</code>) or appended to (<code>UPLOAD</code>), null when skipped
     * @param contentType RDF media type of a document, null otherwise
     */
    public record Step(Kind kind, Path file, String relative, URI target, String contentType) { }

    private PushPlan() { }

    /**
     * Plans the push of a directory into a document.
     *
     * @param root pushed directory (absolute)
     * @param target URI of the document the directory maps to
     * @return steps in execution order
     * @throws IOException directory read error
     */
    public static List<Step> plan(Path root, URI target) throws IOException
    {
        List<Step> steps = new ArrayList<>();
        walk(root, target, root, new ArrayDeque<>(), steps);
        return steps;
    }

    /**
     * Returns the RDF syntax of a file, told by its name, if Jena can parse it.
     *
     * @param fileName file name
     * @return RDF language, or null when the file is not an RDF document
     */
    public static Lang documentLang(String fileName)
    {
        Lang lang = RDFLanguages.filenameToLang(fileName);

        return lang != null && RDFParserRegistry.isRegistered(lang) ? lang : null;
    }

    private static void walk(Path dir, URI url, Path root, Deque<LdhIgnore> ignores, List<Step> steps) throws IOException
    {
        LdhIgnore ignore = LdhIgnore.load(dir);
        if (!ignore.isEmpty()) ignores.push(ignore);

        try
        {
            List<Path> entries;
            try (Stream<Path> list = Files.list(dir))
            {
                entries = list.filter(entry -> !entry.getFileName().toString().startsWith(".")).
                    sorted(Comparator.comparing(entry -> entry.getFileName().toString())).
                    toList();
            }

            List<Path> documents = new ArrayList<>(), uploads = new ArrayList<>(), dirs = new ArrayList<>();
            for (Path entry : entries)
            {
                // a symbolic link to a directory is neither, and is dropped
                if (Files.isDirectory(entry, LinkOption.NOFOLLOW_LINKS)) dirs.add(entry);
                else if (Files.isRegularFile(entry)) (documentLang(entry.getFileName().toString()) != null ? documents : uploads).add(entry);
            }

            documents.sort(Comparator.comparing((Path doc) -> !isRootDocument(doc, root)));
            for (Path doc : documents)
            {
                if (isIgnored(doc, false, ignores)) steps.add(skip(doc, root, false));
                else
                {
                    String name = doc.getFileName().toString();
                    URI docURI = isRootDocument(doc, root) ? url : URIRewriter.childURI(url, stem(name));
                    steps.add(new Step(Kind.DOCUMENT, doc, relative(doc, root, false), docURI, documentLang(name).getContentType().getContentTypeStr()));
                }
            }

            for (Path upload : uploads)
                steps.add(isIgnored(upload, false, ignores) ? skip(upload, root, false) : new Step(Kind.UPLOAD, upload, relative(upload, root, false), url, null));

            for (Path subdir : dirs)
            {
                if (isIgnored(subdir, true, ignores)) steps.add(skip(subdir, root, true));
                else walk(subdir, URIRewriter.childURI(url, subdir.getFileName().toString()), root, ignores, steps);
            }
        }
        finally
        {
            if (!ignore.isEmpty()) ignores.pop();
        }
    }

    private static boolean isRootDocument(Path doc, Path root)
    {
        return doc.getParent().equals(root) && ROOT_STEM.equals(stem(doc.getFileName().toString()));
    }

    private static boolean isIgnored(Path entry, boolean directory, Deque<LdhIgnore> ignores)
    {
        return ignores.stream().anyMatch(ignore -> ignore.ignores(entry, directory));
    }

    private static Step skip(Path entry, Path root, boolean directory)
    {
        return new Step(Kind.SKIP, entry, relative(entry, root, directory), null, null);
    }

    private static String relative(Path entry, Path root, boolean directory)
    {
        StringBuilder sb = new StringBuilder();
        for (Path segment : root.relativize(entry))
        {
            if (sb.length() > 0) sb.append('/');
            sb.append(segment);
        }
        if (directory) sb.append('/');

        return sb.toString();
    }

    private static String stem(String fileName)
    {
        int dot = fileName.lastIndexOf('.');

        return dot > 0 ? fileName.substring(0, dot) : fileName;
    }

}
