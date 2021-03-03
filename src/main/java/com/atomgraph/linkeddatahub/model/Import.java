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
package com.atomgraph.linkeddatahub.model;

import com.atomgraph.client.util.DataManager;
import com.atomgraph.processor.util.Validator;
import com.atomgraph.spinrdf.constraints.ConstraintViolation;
import java.util.List;
import org.apache.jena.rdf.model.Resource;

/**
 * Data import.
 * Represents source file, target container, validator and constraint violations.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public interface Import extends Resource
{
        
//    Import setDataManager(DataManager dataManager);
//    
//    DataManager getDataManager();
//    
//    Import setValidator(Validator validator);
//    
//    Validator getValidator();

//    List<ConstraintViolation> getConstraintViolations();
    
//    Import setBaseUri(Resource baseUri);
//    
//    Resource getBaseUri();
    
    Resource getFile();
    
    Resource getContainer();
    
}
