/**
 *  Copyright 2025 Martynas Jusevičius <martynas@atomgraph.com>
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

import com.apicatalog.jsonld.JsonLdError;
import com.apicatalog.jsonld.document.Document;
import com.apicatalog.jsonld.document.JsonDocument;
import com.apicatalog.jsonld.loader.DocumentLoader;
import com.apicatalog.jsonld.loader.DocumentLoaderOptions;
import com.apicatalog.jsonld.loader.SchemeRouter;
import java.io.StringReader;
import java.net.URI;
import java.util.Set;

/**
 * Titanium {@link DocumentLoader} that serves the bundled schema.org JSON-LD <code>@context</code> document
 * locally for the <code>http://schema.org</code> and <code>https://schema.org</code> URIs, and delegates
 * everything else to {@link SchemeRouter#defaultInstance()} (which performs remote HTTP(S) and file fetches).
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class SchemaOrgDocumentLoader implements DocumentLoader
{

    private static final Set<URI> SCHEMA_ORG = Set.of(
            URI.create("http://schema.org"),
            URI.create("https://schema.org"));

    private final JsonDocument schemaOrgContext;
    private final DocumentLoader fallback;

    /**
     * Constructs the loader with the schema.org JSON-LD context document and {@link SchemeRouter#defaultInstance()} as the fallback.
     *
     * @param schemaOrgJson the schema.org JSON-LD context as a JSON string
     * @throws JsonLdError if the JSON cannot be parsed
     */
    public SchemaOrgDocumentLoader(String schemaOrgJson) throws JsonLdError
    {
        this(schemaOrgJson, SchemeRouter.defaultInstance());
    }

    /**
     * Constructs the loader with an explicit fallback {@link DocumentLoader}.
     *
     * @param schemaOrgJson the schema.org JSON-LD context as a JSON string
     * @param fallback the loader used for URIs other than schema.org
     * @throws JsonLdError if the JSON cannot be parsed
     */
    public SchemaOrgDocumentLoader(String schemaOrgJson, DocumentLoader fallback) throws JsonLdError
    {
        this.schemaOrgContext = JsonDocument.of(new StringReader(schemaOrgJson));
        this.fallback = fallback;
    }

    @Override
    public Document loadDocument(URI url, DocumentLoaderOptions options) throws JsonLdError
    {
        if (SCHEMA_ORG.contains(url)) return schemaOrgContext;
        return fallback.loadDocument(url, options);
    }

}
