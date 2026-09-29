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

import com.atomgraph.linkeddatahub.rdf.vocabulary.A;
import com.atomgraph.linkeddatahub.rdf.vocabulary.SD;
import java.net.URI;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;

/**
 * SPARQL service descriptions - the endpoints a dataspace can query and write.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class Services
{

    private Services() { }

    /**
     * Builds a generic SPARQL service description.
     *
     * @param target target document URI
     * @param uri service URI, relative or absolute (optional, blank node when absent)
     * @param title service title
     * @param endpoint SPARQL endpoint URI
     * @param graphStore Graph Store Protocol endpoint URI (optional)
     * @param authUser HTTP Basic auth user name (optional)
     * @param authPwd HTTP Basic auth password (optional)
     * @param description service description (optional)
     * @return service model
     */
    public static Model service(URI target, String uri, String title, URI endpoint, URI graphStore, String authUser, String authPwd, String description)
    {
        Model model = ModelFactory.createDefaultModel();

        Resource service = Subjects.of(model, target, uri).
            addProperty(RDF.type, SD.Service).
            addProperty(DCTerms.title, title).
            addProperty(SD.endpoint, model.createResource(endpoint.toString())).
            addProperty(SD.supportedLanguage, SD.SPARQL11Query).
            addProperty(SD.supportedLanguage, SD.SPARQL11Update);
        if (graphStore != null) service.addProperty(A.graphStore, model.createResource(graphStore.toString()));
        if (authUser != null) service.addProperty(A.authUser, authUser);
        if (authPwd != null) service.addProperty(A.authPwd, authPwd);
        if (description != null) service.addProperty(DCTerms.description, description);

        return model;
    }

}
