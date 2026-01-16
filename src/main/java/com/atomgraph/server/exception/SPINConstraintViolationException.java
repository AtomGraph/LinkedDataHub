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
import java.util.List;
import com.atomgraph.spinrdf.constraints.ConstraintViolation;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class SPINConstraintViolationException extends ModelException
{
    private final List<ConstraintViolation> cvs;
    
    public SPINConstraintViolationException(List<ConstraintViolation> cvs, Model model, String graphURI)
    {
        super(model);
        this.cvs = cvs;
    }

    public SPINConstraintViolationException(List<ConstraintViolation> cvs, Model model)
    {
        this(cvs, model, null);
    }
    
    public List<ConstraintViolation> getConstraintViolations()
    {
        return cvs;
    }
    
}
