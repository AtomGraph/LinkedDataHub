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
package com.atomgraph.linkeddatahub.server.filter.request;

import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.linkeddatahub.vocabulary.APL;
import com.sun.jersey.api.uri.UriComponent;
import com.sun.jersey.spi.container.ContainerRequest;
import com.sun.jersey.spi.container.ContainerRequestFilter;
import com.sun.jersey.spi.container.ContainerResponseFilter;
import com.sun.jersey.spi.container.ResourceFilter;
import java.util.Arrays;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import javax.ws.rs.core.UriBuilder;

/**
 * Request filter that removes Web-Client parameters from URL query.
 * That is done so that the server does not receive them, as client params are meaningless in a server context.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Deprecated
public class ClientParamRemovalFilter implements ContainerRequestFilter, ResourceFilter
{

    public final static List<String> CLIENT_PARAMS = Arrays.asList(AC.uri.getLocalName(), AC.endpoint.getLocalName(), // AC.query.getLocalName(),
            AC.limit.getLocalName(), AC.offset.getLocalName(), AC.order_by.getLocalName(), AC.desc.getLocalName(),
            AC.mode.getLocalName(), AC.accept.getLocalName(),
            APL.access_to.getLocalName());
    
    @Override
    public ContainerRequest filter(ContainerRequest request)
    {
        UriBuilder requestUriWithoutAC = UriBuilder.fromUri(request.getRequestUri());
        requestUriWithoutAC.replaceQuery(null);

        Iterator<Map.Entry<String, List<String>>> it = request.getQueryParameters().entrySet().iterator();
        while (it.hasNext())
        {
            Map.Entry<String, List<String>> entry = it.next();
            for (String value : entry.getValue())
                if (!CLIENT_PARAMS.contains(entry.getKey()))
                    // we URI-encode values ourselves because Jersey 1.x fails to do so: https://java.net/jira/browse/JERSEY-1717
                    requestUriWithoutAC.queryParam(entry.getKey(), UriComponent.encode(value, UriComponent.Type.UNRESERVED));
        }

        request.setUris(request.getBaseUri(), requestUriWithoutAC.build());
        
        return request;
    }
    
    @Override
    public ContainerRequestFilter getRequestFilter()
    {
        return this;
    }

    @Override
    public ContainerResponseFilter getResponseFilter()
    {
        return null;
    }
    
}
