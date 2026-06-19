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

import com.atomgraph.server.util.Validator;
import com.atomgraph.spinrdf.constraints.ConstraintViolation;
import com.atomgraph.spinrdf.constraints.SPINConstraints;
import java.util.List;
import org.apache.jena.ontapi.OntModelFactory;
import org.apache.jena.ontapi.OntSpecification;
import org.apache.jena.ontapi.model.OntModel;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.riot.RDFDataMgr;
import org.apache.jena.vocabulary.RDF;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Regression guard for SPIN constraint validation under the ontapi migration.
 *
 * {@code SPINConstraints} resolves a constraint through Jena enhanced-node polymorphism
 * ({@code canAs(Query)}/{@code canAs(TemplateCall)}), which an ontapi {@link OntModel}'s profile-aware personality
 * does not carry — so before the fix, validation silently fired nothing. twirl now re-bases the constraint model
 * onto its SPIN personality internally (twirl {@code SPINConstraints.check}), so {@link Validator} can hand it the
 * ontapi model directly. This pins that the real {@code dh:Item spin:constraint :MissingTitle} template constraint
 * flags a {@code dh:Item} that lacks {@code dct:title}.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class SPINConstraintValidationTest
{

    static
    {
        org.apache.jena.sys.JenaSystem.init();
    }

    private static final String DH = "https://www.w3.org/ns/ldt/document-hierarchy#";

    /** The full owl:imports closure the ontology pipeline assembles for the document-hierarchy ontology. */
    private OntModel loadOntology()
    {
        Model closure = ModelFactory.createDefaultModel();
        for (String classpath : new String[] {
            "etc/sp.ttl", "etc/spl.spin.ttl", "etc/spin.ttl",
            "com/atomgraph/linkeddatahub/dh.ttl",
            "com/atomgraph/linkeddatahub/def.ttl",
            "com/atomgraph/linkeddatahub/ldh.ttl" })
            RDFDataMgr.read(closure, classpath);

        // mirror OntologyFilter.loadOntology: RDFS-infer then materialize into a plain OWL1_FULL_MEM graph
        OntModel inferred = OntModelFactory.createModel(closure.getGraph(), OntSpecification.OWL1_FULL_MEM_RDFS_INF);
        OntModel materialized = OntModelFactory.createModel(OntSpecification.OWL1_FULL_MEM);
        materialized.add(inferred);
        return materialized;
    }

    /** A dh:Item with NO dct:title — violates the MissingTitle constraint. */
    private Model violatingItem()
    {
        Model data = ModelFactory.createDefaultModel();
        data.createResource("http://example.org/doc").addProperty(RDF.type, data.createResource(DH + "Item"));
        return data;
    }

    @Test
    public void testMissingTitleConstraintFiresThroughValidator()
    {
        List<ConstraintViolation> violations = new Validator(loadOntology()).validate(violatingItem());
        assertFalse(violations.isEmpty(), "MissingTitle SPIN constraint must fire on a dh:Item without dct:title");
    }

    @Test
    public void testRawOntApiModelFiresViaTwirlRebase()
    {
        // The ontapi OntModel's profile-aware personality lacks the SPIN views, so canAs(...) is false on it.
        // twirl's SPINConstraints.check re-bases the constraint model onto its own SPIN personality, so passing the
        // ontapi model straight in still fires. Guards against twirl regressing that re-base.
        List<ConstraintViolation> direct = SPINConstraints.check(violatingItem(), loadOntology());
        assertFalse(direct.isEmpty(), "SPINConstraints.check must fire on a raw ontapi OntModel (twirl re-bases internally)");
    }

}
