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

import com.atomgraph.linkeddatahub.rdf.vocabulary.ACL;
import com.atomgraph.linkeddatahub.rdf.vocabulary.DH;
import java.net.URI;
import java.util.List;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Property;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.sparql.vocabulary.FOAF;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;
import org.apache.jena.vocabulary.RDFS;

/**
 * Access control: authorizations and the groups they are granted to.
 * <p>
 * Both live in their own document, so each model carries the <code>dh:Item</code> wrapper
 * around the resource it is about - the document is not the resource.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class Acl
{

    private Acl() { }

    /**
     * Builds an authorization document. Agents, agent classes and agent groups say who; the
     * accessTo and accessToClass lists say what; the modes say how.
     *
     * @param doc document URI
     * @param uri authorization URI, relative or absolute (optional, blank node when absent)
     * @param label authorization label, also the document title
     * @param comment authorization comment (optional)
     * @param agents WebIDs the authorization is granted to
     * @param agentClasses agent classes the authorization is granted to
     * @param agentGroups agent groups the authorization is granted to
     * @param to URIs of the documents access is granted on
     * @param toAllIn URIs of the classes whose instances access is granted on
     * @param modes access modes granted
     * @return authorization model
     */
    public static Model authorization(URI doc, String uri, String label, String comment,
            List<URI> agents, List<URI> agentClasses, List<URI> agentGroups,
            List<URI> to, List<URI> toAllIn, List<Resource> modes)
    {
        Model model = ModelFactory.createDefaultModel();

        Resource auth = Subjects.of(model, doc, uri).
            addProperty(RDF.type, ACL.Authorization).
            addProperty(RDFS.label, label);
        if (comment != null) auth.addProperty(RDFS.comment, comment);

        model.createResource(doc.toString()).
            addProperty(RDF.type, DH.Item).
            addProperty(FOAF.primaryTopic, auth).
            addProperty(DCTerms.title, label);

        addResourceValues(auth, ACL.agent, agents);
        addResourceValues(auth, ACL.agentClass, agentClasses);
        addResourceValues(auth, ACL.agentGroup, agentGroups);
        addResourceValues(auth, ACL.accessTo, to);
        addResourceValues(auth, ACL.accessToClass, toAllIn);
        modes.forEach(mode -> auth.addProperty(ACL.mode, mode));

        return model;
    }

    /**
     * Builds an agent group document.
     *
     * @param doc document URI
     * @param uri group URI, relative or absolute (optional, blank node when absent)
     * @param name group name, also the document title
     * @param description group description (optional)
     * @param members WebIDs of the group's members
     * @return group model
     */
    public static Model group(URI doc, String uri, String name, String description, List<URI> members)
    {
        Model model = ModelFactory.createDefaultModel();

        Resource group = Subjects.of(model, doc, uri).
            addProperty(RDF.type, FOAF.Group).
            addProperty(FOAF.name, name);
        if (description != null) group.addProperty(DCTerms.description, description);
        members.forEach(member -> group.addProperty(FOAF.member, model.createResource(member.toString())));

        model.createResource(doc.toString()).
            addProperty(RDF.type, DH.Item).
            addProperty(FOAF.primaryTopic, group).
            addProperty(DCTerms.title, name);

        return model;
    }

    private static void addResourceValues(Resource subject, Property property, List<URI> values)
    {
        values.forEach(value -> subject.addProperty(property, subject.getModel().createResource(value.toString())));
    }

}
