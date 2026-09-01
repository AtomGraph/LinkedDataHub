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

import java.util.List;
import java.util.Locale;

/**
 * Picks the language a representation is composed in from the languages a reader accepts.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class LanguageNegotiator
{

    /**
     * Returns the language a representation is composed in: the highest-ranked language the reader accepts that the UI
     * actually provides, falling back to the first supported language when the reader accepts none of them.
     *
     * This is deliberately not the reader's top preference. Asking for German does not make a page German, and reporting
     * the request as the content's language is what put <code>lang="de"</code> on pages written entirely in English.
     *
     * Matching is RFC 4647 Basic Filtering through {@link Locale#filter}, not Lookup. The supported languages are derived
     * from the UI translation bundle and carry region-qualified tags (<code>en-US</code>), while Accept-Language arrives as
     * primary subtags (<code>en</code>). Lookup truncates the range and so returns only tags equal to or less specific than
     * it, which does not match that direction; Basic Filtering does.
     *
     * @param acceptableLanguages the reader's languages, highest priority first
     * @param supportedLanguages the languages the UI provides
     * @return the composition language, never null
     */
    public static Locale negotiate(List<Locale> acceptableLanguages, List<Locale> supportedLanguages)
    {
        if (supportedLanguages.isEmpty()) return Locale.ENGLISH;

        for (Locale acceptable : acceptableLanguages)
        {
            // JAX-RS reports a wildcard Accept-Language as a locale whose language is "*"; it expresses no preference
            if (acceptable.getLanguage().isEmpty() || acceptable.getLanguage().equals("*")) continue;

            List<Locale> matches = Locale.filter(List.of(new Locale.LanguageRange(acceptable.toLanguageTag())), supportedLanguages);
            if (!matches.isEmpty()) return matches.get(0);
        }

        return supportedLanguages.get(0);
    }

}
