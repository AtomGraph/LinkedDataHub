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

package com.atomgraph.linkeddatahub.cli.command;

import com.atomgraph.linkeddatahub.cli.BaseCommand;
import com.atomgraph.linkeddatahub.cli.http.HttpException;
import com.atomgraph.linkeddatahub.cli.http.LDHClient;
import com.atomgraph.linkeddatahub.cli.mixin.BaseMixin;
import com.atomgraph.linkeddatahub.cli.util.Digests;
import com.atomgraph.linkeddatahub.cli.vocab.NFO;
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.core.MediaType;
import java.io.IOException;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Path;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;
import org.glassfish.jersey.media.multipart.FormDataMultiPart;
import org.glassfish.jersey.media.multipart.file.FileDataBodyPart;
import picocli.CommandLine.Command;
import picocli.CommandLine.Mixin;
import picocli.CommandLine.Option;
import picocli.CommandLine.Parameters;

/**
 * Uploads a file using the RDF/POST multipart encoding. Mirrors <code>bin/add-file.sh</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "add-file", description = "Uploads a file.")
public class AddFile extends BaseCommand
{

    @Mixin
    private BaseMixin baseMixin;

    @Option(names = "--title", required = true, paramLabel = "TITLE", description = "Title of the file")
    private String title;

    @Option(names = "--description", paramLabel = "DESCRIPTION", description = "Description of the file (optional)")
    private String description;

    @Option(names = "--file", required = true, paramLabel = "ABS_PATH", description = "Path to the file")
    private Path file;

    @Option(names = "--content-type", paramLabel = "MEDIA_TYPE", description = "Media type of the file (optional, auto-detected if not set)")
    private String contentType;

    @Parameters(paramLabel = "TARGET_URI", description = "URI of the document")
    private URI target;

    @Override
    public Integer call() throws Exception
    {
        URI base = baseMixin.require(getSpec());

        URI fileURI = core(getClient(), base, target, file, contentType, title, description);
        print(fileURI);

        return 0;
    }

    /**
     * Uploads the file to the target document and returns its content-addressed upload URI.
     * The RDF/POST field order is positional: each <code>pu</code> must immediately precede
     * its <code>ol</code>/<code>ou</code> value.
     *
     * @param client client instance
     * @param base application base URI
     * @param target target document URI
     * @param file file path
     * @param contentType file media type (optional, auto-detected if null)
     * @param title file title
     * @param description file description (optional)
     * @return upload URI derived from the SHA1 hash of the file content
     * @throws IOException file read error
     */
    public static URI core(LDHClient client, URI base, URI target, Path file, String contentType, String title, String description) throws IOException
    {
        String fileContentType = contentType != null ? contentType : detectContentType(file);

        try (FormDataMultiPart multiPart = buildMultiPart(file, fileContentType, title, description))
        {
            HttpException.check(target, client.post(target, Entity.entity(multiPart, multiPart.getMediaType()), ACCEPT_TURTLE)).close();
        }

        return URI.create(base.toString() + "uploads/" + Digests.sha1Hex(file));
    }

    /**
     * Builds the RDF/POST multipart body.
     *
     * @param file file path
     * @param contentType file media type
     * @param title file title
     * @param description file description (optional)
     * @return multipart body
     */
    public static FormDataMultiPart buildMultiPart(Path file, String contentType, String title, String description)
    {
        FormDataMultiPart multiPart = new FormDataMultiPart();

        multiPart.field("rdf", "");
        multiPart.field("sb", "file");
        multiPart.field("pu", NFO.fileName.getURI());
        multiPart.bodyPart(new FileDataBodyPart("ol", file.toFile(), MediaType.valueOf(contentType)));
        multiPart.field("pu", DCTerms.title.getURI());
        multiPart.field("ol", title);
        multiPart.field("pu", RDF.type.getURI());
        multiPart.field("ou", NFO.FileDataObject.getURI());
        if (description != null)
        {
            multiPart.field("pu", DCTerms.description.getURI());
            multiPart.field("ol", description);
        }

        return multiPart;
    }

    static String detectContentType(Path file) throws IOException
    {
        String detected = Files.probeContentType(file);
        return detected != null ? detected : "application/octet-stream";
    }

}
