/**
 *  Copyright 2021 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.io;

import com.apicatalog.jsonld.JsonLdOptions;
import java.io.InputStream;
import java.io.Reader;
import java.io.StringReader;
import org.apache.jena.atlas.web.ContentType;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFParser;
import org.apache.jena.riot.ReaderRIOTBase;
import org.apache.jena.riot.RiotParseException;
import org.apache.jena.riot.lang.LangJSONLD11;
import org.apache.jena.riot.system.StreamRDF;
import org.apache.jena.sparql.util.Context;
import org.apache.jena.util.FileUtils;
import org.jsoup.nodes.Document;
import org.jsoup.parser.Parser;
import org.jsoup.select.Elements;

/**
 * JSON-LD-in-HTML reader.
 * Extracts <code>&lt;script type="application/ld+json"&gt;</code> elements from the HTML input
 * and delegates each JSON-LD payload to Jena's stock {@link Lang#JSONLD11} reader (Titanium-backed).
 * Can be used to read schema.org data.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class HtmlJsonLDReader extends ReaderRIOTBase
{

    private final JsonLdOptions options;

    /**
     * Constructs JSON-LD-in-HTML reader without options.
     */
    public HtmlJsonLDReader()
    {
        this(null);
    }

    /**
     * Constructs JSON-LD-in-HTML reader with options.
     *
     * @param options Titanium JSON-LD options
     */
    public HtmlJsonLDReader(JsonLdOptions options)
    {
        this.options = options;
    }

    @Override
    public void read(InputStream in, String baseURI, Lang lang, StreamRDF output, Context context)
    {
        read(FileUtils.asBufferedUTF8(in), baseURI, output, context);
    }

    @Override
    public void read(Reader in, String baseURI, ContentType ct, StreamRDF output, Context context)
    {
        read(in, baseURI, output, context);
    }

    /**
     * Reads JSON-LD data from the HTML <code>&lt;script&gt;</code> element.
     *
     * @param in HTML input stream
     * @param baseURI base URI
     * @param output RDF output stream
     * @param context JSON-LD reader context
     */
    public void read(Reader in, String baseURI, StreamRDF output, Context context)
    {
        Document html = Parser.htmlParser().parseInput(in, baseURI);
        Elements jsonLdElements = html.selectXpath("/html//script[@type = 'application/ld+json']");

        if (jsonLdElements.isEmpty()) throw new RiotParseException("<script> element with type=\"application/ld+json\" not found",  -1,  -1);

        if (getJsonLdOptions() != null) context.set(LangJSONLD11.JSONLD_OPTIONS, getJsonLdOptions());

        jsonLdElements.stream().map(element -> element.data()).forEach(jsonLd ->
            RDFParser.create().
                source(new StringReader(jsonLd)).
                lang(Lang.JSONLD11).
                base(baseURI).
                context(context).
                parse(output));
    }

    /**
     * Returns JSON-LD reader options.
     *
     * @return reader options
     */
    public JsonLdOptions getJsonLdOptions()
    {
        return options;
    }

}
