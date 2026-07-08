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

package com.atomgraph.linkeddatahub.cli.command.content;

import com.atomgraph.linkeddatahub.cli.BaseCommand;
import com.atomgraph.linkeddatahub.cli.http.HttpException;
import com.atomgraph.linkeddatahub.cli.mixin.BaseMixin;
import com.atomgraph.linkeddatahub.cli.util.SequenceNumbers;
import com.atomgraph.linkeddatahub.cli.vocab.LDH;
import jakarta.ws.rs.core.Response;
import java.net.URI;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Property;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;
import picocli.CommandLine.Command;
import picocli.CommandLine.Mixin;
import picocli.CommandLine.Option;
import picocli.CommandLine.Parameters;

/**
 * Appends an XHTML content block to a document. Mirrors <code>bin/content/add-xhtml-block.sh</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "add-xhtml-block", description = "Appends an XHTML content block to a document.")
public class AddXHTMLBlock extends BaseCommand
{

    @Mixin
    private BaseMixin baseMixin; // accepted for script interface parity, unused

    @Option(names = "--value", required = true, paramLabel = "XHTML", description = "XHTML content (must be well-formed XML)")
    private String value;

    @Option(names = "--title", paramLabel = "TITLE", description = "Title of the block (optional)")
    private String title;

    @Option(names = "--description", paramLabel = "DESCRIPTION", description = "Description of the block (optional)")
    private String description;

    @Option(names = "--uri", paramLabel = "URI", description = "URI of the block (optional, blank node if not set)")
    private String uri;

    @Parameters(paramLabel = "TARGET_URI", description = "URI of the document")
    private URI target;

    @Override
    public Integer call() throws Exception
    {
        Model current;
        try (Response response = HttpException.check(target, getClient().get(target, ACCEPT_NTRIPLES)))
        {
            current = response.readEntity(Model.class);
        }
        Property seq = SequenceNumbers.nextSequenceProperty(current, ResourceFactory.createResource(target.toString()));

        post(getClient(), target, buildModel(target, seq, uri, value, title, description));
        print(target);

        return 0;
    }

    /**
     * Builds the XHTML block description.
     *
     * @param target target document URI
     * @param seq membership property (<code>rdf:_N</code>)
     * @param uri block URI (optional)
     * @param value XHTML content
     * @param title block title (optional)
     * @param description block description (optional)
     * @return block model
     */
    public static Model buildModel(URI target, Property seq, String uri, String value, String title, String description)
    {
        Model model = ModelFactory.createDefaultModel();

        Resource block = createSubject(model, target, uri).
            addProperty(RDF.type, LDH.XHTML).
            addProperty(RDF.value, model.createTypedLiteral(value, RDF.dtXMLLiteral));
        model.createResource(target.toString()).addProperty(seq, block);
        if (title != null) block.addProperty(DCTerms.title, title);
        if (description != null) block.addProperty(DCTerms.description, description);

        return model;
    }

}
