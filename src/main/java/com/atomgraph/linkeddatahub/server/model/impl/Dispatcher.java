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
package com.atomgraph.linkeddatahub.server.model.impl;

import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.linkeddatahub.apps.model.Dataset;
import com.atomgraph.linkeddatahub.resource.Generate;
import com.atomgraph.linkeddatahub.resource.Namespace;
import com.atomgraph.linkeddatahub.resource.Transform;
import com.atomgraph.linkeddatahub.resource.admin.Clear;
import com.atomgraph.linkeddatahub.resource.admin.RequestAccess;
import com.atomgraph.linkeddatahub.resource.admin.SignUp;
import com.atomgraph.linkeddatahub.resource.Graph;
import com.atomgraph.linkeddatahub.resource.acl.Access;
import com.atomgraph.linkeddatahub.resource.acl.AccessRequest;
import java.util.Optional;
import jakarta.inject.Inject;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.UriInfo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * A catch-all JAX-RS resource that routes requests to sub-resources.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Path("/")
public class Dispatcher
{
    
    private static final Logger log = LoggerFactory.getLogger(Dispatcher.class);

    private final UriInfo uriInfo;
    private final Optional<Dataset> dataset;
    private final com.atomgraph.linkeddatahub.Application system;
    
    /**
     * Constructs resource which dispatches requests to sub-resources.
     * 
     * @param uriInfo URI info
     * @param dataset optional dataset
     * @param system system application
     */
    @Inject
    public Dispatcher(@Context UriInfo uriInfo, Optional<Dataset> dataset, com.atomgraph.linkeddatahub.Application system)
    {
        this.uriInfo = uriInfo;
        this.dataset = dataset;
        this.system = system;
    }
    
    /**
     * Returns proxy class that takes precedence over the default JAX-RS path matching.
     * The request is proxied in two cases:
     * <ul>
     *   <li>externally (URI specified by the <code>?uri</code> query param, when <code>?graph</code> query param not set)</li>
     *   <li>internally if it matches a <code>lapp:Dataset</code> specified in the system app config</li>
     * </ul>
     * @return optional class
     */
    public Optional<Class> getProxyClass()
    {
        if (getUriInfo().getQueryParameters().containsKey(AC.uri.getLocalName()))
        {
            if (log.isDebugEnabled()) log.debug("No Application matched request URI <{}>, dispatching to ProxyResourceBase", getUriInfo().getQueryParameters().getFirst(AC.uri.getLocalName()));
            return Optional.of(ProxyResourceBase.class);
        }
        if (getDataset().isPresent())
        {
            if (log.isDebugEnabled()) log.debug("Serving request URI <{}> from Dataset <{}>, dispatching to ProxyResourceBase", getUriInfo().getAbsolutePath(), getDataset().get());
            return Optional.of(ProxyResourceBase.class);
        }
        
        return Optional.empty();
    }
    
    /**
     * Returns JAX-RS resource that will handle this request.
     * 
     * @return resource
     */
    @Path("{path: .*}")
    public Class getSubResource()
    {
        return getProxyClass().orElse(getDocumentClass());
    }
    
    // TO-DO: move @Path annotations onto respective classes?
    
    /**
     * Returns SPARQL protocol endpoint.
     * 
     * @return endpoint resource
     */
    @Path("sparql")
    public Class getSPARQLEndpoint()
    {
        return getProxyClass().orElse(SPARQLEndpointImpl.class);
    }

    /**
     * Returns SPARQL endpoint for the in-memory ontology model.
     * 
     * @return endpoint resource
     */
    @Path("ns")
    public Class getNamespace()
    {
        return getProxyClass().orElse(Namespace.class);
    }

    /**
     * Returns second-level ontology documents.
     * 
     * @return namespace resource
     */
    @Path("ns/{slug}/")
    public Class getSubOntology()
    {
        return getProxyClass().orElse(Namespace.class);
    }
    
    /**
     * Returns signup endpoint.
     * 
     * @return endpoint resource
     */
    @Path("sign up")
    public Class getSignUp()
    {
        return getProxyClass().orElse(SignUp.class);
    }
    
    /**
     * Returns the access description endpoint.
     * 
     * @return endpoint resource
     */
    @Path("access")
    public Class getAccess()
    {
        return getProxyClass().orElse(Access.class);
    }

    /**
     * Returns the access description endpoint.
     * 
     * @return endpoint resource
     */
    @Path("access/request")
    public Class getAccessRequest()
    {
        return getProxyClass().orElse(AccessRequest.class);
    }
    
    /**
     * Returns the ACL access request endpoint.
     * 
     * @return endpoint resource
     */
    @Path("request access")
    public Class getRequestAccess()
    {
        return getProxyClass().orElse(RequestAccess.class);
    }

    /**
     * Returns content-addressed file item resource.
     * 
     * @return resource
     * @see com.atomgraph.linkeddatahub.apps.model.Application#UPLOADS_PATH
     */
    @Path("uploads/{sha1sum}")
    public Class getFileItem()
    {
        return getProxyClass().orElse(com.atomgraph.linkeddatahub.resource.upload.sha1.Item.class);
    }

//    /**
//     * Returns the endpoint for synchronous RDF imports.
//     * 
//     * @return endpoint resource
//     */
//    @Path("add")
//    public Class getAddEndpoint()
//    {
//        return getProxyClass().orElse(Add.class);
//    }
    
    /**
     * Returns the endpoint for synchronous RDF imports with a <code>CONSTRUCT</code> query transformation.
     * 
     * @return endpoint resource
     */
    @Path("transform")
    public Class getTransformEndpoint()
    {
        return getProxyClass().orElse(Transform.class);
    }
    
    /**
     * Returns the endpoint for container generation.
     *
     * @return endpoint resource
     */
    @Path("generate")
    public Class getGenerateEndpoint()
    {
        return getProxyClass().orElse(Generate.class);
    }
    
    /**
     * Returns the endpoint that allows clearing ontologies from cache by URI.
     * 
     * @return endpoint resource
     */
    @Path("clear")
    public Class getClearEndpoint()
    {
        return getProxyClass().orElse(Clear.class);
    }
    
    /**
     * Returns Google OAuth endpoint.
     * 
     * @return endpoint resource
     */
    @Path("oauth2/authorize/google")
    public Class getAuthorizeGoogle()
    {
        return getProxyClass().orElse(com.atomgraph.linkeddatahub.resource.admin.oauth2.google.Authorize.class);
    }

    /**
     * Returns OAuth login endpoint.
     * 
     * @return endpoint resource
     */
    @Path("oauth2/login")
    public Class getOAuth2Login()
    {
        return getProxyClass().orElse(com.atomgraph.linkeddatahub.resource.admin.oauth2.Login.class);
    }
    
    /**
     * Returns the default JAX-RS resource class.
     * 
     * @return resource class
     */
    public Class getDocumentClass()
    {
        return Graph.class;
    }
    
    /**
     * Returns request URI information.
     * 
     * @return URI info
     */
    public UriInfo getUriInfo()
    {
        return uriInfo;
    }

    /**
     * Returns the matched dataset (optional).
     * 
     * @return optional dataset
     */
    public Optional<Dataset> getDataset()
    {
        return dataset;
    }
    
    /**
     * Returns the system application.
     * 
     * @return JAX-RS application
     */
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }
    
}
