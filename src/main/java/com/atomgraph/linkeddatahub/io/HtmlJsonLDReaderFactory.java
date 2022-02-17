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

import com.atomgraph.core.MediaType;
import com.github.jsonldjava.core.JsonLdOptions;
import org.apache.jena.atlas.lib.InternalErrorException;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.LangBuilder;
import org.apache.jena.riot.ReaderRIOT;
import org.apache.jena.riot.ReaderRIOTFactory;
import org.apache.jena.riot.system.ParserProfile;

/**
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class HtmlJsonLDReaderFactory implements ReaderRIOTFactory
{
    
    private final JsonLDReader jsonLDReader;
    private final JsonLdOptions options;

    // TO-DO: move to RDFLanguages
    public static final Lang HTML = LangBuilder.create("HTML", MediaType.TEXT_HTML).
            addFileExtensions("html").
            build();
    
    public HtmlJsonLDReaderFactory(JsonLDReader jsonLDReader)
    {
        this(jsonLDReader, null);
    }
    
    public HtmlJsonLDReaderFactory(JsonLDReader jsonLDReader, JsonLdOptions options)
    {
        this.jsonLDReader = jsonLDReader;
        this.options = options;
    }
    
    @Override
    public ReaderRIOT create(Lang lang, ParserProfile profile) 
    {
        if ( !HTML.equals(lang) )
            throw new InternalErrorException("Attempt to parse " + lang + " as HTML");
        
        return new HtmlJsonLDReader(getJsonLDReader(), getJsonLdOptions());
    }

    public JsonLDReader getJsonLDReader()
    {
        return jsonLDReader;
    }
    
    public JsonLdOptions getJsonLdOptions()
    {
        return options;
    }
    
}
