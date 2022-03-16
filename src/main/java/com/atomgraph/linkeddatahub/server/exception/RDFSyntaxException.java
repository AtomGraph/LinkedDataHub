/**
 *  Copyright 2019 Martynas Jusevičius <martynas@atomgraph.com>
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

import java.util.List;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.RDF;
import org.apache.jena.vocabulary.RDFS;
import com.atomgraph.linkeddatahub.server.io.CollectingErrorHandler.Violation;
import com.atomgraph.linkeddatahub.vocabulary.LDH;
import com.atomgraph.server.exception.ModelException;

/**
 * RDF syntax exception.
 * Thrown when read RDF data contains a syntax error.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see com.atomgraph.server.io.SkolemizingModelProvider
 */
public class RDFSyntaxException extends ModelException
{
    
    private final List<Violation> violations;
    
    /**
     * Constructs exception.
     * 
     * @param violations list of violations
     * @param model violation RDF model
     */
    public RDFSyntaxException(List<Violation> violations, Model model)
    {
        super(model);
        this.violations = violations;
        
        for (Violation violation : violations)
        {
            Resource violationRes = model.createResource().addProperty(RDF.type, LDH.URISyntaxViolation).
                addLiteral(RDFS.label, violation.getMessage());
            
            // hacky heuristic to extract the invalid URI value, which Jena's ErrorHandler does not directly expose
            if (violation.getMessage().startsWith("Bad IRI: <") && violation.getMessage().contains("Code: 57"))
            {
                String value = violation.getMessage().substring(violation.getMessage().lastIndexOf("<") + 1,
                    violation.getMessage().lastIndexOf(">"));
                violationRes.addLiteral(LDH.violationValue, value);
            }
        }
    }
    
    /**
     * Returns he violation list.
     * 
     * @return violation list
     */
    public List<Violation> getViolations()
    {
        return violations;
    }
    
}
