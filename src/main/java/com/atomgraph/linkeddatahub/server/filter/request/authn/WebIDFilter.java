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
package com.atomgraph.linkeddatahub.server.filter.request.authn;

import com.atomgraph.linkeddatahub.server.filter.request.AuthenticationFilter;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.core.io.ModelProvider;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.exception.auth.InvalidWebIDPublicKeyException;
import com.atomgraph.linkeddatahub.exception.auth.InvalidWebIDURIException;
import com.atomgraph.linkeddatahub.exception.auth.WebIDCertificateException;
import com.atomgraph.linkeddatahub.exception.auth.WebIDLoadingException;
import com.atomgraph.linkeddatahub.exception.auth.WebIDDelegationException;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import java.net.URI;
import java.net.URISyntaxException;
import java.security.cert.CertificateException;
import java.security.cert.CertificateParsingException;
import java.security.cert.X509Certificate;
import java.security.interfaces.RSAPublicKey;
import java.util.ArrayList;
import java.util.List;
import javax.annotation.PostConstruct;
import javax.annotation.Priority;
import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.Priorities;
import javax.ws.rs.client.Client;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.PreMatching;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.SecurityContext;
import org.apache.jena.datatypes.xsd.XSDDatatype;
import org.apache.jena.query.ParameterizedSparqlString;
import org.apache.jena.query.QueryExecution;
import org.apache.jena.query.QueryExecutionFactory;
import org.apache.jena.query.ResultSet;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * WebID authentication request filter.
 * Queries for matching authorizations using SPARQL query against administrative service.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@PreMatching
@Priority(Priorities.USER) // has to execute after HttpMethodOverrideFilter which has @Priority(Priorities.HEADER_DECORATOR + 50)
public class WebIDFilter extends AuthenticationFilter
{
    
    private static final Logger log = LoggerFactory.getLogger(WebIDFilter.class);

    public static final int SNA_URI_NAME = 6;
    public static final String ON_BEHALF_OF = "On-Behalf-Of";
    
    private final MediaTypes mediaTypes = new MediaTypes();
    private final javax.ws.rs.core.MediaType[] acceptedTypes;
    
    @Context HttpServletRequest httpServletRequest;

    private ParameterizedSparqlString webIDQuery;

    public WebIDFilter()
    {
        super();
        List<javax.ws.rs.core.MediaType> acceptedTypeList = new ArrayList();
        acceptedTypeList.addAll(mediaTypes.getReadable(Model.class));
        acceptedTypes = acceptedTypeList.toArray(new javax.ws.rs.core.MediaType[acceptedTypeList.size()]); 
    }
    
    @PostConstruct
    public void init()
    {
        webIDQuery = new ParameterizedSparqlString(getSystem().getWebIDQuery().toString());
    }
    
    @Override
    public String getScheme()
    {
        return SecurityContext.CLIENT_CERT_AUTH;
    }

//    @Override
//    public void filter(ContainerRequestContext request)
//    {
//        if (request == null) throw new IllegalArgumentException("ContainerRequestContext cannot be null");
//        if (log.isDebugEnabled()) log.debug("Authenticating request URI: {}", request.getUriInfo().getRequestUri());
//
//        // skip filter if user already authorized
//        if (request.getSecurityContext().getUserPrincipal() != null) return;
//        // skip filter if no application has matched
//        if (getApplication() == null) return;
//
//        // logout not really possible with HTTP certificates
//        //if (isLogoutForced(request, getScheme())) logout(app, request);
//    }
    
    @Override
    public Resource authenticate(ContainerRequestContext request)
    {
        X509Certificate[] certs = (X509Certificate[])getHttpServletRequest().getAttribute("javax.servlet.request.X509Certificate");
        if (certs == null) return null;

        try
        {
            X509Certificate webIDCert = null;
            for (X509Certificate cert : certs)
                if (getWebIDURI(cert) != null) webIDCert = cert;

            if (log.isTraceEnabled()) log.trace("Client WebID certificate: {}", webIDCert);
            if (webIDCert == null) return null;

            webIDCert.checkValidity(); // check if certificate is expired or not yet valid
            RSAPublicKey publicKey = (RSAPublicKey)webIDCert.getPublicKey();
            URI webID = getWebIDURI(webIDCert);
            if (log.isTraceEnabled()) log.trace("Client WebID: {}", webID);

            Resource agent = authenticate(loadWebID(webID), webID, publicKey);
            if (agent == null)
            {
                if (log.isErrorEnabled()) log.error("Client certificate public key did not match WebID public key: {}", webID);
                throw new InvalidWebIDPublicKeyException(publicKey, webID.toString());
            }
            getSystem().getWebIDModelCache().put(webID, agent.getModel()); // now it's safe to cache the WebID Model

            String onBehalfOf = request.getHeaderString(ON_BEHALF_OF);
            if (onBehalfOf != null)
            {
                URI principalWebID = new URI(onBehalfOf);
                Model principalWebIDModel = loadWebID(principalWebID);
                Resource principal = principalWebIDModel.createResource(onBehalfOf);
                // if we verify that the current agent is a secretary of the principal, that principal becomes current agent. Else throw error
                if (agent.equals(principal) || agent.getModel().contains(agent, ACL.delegates, principal)) agent = principal;
                else throw new WebIDDelegationException(agent, principal);
            }

            return agent;
        }
        catch (CertificateException ex)
        {
            if (log.isErrorEnabled()) log.error("WebID certificate error (could not parse, expired or not yet valid)", ex);
            throw new WebIDCertificateException(ex);
        }
        catch (URISyntaxException ex)
        {
            if (log.isErrorEnabled()) log.error("Could not parse WebID URI: {}", ex.getInput(), ex);
            throw new InvalidWebIDURIException(ex.getInput());
        }
    }

