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

import java.net.URI;
import java.util.List;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.UriInfo;
import org.apache.jena.query.Query;

/**
 * LinkedDataHub SPARQL endpoint interface.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Deprecated
public interface SPARQLEndpoint extends com.atomgraph.core.model.SPARQLEndpoint
{
    
    Response get(Query query, List<URI> defaultGraphUris, List<URI> namedGraphUris, UriInfo uriInfo, HttpHeaders httpHeaders);

    Response post(Query query, List<URI> defaultGraphUris, List<URI> namedGraphUris, UriInfo uriInfo, HttpHeaders httpHeaders);

}
