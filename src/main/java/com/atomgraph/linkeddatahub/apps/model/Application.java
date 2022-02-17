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
package com.atomgraph.linkeddatahub.apps.model;

import com.atomgraph.linkeddatahub.model.Service;
import java.net.URI;
import org.apache.jena.rdf.model.Resource;

/**
 * A dataspace with a base URI, LDT ontology, SPARQL backend, and XSLT frontend.
 * This is a "logical" LinkedDataHub application which should be confused with the JAX-RS application implementation.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public interface Application extends Resource, com.atomgraph.processor.model.Application
{
    
    Resource getMaker();
    
    Resource getBase();
    
    URI getBaseURI();
    
    @Override
    Service getService();

    Resource getStylesheet();
    
    boolean isReadOnly();
    
}
