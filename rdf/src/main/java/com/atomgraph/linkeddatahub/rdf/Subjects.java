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

package com.atomgraph.linkeddatahub.rdf;

import java.net.URI;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Resource;

/**
 * The subject a description appended to a document is about.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class Subjects
{

    private Subjects() { }

    /**
     * Returns the subject resource for an appended description: the given URI resolved against
     * the target document URI, or a fresh blank node when no URI is given.
     * <p>
     * A blank node is the right default because most appended descriptions - a content block, a
     * query, a chart - are only ever referred to from within the document that carries them, so
     * minting a URI for them would add an identifier nothing dereferences.
     *
     * @param model model to create the resource in
     * @param target target document URI
     * @param uri subject URI, absolute or relative to the target, or null for a blank node
     * @return subject resource
     */
    public static Resource of(Model model, URI target, String uri)
    {
        return uri != null ? model.createResource(target.resolve(uri).toString()) : model.createResource();
    }

}
