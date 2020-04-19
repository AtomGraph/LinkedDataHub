/**
 *  Copyright 2020 Martynas Jusevičius <martynas@atomgraph.com>
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

package com.atomgraph.linkeddatahub.client;

import java.net.URI;
import javax.ws.rs.client.WebTarget;
import javax.ws.rs.core.Response;
import javax.xml.transform.URIResolver;
import net.sf.saxon.trans.UnparsedTextURIResolver;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelGetter;

/**
 *
 * @author Martynas Jusevičius <martynas@atomgraph.com>
 */
public interface DataManager extends ModelGetter, URIResolver, UnparsedTextURIResolver
{

    WebTarget getEndpoint(URI uri);
    
    Response get(String uri, javax.ws.rs.core.MediaType[] acceptedTypes);
    
    Response load(String filenameOrURI);
    
    Model loadModel(String uri);

}
