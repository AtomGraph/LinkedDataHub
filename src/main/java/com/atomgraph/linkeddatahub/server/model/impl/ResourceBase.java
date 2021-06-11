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
package com.atomgraph.linkeddatahub.server.model.impl;

import com.atomgraph.client.vocabulary.AC;
import static com.atomgraph.core.MediaType.APPLICATION_SPARQL_QUERY_TYPE;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.core.vocabulary.SD;
import com.atomgraph.client.util.DataManager;
import com.atomgraph.linkeddatahub.client.SesameProtocolClient;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.model.ClientUriInfo;
import com.atomgraph.linkeddatahub.server.model.Patchable;
import com.atomgraph.linkeddatahub.vocabulary.APLT;
import com.atomgraph.processor.model.TemplateCall;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.query.*;
import org.apache.jena.rdf.model.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import javax.ws.rs.Path;
import javax.ws.rs.core.*;
import javax.ws.rs.core.Context;
import javax.ws.rs.ext.Providers;
import java.net.URI;
import java.util.*;
import javax.inject.Inject;
import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.HttpMethod;
import javax.ws.rs.OPTIONS;
import javax.ws.rs.PATCH;
import javax.ws.rs.client.Client;
import javax.ws.rs.client.Invocation;
import javax.ws.rs.container.ResourceContext;
import javax.ws.rs.core.Response.ResponseBuilder;
import org.apache.commons.lang3.StringUtils;
import org.apache.jena.update.UpdateRequest;
import org.glassfish.jersey.uri.UriComponent;

