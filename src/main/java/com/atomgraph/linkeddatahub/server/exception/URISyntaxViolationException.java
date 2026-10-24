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
package com.atomgraph.linkeddatahub.server.exception;

import com.atomgraph.linkeddatahub.vocabulary.LDH;
import com.atomgraph.server.exception.ModelException;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.vocabulary.RDF;
import org.apache.jena.vocabulary.RDFS;

/**
 * A write refused for IRIs that are not IRIs. Each is described as an <code>ldh:URISyntaxViolation</code> carrying
 * the value as written (<code>ldh:violationValue</code>) and the explanation (<code>rdfs:label</code>), so a form
 * can mark the field it was typed into.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class URISyntaxViolationException extends ModelException
{

    private final Map<String, String> violations;

    /**
     * Constructs the exception.
     *
     * @param violations malformed IRIs mapped to their explanations
     */
    public URISyntaxViolationException(Map<String, String> violations)
    {
        super(ModelFactory.createDefaultModel());
        if (violations == null || violations.isEmpty()) throw new IllegalArgumentException("Violations cannot be null or empty");

        this.violations = Collections.unmodifiableMap(new LinkedHashMap<>(violations));
        this.violations.forEach((value, message) -> getModel().createResource().
            addProperty(RDF.type, LDH.URISyntaxViolation).
            addProperty(RDFS.label, message).
            addProperty(LDH.violationValue, value));
    }

    /**
     * Returns the malformed IRIs.
     *
     * @return malformed IRIs mapped to their explanations
     */
    public Map<String, String> getViolations()
    {
        return violations;
    }

    @Override
    public String getMessage()
    {
        return "Not a valid IRI: " + String.join(", ", getViolations().values());
    }

}
