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

import java.io.IOException;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.nio.file.FileAlreadyExistsException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.nio.file.StandardOpenOption;
import java.util.List;
import java.util.Optional;
import java.util.regex.Pattern;

/**
 * What the platform itself records of an upload, beside its bytes in the upload folder: the media type it was first
 * uploaded with, and the documents it was uploaded into.
 * <p>
 * An upload's description is merged from every graph that states something of its URI, so neither can be read from
 * it: any writer of any document could add a <code>dct:format</code> to someone else's upload, and every document is
 * free to mention it (formal/uploads, <code>any_writer_describes_any_upload</code>). These records are written only
 * when a write that uploads the bytes goes ahead. The media type is kept like the bytes, first writer wins; a document
 * is added each time the same bytes are uploaded into it, which takes having the bytes.
 * <p>
 * Both live in subfolders of the upload folder, <code>.types/</code> and <code>.documents/</code>, named by the
 * digest like the file. No URI addresses them: an upload is <code>uploads/{sha1sum}</code>, a single segment.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public final class UploadRecords
{

    /** A digest the upload folder names a file by. */
    public static final Pattern SHA1 = Pattern.compile("[0-9a-f]{40}");

    private static final String TYPES = ".types";
    private static final String DOCUMENTS = ".documents";

    private UploadRecords()
    {
    }

    /**
     * Records an upload that a write has gone ahead with: its media type, unless one is recorded already, and the
     * document it was uploaded into.
     *
     * @param uploadFolder upload folder
     * @param sha1 digest of the bytes
     * @param mediaType media type the bytes were uploaded with
     * @param document document the write uploaded them into
     * @throws IOException if a record cannot be written
     */
    public static void record(Path uploadFolder, String sha1, String mediaType, URI document) throws IOException
    {
        Path type = uploadFolder.resolve(TYPES).resolve(sha1);
        if (!Files.exists(type))
        {
            Files.createDirectories(type.getParent());
            Path temp = Files.createTempFile(type.getParent(), ".type-", ".tmp");
            try
            {
                Files.writeString(temp, mediaType, StandardCharsets.UTF_8);
                // no REPLACE_EXISTING: when two uploads of the same bytes race, the first one's type stays
                Files.move(temp, type, StandardCopyOption.ATOMIC_MOVE);
            }
            catch (FileAlreadyExistsException ex)
            {
                // recorded by a concurrent upload of the same bytes
            }
            finally
            {
                Files.deleteIfExists(temp);
            }
        }

        if (!getDocuments(uploadFolder, sha1).contains(document))
        {
            Path documents = uploadFolder.resolve(DOCUMENTS).resolve(sha1);
            Files.createDirectories(documents.getParent());
            Files.writeString(documents, document + "\n", StandardCharsets.UTF_8, StandardOpenOption.CREATE, StandardOpenOption.APPEND);
        }
    }

    /**
     * Returns the media type an upload was first uploaded with.
     *
     * @param uploadFolder upload folder
     * @param sha1 digest of the bytes
     * @return media type, empty for an upload made before it was recorded
     * @throws IOException if the record cannot be read
     */
    public static Optional<String> getMediaType(Path uploadFolder, String sha1) throws IOException
    {
        Path type = uploadFolder.resolve(TYPES).resolve(sha1);
        if (!Files.exists(type)) return Optional.empty();

        return Optional.of(Files.readString(type, StandardCharsets.UTF_8).trim()).filter(t -> !t.isEmpty());
    }

    /**
     * Returns the documents an upload was uploaded into.
     *
     * @param uploadFolder upload folder
     * @param sha1 digest of the bytes
     * @return document URIs, empty for an upload made before they were recorded
     * @throws IOException if the record cannot be read
     */
    public static List<URI> getDocuments(Path uploadFolder, String sha1) throws IOException
    {
        Path documents = uploadFolder.resolve(DOCUMENTS).resolve(sha1);
        if (!Files.exists(documents)) return List.of();

        return Files.readAllLines(documents, StandardCharsets.UTF_8).stream().
            filter(line -> !line.isBlank()).
            map(URI::create).
            distinct().
            toList();
    }

}
