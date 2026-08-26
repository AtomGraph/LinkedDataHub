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

import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Property;
import org.apache.jena.rdf.model.RDFNode;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.rdf.model.StmtIterator;
import org.apache.jena.vocabulary.RDF;

/**
 * RDF container membership property (<code>rdf:_N</code>) helpers for content blocks.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class SequenceNumbers
{

    private SequenceNumbers() { }

    /**
     * Returns the next free membership property <code>rdf:_(max + 1)</code> for the given subject,
     * where <code>max</code> is the highest existing <code>rdf:_N</code> predicate (0 if none).
     *
     * @param model model with the subject's description
     * @param subject resource whose membership properties are scanned
     * @return next membership property
     */
    public static Property nextSequenceProperty(Model model, Resource subject)
    {
        String prefix = RDF.getURI() + "_";
        int max = 0;

        StmtIterator it = model.listStatements(subject, null, (RDFNode)null);
        try
        {
            while (it.hasNext())
            {
                String uri = it.next().getPredicate().getURI();
                if (uri.startsWith(prefix))
                    try
                    {
                        max = Math.max(max, Integer.parseInt(uri.substring(prefix.length())));
                    }
                    catch (NumberFormatException ex)
                    {
                        // not a membership property, e.g. rdf:_x
                    }
            }
        }
        finally
        {
            it.close();
        }

        return ResourceFactory.createProperty(prefix + (max + 1));
    }

}