/**
 * LinkedDataHub JAX-RS resource implementation.
 * It handles requests by default, unless a more specific Linked Data Template matches.
 * It also serves the base class for all other resource implementations.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Path("/")
@Deprecated
public class ResourceBase extends com.atomgraph.server.model.impl.ResourceBase implements com.atomgraph.linkeddatahub.server.model.Resource, Patchable
{
    private static final Logger log = LoggerFactory.getLogger(ResourceBase.class);
    
    private final com.atomgraph.linkeddatahub.Application system;
    private final com.atomgraph.linkeddatahub.apps.model.Application application;
    private final DataManager dataManager;
    private final SecurityContext securityContext;
    private final Providers providers;
    private final ClientUriInfo clientUriInfo;
    
    @Inject HttpServletRequest httpServletRequest;

    @Inject
    public ResourceBase(@Context UriInfo uriInfo, ClientUriInfo clientUriInfo, @Context Request request, MediaTypes mediaTypes,
            Optional<Service> service, Optional<com.atomgraph.linkeddatahub.apps.model.Application> application,
            Optional<Ontology> ontology, Optional<TemplateCall> templateCall,
            @Context HttpHeaders httpHeaders, @Context ResourceContext resourceContext,
            @Context HttpServletRequest httpServletRequest, @Context SecurityContext securityContext,
            DataManager dataManager, @Context Providers providers,
            com.atomgraph.linkeddatahub.Application system)
    {
        this(uriInfo, clientUriInfo, request, mediaTypes,
            uriInfo.getAbsolutePath(),
            service.orElse(null), application.orElse(null),
            ontology.orElse(null), templateCall,
            httpHeaders, resourceContext,
            httpServletRequest, securityContext,
            dataManager, providers,
            system);
    }

    protected ResourceBase(final UriInfo uriInfo, final ClientUriInfo clientUriInfo, final Request request, final MediaTypes mediaTypes, final URI uri, 
            final Service service, final com.atomgraph.linkeddatahub.apps.model.Application application,
            final Ontology ontology, final Optional<TemplateCall> templateCall,
            final HttpHeaders httpHeaders, final ResourceContext resourceContext,
            final HttpServletRequest httpServletRequest, final SecurityContext securityContext,
            final DataManager dataManager, final Providers providers,
            final com.atomgraph.linkeddatahub.Application system)
    {
        super(uriInfo, request, mediaTypes, uri,
                service, application, ontology, templateCall,
                httpHeaders, resourceContext);
//        if (application == null) throw new IllegalArgumentException("Application cannot be null");
        if (securityContext == null) throw new IllegalArgumentException("SecurityContext cannot be null");
        if (dataManager == null) throw new IllegalArgumentException("DataManager cannot be null");
        if (providers == null) throw new IllegalArgumentException("Providers cannot be null");
        if (system == null) throw new IllegalArgumentException("System Application cannot be null");

        if (log.isDebugEnabled()) log.debug("Constructing {}", getClass());
        this.clientUriInfo = clientUriInfo;
        this.application = application;
        this.dataManager = dataManager;
        this.httpServletRequest = httpServletRequest;
        this.securityContext = securityContext;
        this.providers = providers;
        this.system = system;
        if (log.isDebugEnabled()) log.debug("UserPrincipal: {} ", securityContext.getUserPrincipal());
    }

    /**
     * Gets a list of media types that a writable for a message body class.
     * 
     * @param clazz message body class, normally <code>Dataset.class</code> or <code>Model.class</code>
     * @return list of media types
     */
    @Override
    public List<MediaType> getWritableMediaTypes(Class clazz)
    {
        // restrict writable MediaTypes to the requested one (usually by RDF export feature)
        if (getClientUriInfo().getQueryParameters().containsKey(AC.accept.getLocalName())) // TO-DO: move to ResourceFilter?
        {
            String accept = getClientUriInfo().getQueryParameters().getFirst(AC.accept.getLocalName());
            
            MediaType mediaType = MediaType.valueOf(accept); // parse value
            mediaType = new MediaType(mediaType.getType(), mediaType.getSubtype(), MediaTypes.UTF8_PARAM); // set charset=UTF-8
            return Arrays.asList(mediaType);
        }

        return super.getWritableMediaTypes(clazz);
    }
    
    /**
     * Overrides <code>OPTIONS</code> HTTP header values.
     * Specifies allowed methods.
     * 
     * @return HTTP response
     */
    @OPTIONS
    public Response options()
    {
        ResponseBuilder rb = Response.ok().
            header(HttpHeaders.ALLOW, HttpMethod.GET).
            header(HttpHeaders.ALLOW, HttpMethod.POST).
            header(HttpHeaders.ALLOW, HttpMethod.PUT).
            header(HttpHeaders.ALLOW, HttpMethod.DELETE);
        
        String acceptWritable = StringUtils.join(getWritableMediaTypes(Model.class), ",");
        rb.header("Accept-Post", acceptWritable);
        
        return rb.build();
        
    }
    
    /**
     * Handles HTTP <code>GET</code> method and returns response.
     * Adds support for some system parameters on top of the default LDT implementation.
     * 
     * @return HTTP response
     */
    @Override
    public Response get()
    {
        if (getTemplateCall().isPresent() && getTemplateCall().get().hasArgument(APLT.debug.getLocalName(), SD.SPARQL11Query))
        {
            if (log.isDebugEnabled()) log.debug("Returning SPARQL query string as debug response");
            return Response.ok(getQuery().toString()).
                    type(new MediaType(APPLICATION_SPARQL_QUERY_TYPE.getType(), APPLICATION_SPARQL_QUERY_TYPE.getType(), MediaTypes.UTF8_PARAM)).
                    build();
        }
        
        return super.get();
    }
