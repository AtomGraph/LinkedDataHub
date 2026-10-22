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
package com.atomgraph.linkeddatahub.server.security;

import com.atomgraph.linkeddatahub.vocabulary.ACL;
import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.function.Function;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.RDFNode;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFParser;
import org.apache.jena.vocabulary.RDFS;

/**
 * The hierarchy of WAC access modes, as the bundled ACL ontology declares it.
 * The ontology declares <code>acl:Append rdfs:subClassOf acl:Write</code>: an append is a write that only adds
 * information, so a grant of <code>acl:Write</code> covers an operation that requires <code>acl:Append</code>,
 * and a grant of <code>acl:Append</code> does not cover one that requires <code>acl:Write</code>.
 * <code>acl:Access</code>, the class of all accesses, is the root of the hierarchy rather than a mode an
 * authorization grants, so it never covers anything.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see <a href="https://www.w3.org/ns/auth/acl">ACL ontology</a>
 */
public class AccessModes
{

    /** Classpath location of the bundled ACL ontology, the file the <code>acl:</code> namespace is mapped to */
    public static final String ONTOLOGY_LOCATION = "/com/atomgraph/linkeddatahub/acl.rdf";

    private static final Model ONTOLOGY = load();

    private static Model load()
    {
        try (InputStream is = AccessModes.class.getResourceAsStream(ONTOLOGY_LOCATION))
        {
            if (is == null) throw new IllegalStateException("ACL ontology not found on the classpath at " + ONTOLOGY_LOCATION);

            Model model = ModelFactory.createDefaultModel();
            RDFParser.create().source(is).lang(Lang.RDFXML).base(ACL.NS).parse(model);
            return model;
        }
        catch (IOException ex)
        {
            throw new UncheckedIOException(ex);
        }
    }

    /**
     * Returns the modes whose grant covers the given required mode: the mode itself and its superclasses.
     *
     * @param mode required access mode
     * @return covering modes
     */
    public static Set<Resource> covering(Resource mode)
    {
        return closure(mode, m -> ONTOLOGY.listObjectsOfProperty(m, RDFS.subClassOf).toList());
    }

    /**
     * Returns the modes the given granted mode covers: the mode itself and its subclasses.
     *
     * @param mode granted access mode
     * @return covered modes
     */
    public static Set<Resource> covered(Resource mode)
    {
        return closure(mode, m -> ONTOLOGY.listSubjectsWithProperty(RDFS.subClassOf, m).toList());
    }

    private static Set<Resource> closure(Resource mode, Function<Resource, List<? extends RDFNode>> step)
    {
        if (mode == null) throw new IllegalArgumentException("Access mode cannot be null");

        Set<Resource> modes = new HashSet<>();
        collect(mode, step, modes);
        return Collections.unmodifiableSet(modes);
    }

    private static void collect(Resource mode, Function<Resource, List<? extends RDFNode>> step, Set<Resource> modes)
    {
        if (mode.equals(ACL.Access) || !modes.add(mode)) return;

        step.apply(mode).stream().
            filter(RDFNode::isURIResource).
            map(RDFNode::asResource).
            forEach(next -> collect(next, step, modes));
    }

}
