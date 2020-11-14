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
package com.atomgraph.linkeddatahub.server.model;

import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.model.Agent;
import javax.ws.rs.Consumes;
import javax.ws.rs.POST;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import org.apache.jena.rdf.model.Model;
import org.glassfish.jersey.media.multipart.FormDataMultiPart;

/**
 * LinkedDataHub server resource interface.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public interface Resource extends com.atomgraph.core.model.Resource
{
    
    Application getApplication();
    
    boolean exists(org.apache.jena.rdf.model.Resource resource);

    Response construct(Model model);
    
    @POST
    @Consumes(MediaType.MULTIPART_FORM_DATA)
    Response postMultipart(FormDataMultiPart multiPart);
    
    // UserAccount getUserAccount(); // TO-DO: refactor into SecurityContext
    
    Agent getAgent();
    
}
