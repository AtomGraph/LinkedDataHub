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
    
    /** Base URI for media type URIs */
    public final static String NS = "http://www.sparontologies.net/mediatype/"; // TO-DO: replace with https://www.w3.org/ns/formats/ URIs
    
    /**
     * Constructs media type from RDF language.
     * 
     * @param lang RDF language
     */
    public MediaType(Lang lang)
    {
        this(lang.getContentType());
    }

    /**
     * Constructs media type from RDF language and parameters.
     * 
     * @param lang RDF language
     * @param parameters media type parameters
     */
    public MediaType(Lang lang, Map<String, String> parameters)
    {
        this(lang.getContentType(), parameters);
    }
    
    /**
     * Constructs media type from Jena's content type.
     * 
     * @param ct content type
     */
    public MediaType(ContentType ct)
    {
        this(ct.getType(), ct.getSubType());
    }

    /**
     * Constructs media type from Jena's content type and parameters
     * 
     * @param ct content type
     * @param parameters media type parameters
     */
    public MediaType(ContentType ct, Map<String, String> parameters)
    {
        this(ct.getType(), ct.getSubType(), parameters);
    }
    
    /**
     * Constructs media type from type, subtype, and parameters.
     * 
     * @param type type component
     * @param subtype subtype component
     * @param parameters parameters
     */
    public MediaType(String type, String subtype, Map<String, String> parameters)
    {
        super(type, subtype, parameters);
    }

    /**
     * Constructs media type from type and subtype.
     * 
     * @param type type component
     * @param subtype subtype component
     */
    public MediaType(String type, String subtype)
    {
        super(type, subtype);
    }

    /**
     * Constructs empty media type.
     */
    public MediaType()
    {
        super();
    }
    
    /**
     * Returns JAX-RS media type as RDF resource.
     * 
     * @param mediaType media type
     * @return RDF resource
     */
    public static Resource toResource(javax.ws.rs.core.MediaType mediaType)
    {
        return ResourceFactory.createResource(toURI(mediaType).toString());
    }

    /**
     * Returns JAX-RS media type as URI.
     * 
     * @param mediaType media type
     * @return media type URI
     */
    public static URI toURI(javax.ws.rs.core.MediaType mediaType)
    {
        return URI.create(NS).resolve(URI.create(mediaType.toString()));
    }
    
    /**
     * Converts media type's RDF resource back to JAX-RS media type.
     * 
     * @param resource RDF resource
     * @return JAX-RS media type
     */
    public static javax.ws.rs.core.MediaType valueOf(Resource resource)
    {
        return valueOf(URI.create(resource.getURI()));
    }
    
    /**
     * Converts media type's URI back to JAX-RS media type.
     * 
     * @param uri media type's URI
     * @return JAX-RS media type
     */
    public static javax.ws.rs.core.MediaType valueOf(URI uri)
    {
        return valueOf(URI.create(NS).relativize(uri).toString());
    }
    
}