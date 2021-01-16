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
package com.atomgraph.linkeddatahub.client.impl;

import org.apache.jena.util.LocationMapper;
import java.net.URI;
import javax.ws.rs.core.SecurityContext;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.client.filter.WebIDDelegationFilter;
import com.atomgraph.linkeddatahub.model.Agent;
import java.util.Map;
import javax.ws.rs.client.Client;
import javax.ws.rs.client.ClientRequestFilter;
import javax.ws.rs.client.WebTarget;
import javax.xml.transform.Source;
import javax.xml.transform.TransformerException;
import org.apache.jena.rdf.model.Model;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Manager for remote RDF dataset access.
 * Documents can be mapped to local copies.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class DataManagerImpl extends com.atomgraph.client.util.DataManagerImpl
{
    private static final Logger log = LoggerFactory.getLogger(DataManagerImpl.class);
    
    private final URI rootContextURI;
    private final URI baseURI;
    private final String authScheme;
    private final Agent agent;

    public DataManagerImpl(LocationMapper mapper, Map<String, Model> modelCache,
            Client client, MediaTypes mediaTypes,
            boolean cacheModelLoads, boolean preemptiveAuth, boolean resolvingUncached,
            URI rootContextURI, Application app,
            SecurityContext securityContext)
    {
        this(mapper, modelCache,
            client, mediaTypes,
            cacheModelLoads, preemptiveAuth, resolvingUncached,
            rootContextURI,
            app != null ? app.getBaseURI() : null,
            securityContext != null ? securityContext.getAuthenticationScheme() : null,
            (securityContext != null && securityContext.getUserPrincipal() instanceof Agent) ? (Agent)securityContext.getUserPrincipal() : null);
    }
    
    public DataManagerImpl(LocationMapper mapper, Map<String, Model> modelCache, 
            Client client, MediaTypes mediaTypes,
            boolean cacheModelLoads, boolean preemptiveAuth, boolean resolvingUncached,
            URI rootContextURI, URI baseURI,
            String authScheme, Agent agent)
    {
        super(mapper, modelCache, client, mediaTypes, cacheModelLoads, preemptiveAuth, resolvingUncached);
        this.rootContextURI = rootContextURI;
        this.baseURI = baseURI;
        this.authScheme = authScheme;
        this.agent = agent;
    }
    
    @Override
    public boolean resolvingUncached(String filenameOrURI)
    {
        // first check if the resolution of uncached documents is allowed in the configuration
        // TO-DO: new config property resolveUncachedRelative?
        if (super.resolvingUncached(filenameOrURI))
            if (getBaseURI() != null && !isMapped(filenameOrURI))
            {
                // always resolve URIs relative to the root Context base URI
                boolean relative = !getRootContextURI().relativize(URI.create(filenameOrURI)).isAbsolute();
                return relative;
            }
        
        return super.resolvingUncached(filenameOrURI); // by default, do not resolve URIs
    }
    
    public ClientRequestFilter getClientAuthFilter()
    {
        if (getAgent() != null)
        {
            if (log.isDebugEnabled()) log.debug("Delegating Agent's <{}> access to secretary", getAgent());
            return new WebIDDelegationFilter(getAgent());
        }
            
        return null;
    }
    
    @Override
    public Source resolve(String href, String base) throws TransformerException
    {
        URI hrefBase = URI.create(base);
        URI uri = href.isEmpty() ? hrefBase : hrefBase.resolve(href);
        if (uri.getScheme().equals("http") || uri.getScheme().equals("https"))
        {
            if (!(hasCachedModel(uri.toString()) || (isResolvingMapped() && isMapped(uri.toString()))))
            {
                // if document is not cached, construct ontology URI - they are cached under different URIs than their documents. TO-DO: refactor
                String ontologyHref = href + "#";
                uri = href.isEmpty() ? hrefBase : hrefBase.resolve(ontologyHref);
                if (hasCachedModel(uri.toString()) || (isResolvingMapped() && isMapped(uri.toString())))
                {
                    if (log.isDebugEnabled()) log.debug("Resolving ontology URI '{}' from model cache instead of dereferencing its document '{}'", ontologyHref, href);
                    return super.resolve(ontologyHref, base);
                }
            }
        }
        
        return super.resolve(href, base);
    }
    
//    @Override
//    public Source getSource(Model model, String systemId) throws IOException
//    {
//        if (log.isDebugEnabled()) log.debug("Number of Model stmts read: {}", model.size());
//        try (ByteArrayOutputStream stream = new ByteArrayOutputStream())
//        {
//            // if the model uses inference, discard the inferred statements - XSLT functions will be traversing ontology documents as Linked Data anyway
//            if (model instanceof InfModel) model = ((InfModel)model).getRawModel();
//            
//            model.write(stream);
//            if (log.isDebugEnabled()) log.debug("RDF/XML bytes written: {}", stream.toByteArray().length);
//            return new StreamSource(new ByteArrayInputStream(stream.toByteArray()), systemId);
//        }
//    }
    
    @Override
    public WebTarget getEndpoint(URI uri)
    {
        return getEndpoint(uri, true);
    }
    
    public WebTarget getEndpoint(URI uri, boolean delegateWebID)
    {
        WebTarget endpoint = super.getEndpoint(uri);
        
        if (delegateWebID && !getBaseURI().relativize(uri).isAbsolute())
        {
            ClientRequestFilter filter = getClientAuthFilter();
            if (filter != null) endpoint.register(filter);
        }
        
        return endpoint;
    }

    public URI getRootContextURI()
    {
        return rootContextURI;
    }
    
    public URI getBaseURI()
    {
        return baseURI;
    }
    
    public String getAuthScheme()
    {
        return authScheme;
    }
    
    public Agent getAgent()
    {
        return agent;
    }
    
}