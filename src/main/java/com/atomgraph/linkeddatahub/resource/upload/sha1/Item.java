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
package com.atomgraph.linkeddatahub.resource.upload.sha1;

import javax.ws.rs.core.Context;
import javax.ws.rs.core.Request;
import javax.ws.rs.ext.Providers;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.client.util.DataManager;
import java.util.Optional;
import javax.inject.Inject;
import javax.ws.rs.core.EntityTag;
import javax.ws.rs.core.UriInfo;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.sparql.vocabulary.FOAF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS resource that serves content-addressed (using SHA1 hash) file data.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class Item extends com.atomgraph.linkeddatahub.resource.upload.Item
{
    private static final Logger log = LoggerFactory.getLogger(Item.class);

    @Inject
    public Item(@Context UriInfo uriInfo, @Context Request request, Optional<Ontology> ontology, Optional<Service> service, MediaTypes mediaTypes,
            Optional<com.atomgraph.linkeddatahub.apps.model.Application> application,
            DataManager dataManager,
            @Context Providers providers, com.atomgraph.linkeddatahub.Application system)
    {
        super(uriInfo, request, ontology, service, mediaTypes,
            application,
            dataManager, providers, system);
        if (log.isDebugEnabled()) log.debug("Constructing {}", getClass());
    }
    
    @Override
    public EntityTag getEntityTag(Model model)
    {
        return new EntityTag(getSHA1Hash(getResource()));
    }
    
    public String getSHA1Hash(Resource resource)
    {
        return resource.getRequiredProperty(FOAF.sha1).getString();
    }
    
}