//    
//    @Override
//    public Date getLastModified(Model model)
//    {
//        if (model == null) throw new IllegalArgumentException("Model cannot be null");
//        
//        List<Date> dates = new ArrayList<>();
//
//        NodeIterator createdIt = model.listObjectsOfProperty(getOntResource(), DCTerms.created);
//        try
//        {
//            while (createdIt.hasNext())
//            {
//                RDFNode object = createdIt.next();
//                if (object.isLiteral() && object.asLiteral().getValue() instanceof XSDDateTime)
//                    dates.add(((XSDDateTime)object.asLiteral().getValue()).asCalendar().getTime());
//            }
//        }
//        finally
//        {
//            createdIt.close();
//        }
//
//        NodeIterator modifiedIt = model.listObjectsOfProperty(getOntResource(), DCTerms.modified);
//        try
//        {
//            while (modifiedIt.hasNext())
//            {
//                RDFNode object = modifiedIt.next();
//                if (object.isLiteral() && object.asLiteral().getValue() instanceof XSDDateTime)
//                    dates.add(((XSDDateTime)object.asLiteral().getValue()).asCalendar().getTime());
//            }
//        }
//        finally
//        {
//            modifiedIt.close();
//        }
//        
//        if (!dates.isEmpty()) return Collections.max(dates);
//        
//        return null;
//    }

    @PATCH
    @Override
    public Response patch(UpdateRequest updateRequest)
    {
        // TO-DO: do a check that the update only uses this named graph
        getService().getEndpointAccessor().update(updateRequest, Collections.<URI>emptyList(), Collections.<URI>emptyList());
        
        return Response.ok().build();
    }
    
    /**
     * Bans up to 2 request URLs from Varnish proxy cache
     * @param resources request URLs
     * @return response from the proxy
     * @see <a href="https://varnish-cache.org/docs/trunk/users-guide/purging.html#bans">Purging and banning</a>
     */
    public Response ban(org.apache.jena.rdf.model.Resource... resources)
    {
        if (resources == null) throw new IllegalArgumentException("Resource cannot be null");
        
        if (getApplication().getService().getProxy() != null)
        {
            // create new Client instance, otherwise ApacheHttpClient reuses connection and Varnish ignores BAN request
            Invocation.Builder builder = getClient().target(getApplication().getService().getProxy().getURI()).request();

            for (Resource resource : resources)
                if (resource != null)
                {
                    // make URIs relative *iff* they will appear in SPARQL queries with BASE
                    URI uri = URI.create(resource.getURI());

                    // encode the URI, because that is how it will appear in SPARQL Protocol URLs cached by the backend proxy
                    builder = builder.header("X-Escaped-Request-URI", UriComponent.encode(uri.toString(), UriComponent.Type.UNRESERVED));
                }

            return builder.method("BAN", Response.class);
        }

        return null;
    }
    
    /**
     * Retrieves RDF description of the resource that is being requested.
     * The description is the result of a SPARQL query execution on the application's service.
     * Variable bindings are either applied to the query string or sent separately as parameters, depending on the service capabilities.
     * 
     * @return RDF dataset
     */
    @Override
    public Model describe()
    {
        // send query bindings separately from the query if the service supports the Sesame protocol
        if (getService().getSPARQLClient() instanceof SesameProtocolClient)
        {
            // get the original query string without applied bindings
            Query query = new ParameterizedSparqlString(getTemplateCall().get().getTemplate().getQuery().as(com.atomgraph.spinrdf.model.Query.class).getText(),
                getUriInfo().getBaseUri().toString()).asQuery();
            
            try (Response cr = ((SesameProtocolClient)getService().getSPARQLClient()).query(query, Model.class, getQuerySolutionMap(), new MultivaluedHashMap()))
            {
                return cr.readEntity(Model.class);
            }
        }
        else
        {
            try (Response cr = getService().getSPARQLClient().query(getQuery(), Model.class, new MultivaluedHashMap()))
            {
                return cr.readEntity(Model.class);
            }
        }
    }
    
    /**
     * Returns the value of the <code>Cache-Control</code> HTTP response header.
     * 
     * @return cache control value
     */
//    @Override
//    public CacheControl getCacheControl()
//    {
//        if (getTemplateCall().get().hasArgument(APLT.forClass))
//            return CacheControl.valueOf("no-cache"); // do not cache instance pages
//        
//        return super.getCacheControl();
//    }
    
    /**
     * Get supported (readable/writable) media types.
     * 
     * @return 
     */
    @Override
    public MediaTypes getMediaTypes()
    {
        return getSystem().getMediaTypes();
    }

    public ClientUriInfo getClientUriInfo()
    {
        return clientUriInfo;
    }
    
    public DataManager getDataManager()
    {
        return dataManager;
    }
    
    public HttpServletRequest getHttpServletRequest()
    {
        return httpServletRequest;
    }
    
    public SecurityContext getSecurityContext()
    {
        return securityContext;
    }

    public Providers getProviders()
    {
        return providers;
    }
  
    @Override
    public com.atomgraph.linkeddatahub.apps.model.Application getApplication()
    {
        return application;
    }

    @Override
    public com.atomgraph.linkeddatahub.model.Service getService()
    {
        return getApplication().getService();
    }
    
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }
 
    public Client getClient()
    {
        return getSystem().getClient();
    }
    
}