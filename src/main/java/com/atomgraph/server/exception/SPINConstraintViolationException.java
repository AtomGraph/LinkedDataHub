/*
 * Copyright 2013 Martynas Jusevičius <martynas@atomgraph.com>.
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

package com.atomgraph.server.exception;

import org.apache.jena.rdf.model.Model;
import org.apache.jena.shacl.ValidationReport;
import java.util.List;
import com.atomgraph.spinrdf.constraints.ConstraintViolation;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class SPINConstraintViolationException extends ModelException
{
    private final List<ConstraintViolation> cvs;
    private final ValidationReport report;
    
    /**
     * Constructs a violation that carries both kinds a write can fail: the SPIN violations and, when the
     * same model does not conform to the ontology's SHACL shapes either, that report. Validation runs both
     * so that a form which fails one of each is told about both at once, rather than about the second
     * only after the first is corrected.
     * 
     * @param cvs SPIN constraint violations
     * @param model validated model
     * @param graphURI graph URI
     * @param report SHACL validation report, or null if the model conforms to the shapes
     */
    public SPINConstraintViolationException(List<ConstraintViolation> cvs, Model model, String graphURI, ValidationReport report)
    {
        super(model);
        this.cvs = cvs;
        this.report = report;
    }

    public SPINConstraintViolationException(List<ConstraintViolation> cvs, Model model, String graphURI)
    {
        this(cvs, model, graphURI, null);
    }

    public SPINConstraintViolationException(List<ConstraintViolation> cvs, Model model)
    {
        this(cvs, model, null);
    }
    
    public List<ConstraintViolation> getConstraintViolations()
    {
        return cvs;
    }
    
    /**
     * Returns the SHACL validation report of the same model, if it did not conform to the shapes either.
     * 
     * @return validation report or null
     */
    public ValidationReport getValidationReport()
    {
        return report;
    }
    
}