    public static URI getWebIDURI(X509Certificate cert) throws URISyntaxException, CertificateParsingException
    {
        if (cert.getSubjectAlternativeNames() != null)
        {
            List<?>[] snas = cert.getSubjectAlternativeNames().toArray(new List<?>[0]);
            if (snas.length > 0 && cert.getPublicKey() instanceof RSAPublicKey)
                for (List<?> sna : snas)
                {
                    Object type = sna.get(0);
                    if (Integer.valueOf(type.toString()).equals(SNA_URI_NAME))
                    {
                        Object value = sna.get(1);
                        return new URI(value.toString());
                    }
                }
        }
        
        return null;
    }
    
    public Resource authenticate(Model webIDModel, URI webID, RSAPublicKey publicKey)
    {
        ParameterizedSparqlString pss = getWebIDQuery();
        pss.setLiteral("exp", ResourceFactory.createTypedLiteral(publicKey.getPublicExponent()));
        pss.setLiteral("mod", ResourceFactory.createTypedLiteral(publicKey.getModulus().toString(16), XSDDatatype.XSDhexBinary));

        try (QueryExecution qex = QueryExecutionFactory.create(pss.asQuery(), webIDModel))
        {
            ResultSet resultSet = qex.execSelect();
            if (resultSet.hasNext())
            {
                Resource agent = resultSet.next().getResource("webid");
                if (agent != null && agent.isURIResource() && agent.getURI().equals(webID.toString()))
                    return agent; // ?webid with matching key values is our WebID agent
            }
        }

        return null;
    }
  
    public Model loadWebID(URI webID)
    {
        if (getSystem().getWebIDModelCache().containsKey(webID)) return getSystem().getWebIDModelCache().get(webID);
        
        Model model = loadWebIDFromURI(webID);
        
        return model;
    }
    
    public Model loadWebIDFromURI(URI webID)
    {
        try
        {
            // remove fragment identifier to get document URI
            URI webIDDoc = new URI(webID.getScheme(), webID.getSchemeSpecificPart(), null).normalize();
            
            try (Response cr = getNoCertClient().target(webIDDoc).
                    request(getAcceptableMediaTypes()).
                    get())
            {
                if (!cr.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
                {
                    if (log.isErrorEnabled()) log.error("Could not load WebID: {}", webID.toString());
                    throw new WebIDLoadingException(webID, cr);
                }
                cr.getHeaders().putSingle(ModelProvider.REQUEST_URI_HEADER, webIDDoc.toString()); // provide a base URI hint to ModelProvider

                return cr.readEntity(Model.class);
            }
        }
        catch (URISyntaxException ex)
        {
            // can't happen
        }
        
        return null;
    }
    
//    @Override
//    public boolean isApplied(com.atomgraph.linkeddatahub.apps.model.Application app, ContainerRequestContext request)
//    {
//        return true;
//    }
    
    public HttpServletRequest getHttpServletRequest()
    {
        return httpServletRequest;
    }
    
    public ParameterizedSparqlString getWebIDQuery()
    {
        return webIDQuery.copy();
    }
    
    public Client getNoCertClient()
    {
        return getSystem().getNoCertClient();
    }
    
    public javax.ws.rs.core.MediaType[] getAcceptableMediaTypes()
    {
        return acceptedTypes;
    }

    @Override
    public void login(Application app, ContainerRequestContext request)
    {
        throw new UnsupportedOperationException("Not supported yet."); // login is controlled by the browser
    }

    @Override
    public void logout(Application app, ContainerRequestContext request)
    {
        throw new UnsupportedOperationException("Not supported yet."); // logout not really possible with HTTP certificates
    }
    
}