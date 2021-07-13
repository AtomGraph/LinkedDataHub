/**
 *  Copyright 2021 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.resource.add;

import com.atomgraph.core.vocabulary.SD;
import com.atomgraph.linkeddatahub.vocabulary.NFO;
import java.net.URI;
import java.util.Map;
import javax.ws.rs.BadRequestException;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.DCTerms;
import org.glassfish.jersey.media.multipart.FormDataBodyPart;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class Container extends com.atomgraph.linkeddatahub.resource.file.Container
{

    private static final Logger log = LoggerFactory.getLogger(Container.class);

    @Override
    public Response postMultipart(Model model, Boolean defaultGraph, URI graphUri, Map<String, FormDataBodyPart> fileNameBodyPartMap)
    {
        if (model == null) throw new IllegalArgumentException("Model cannot be null");
        if (fileNameBodyPartMap == null) throw new IllegalArgumentException("Map<String, FormDataBodyPart> cannot be null");
        
        int count = 0;
        ResIterator resIt = model.listResourcesWithProperty(NFO.fileName);
        try
        {
            while (resIt.hasNext())
            {
                Resource file = resIt.next();
                String fileName = file.getProperty(NFO.fileName).getString();
                FormDataBodyPart bodyPart = fileNameBodyPartMap.get(fileName);
                
                Resource graph = file.getPropertyResourceValue(SD.name);
                if (graph == null || !graph.isURIResource()) throw new BadRequestException("Graph URI not specified for uploaded File");

                MediaType mediaType = null;
                if (file.hasProperty(DCTerms.format)) mediaType = com.atomgraph.linkeddatahub.MediaType.valueOf(file.getPropertyResourceValue(DCTerms.format));
                if (mediaType != null) bodyPart.setMediaType(mediaType);

                Model partModel = bodyPart.getValueAs(Model.class);
                post(partModel, false, URI.create(graph.getURI())); // append uploaded triples/quads
                count++;
            }
        }
        finally
        {
            resIt.close();
        }

        if (log.isDebugEnabled()) log.debug("# of files uploaded: {} ", count);
        return post(model, defaultGraph, graphUri);
    }
    
}
