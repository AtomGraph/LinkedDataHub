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
package com.atomgraph.linkeddatahub;

import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import java.net.URI;
import java.util.Map;
import org.apache.jena.atlas.web.ContentType;
import org.apache.jena.riot.Lang;

/**
 * Media type representation with URI resource mapping.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see <a href="http://www.sparontologies.net/mediatype/">Media type as Linked Open Data</a>
 * @see <a href="https://www.w3.org/ns/formats/">File Formats</a>
 */
public class MediaType extends com.atomgraph.client.MediaType
{
    
    public final static String NS = "http://www.sparontologies.net/mediatype/"; // TO-DO: replace with https://www.w3.org/ns/formats/ URIs
    
    public MediaType(Lang lang)
    {
        this(lang.getContentType());
    }

    public MediaType(Lang lang, Map<String, String> parameters)
    {
        this(lang.getContentType(), parameters);
    }
    
    public MediaType(ContentType ct)
    {
        this(ct.getType(), ct.getSubType());
    }

    public MediaType(ContentType ct, Map<String, String> parameters)
    {
        this(ct.getType(), ct.getSubType(), parameters);
    }
    
    public MediaType(String type, String subtype, Map<String, String> parameters)
    {
        super(type, subtype, parameters);
    }

    public MediaType(String type, String subtype)
    {
        super(type, subtype);
    }

    public MediaType()
    {
        super();
    }
    
    public static Resource toResource(javax.ws.rs.core.MediaType mediaType)
    {
        return ResourceFactory.createResource(toURI(mediaType).toString());
    }

    public static URI toURI(javax.ws.rs.core.MediaType mediaType)
    {
        return URI.create(NS).resolve(URI.create(mediaType.toString()));
    }
    
    public static javax.ws.rs.core.MediaType valueOf(Resource resource)
    {
        return valueOf(URI.create(resource.getURI()));
    }
    
    public static javax.ws.rs.core.MediaType valueOf(URI uri)
    {
        return valueOf(URI.create(NS).relativize(uri).toString());
    }
    
}