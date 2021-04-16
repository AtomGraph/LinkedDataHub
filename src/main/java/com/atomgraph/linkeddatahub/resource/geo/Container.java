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
package com.atomgraph.linkeddatahub.resource.geo;

import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.model.ClientUriInfo;
import com.atomgraph.client.util.DataManager;
import com.atomgraph.linkeddatahub.server.model.impl.ResourceBase;
import com.atomgraph.processor.model.TemplateCall;
import java.util.Optional;
import javax.inject.Inject;
import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.container.ResourceContext;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.SecurityContext;
import javax.ws.rs.core.UriInfo;
import javax.ws.rs.ext.Providers;
import org.apache.jena.ontology.Ontology;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS resource that handles geo container requests.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Deprecated
public class Container extends ResourceBase
{
    private static final Logger log = LoggerFactory.getLogger(Container.class);
    
    @Inject
    public Container(@Context UriInfo uriInfo, ClientUriInfo clientUriInfo, @Context Request request, MediaTypes mediaTypes,
            Optional<Service> service, Optional<com.atomgraph.linkeddatahub.apps.model.Application> application,
            Optional<Ontology> ontology, Optional<TemplateCall> templateCall,
            @Context HttpHeaders httpHeaders, @Context ResourceContext resourceContext,
            @Context HttpServletRequest httpServletRequest, @Context SecurityContext securityContext,
            DataManager dataManager, @Context Providers providers,
            com.atomgraph.linkeddatahub.Application system)
    {
        super(uriInfo, clientUriInfo, request, mediaTypes, 
            service, application,
            ontology, templateCall,
            httpHeaders, resourceContext,
            httpServletRequest, securityContext,
            dataManager, providers,
            system);
    }
    
//    @Override
//    public Response get()
//    {
//        if (getEast() != null && getNorth() != null && getSouth() != null && getWest() != null)
//        {
//            if (log.isDebugEnabled()) log.debug("SW Lat: {} SW Lng: {}", getSouth(), getWest());
//            if (log.isDebugEnabled()) log.debug("NE Lat: {} NE Lng: {}", getNorth(), getEast());
//
//            addFilters(getQueryBuilder().getSubSelectBuilders().get(0), getQueryBuilder().getModel(),
//                    getEast(), getNorth(), getSouth(), getWest());
//        }
//        
//        return super.get();
//    }

    // https://developers.google.com/maps/articles/toomanymarkers#viewportmarkermanagement
    // http://stackoverflow.com/questions/7920565/how-can-i-query-for-all-records-within-latitude-longitude-area
//    public void addFilters(SelectBuilder selectBuilder, Model model, Float east, Float north, Float south, Float west)
//    {        
//        selectBuilder.filter(createFilter(model, model.createResource(SP.NS + "ge"),
//                SPINFactory.createVariable(model, "lat"), model.createTypedLiteral(south)));
//        selectBuilder.filter(createFilter(model, model.createResource(SP.NS + "le"),
//                SPINFactory.createVariable(model, "lat"), model.createTypedLiteral(north)));
//
//        if (west > 0 && east < 0)
//        {
//            if (log.isDebugEnabled()) log.debug("Viewport bounds are crossing the anti-meridian (180 degrees)");
//            
//            selectBuilder.filter(SPINFactory.createFilter(model, model.createResource().
//                addProperty(RDF.type, model.createResource(SP.NS + "or")).
//                addProperty(SP.arg1, model.createResource().
//                    addProperty(RDF.type, model.createResource(SP.NS + "and")).
//                    addProperty(SP.arg1, model.createResource().
//                        addProperty(RDF.type, model.createResource(SP.NS + "ge")).
//                        addProperty(SP.arg1, SPINFactory.createVariable(model, "long")).
//                        addProperty(SP.arg2, model.createTypedLiteral(west))).
//                    addProperty(SP.arg2, model.createResource().
//                        addProperty(RDF.type, model.createResource(SP.NS + "le")).
//                        addProperty(SP.arg1, SPINFactory.createVariable(model, "long")).
//                        addProperty(SP.arg2, model.createTypedLiteral(Float.valueOf(180))))).
//                addProperty(SP.arg2, model.createResource().
//                    addProperty(RDF.type, model.createResource(SP.NS + "and")).
//                    addProperty(SP.arg1, model.createResource().
//                        addProperty(RDF.type, model.createResource(SP.NS + "ge")).
//                        addProperty(SP.arg1, SPINFactory.createVariable(model, "long")).
//                        addProperty(SP.arg2, model.createTypedLiteral(Float.valueOf(-180)))).
//                    addProperty(SP.arg2, model.createResource().
//                        addProperty(RDF.type, model.createResource(SP.NS + "le")).
//                        addProperty(SP.arg1, SPINFactory.createVariable(model, "long")).
//                        addProperty(SP.arg2, model.createTypedLiteral(east))))));
//        }
//        else
//        {
//            selectBuilder.filter(createFilter(model, model.createResource(SP.NS + "ge"),
//                    SPINFactory.createVariable(model, "long"), model.createTypedLiteral(west)));
//            selectBuilder.filter(createFilter(model, model.createResource(SP.NS + "le"),
//                    SPINFactory.createVariable(model, "long"), model.createTypedLiteral(east)));
//        }
//    }
    
//    public Float getEast()
//    {
//        return getTemplateCall().getArgumentProperty(APLT.east).getFloat();
//    }
//    
//    public Float getNorth()
//    {
//        return getTemplateCall().getArgumentProperty(APLT.north).getFloat();
//    }
//    
//    public Float getSouth()
//    {
//        return getTemplateCall().getArgumentProperty(APLT.south).getFloat();
//    }
//
//    public Float getWest()
//    {
//        return getTemplateCall().getArgumentProperty(APLT.west).getFloat();
//    }

}