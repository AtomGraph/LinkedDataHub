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
package com.atomgraph.linkeddatahub.server.filter.request.auth;

import com.atomgraph.linkeddatahub.server.filter.request.AuthenticationFilter;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.core.io.ModelProvider;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.model.Agent;
import com.atomgraph.linkeddatahub.server.exception.auth.webid.InvalidWebIDPublicKeyException;
import com.atomgraph.linkeddatahub.server.exception.auth.webid.WebIDLoadingException;
import com.atomgraph.linkeddatahub.server.exception.auth.webid.WebIDDelegationException;
import com.atomgraph.linkeddatahub.server.security.AgentSecurityContext;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.linkeddatahub.vocabulary.Cert;
import com.atomgraph.linkeddatahub.vocabulary.FOAF;
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
import javax.ws.rs.ProcessingException;
import javax.ws.rs.client.Client;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.PreMatching;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.SecurityContext;
import org.apache.jena.datatypes.xsd.XSDDatatype;
import org.apache.jena.query.ParameterizedSparqlString;
import org.apache.jena.query.QueryExecution;
import org.apache.jena.query.ResultSet;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.vocabulary.RDF;
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

    /** Constant for <code>subjectAlternativeName</code> entry URI type */
    public static final int SAN_URI_NAME = 6;
    /** HTTP request header name that indicates WebID delegation */
    public static final String ON_BEHALF_OF = "On-Behalf-Of";
    
    private final MediaTypes mediaTypes = new MediaTypes();
    private final javax.ws.rs.core.MediaType[] acceptedTypes;
    
    @Context HttpServletRequest httpServletRequest;

    private ParameterizedSparqlString webIDQuery;

    /**
     * Constructs filter.
     */
    public WebIDFilter()
    {
        super();
        List<javax.ws.rs.core.MediaType> acceptedTypeList = new ArrayList();
        acceptedTypeList.addAll(mediaTypes.getReadable(Model.class));
        acceptedTypes = acceptedTypeList.toArray(javax.ws.rs.core.MediaType[]::new); 
    }
    
    /**
     * Post-construct initialization of resource.
     */
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
    
    @Override
    public SecurityContext authenticate(ContainerRequestContext request)
    {
        try
        {
            X509Certificate webIDCert = getWebIDCertificate(request);
            if (log.isTraceEnabled()) log.trace("Client WebID certificate: {}", webIDCert);
            if (webIDCert == null) return null;

            webIDCert.checkValidity(); // check if certificate is expired or not yet valid
            RSAPublicKey publicKey = (RSAPublicKey)webIDCert.getPublicKey();
            URI webID = getWebIDURI(webIDCert);
            if (webID == null)
            {
                if (log.isTraceEnabled()) log.trace("WebID not found in the client certificate, skipping WebID filter");
                return null;
            }
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
                if (agent.equals(principal) || principal.getModel().contains(agent, ACL.delegates, principal)) agent = principal;
                else throw new WebIDDelegationException(agent, principal);
            }

            // imitate type inference, otherwise we'll get Jena's polymorphism exception
            return new AgentSecurityContext(getScheme(), agent.addProperty(RDF.type, FOAF.Agent).as(Agent.class));
        }
        catch (CertificateException ex)
        {
            if (log.isErrorEnabled()) log.error("WebID certificate error (could not parse, expired or not yet valid)", ex);
            //throw new WebIDCertificateException(ex);
            return null;
        }
        catch (URISyntaxException ex)
        {
            if (log.isErrorEnabled()) log.error("Could not parse WebID URI: {}", ex.getInput(), ex);
            //throw new InvalidWebIDURIException(ex.getInput());
            return null;
        }
        catch (ProcessingException ex)
        {
            if (log.isErrorEnabled()) log.error("Could not load WebID URI", ex);
//            throw new WebIDLoadingException(ex, null);
            return null;
        }
    }

    /**
     * Retrieves WebID certificate from the container request context.
     * 
     * @param request request context
     * @return X509 certificate
     * @throws URISyntaxException WebID URI is malformed
     * @throws CertificateException certificate error
     * @throws CertificateParsingException certificate parsing error
     */
    public X509Certificate getWebIDCertificate(ContainerRequestContext request) throws URISyntaxException, CertificateException, CertificateParsingException
    {
        X509Certificate[] certs = (X509Certificate[])getHttpServletRequest().getAttribute("javax.servlet.request.X509Certificate");

        for (X509Certificate cert : certs)
            if (getWebIDURI(cert) != null) return cert;
        
        return null;
    }
    
    /**
     * Retrieves WebID URI from the given certificate's <code>subjectAlternativeName</code>.
     * 
     * @param cert X509 certificate
     * @return WebID URI
     * @throws URISyntaxException URI syntax error
     * @throws CertificateParsingException certificate parsing exception
     */
    public static URI getWebIDURI(X509Certificate cert) throws URISyntaxException, CertificateParsingException
    {
        if (cert.getSubjectAlternativeNames() != null)
        {
            List<?>[] sans = cert.getSubjectAlternativeNames().toArray(List<?>[]::new);
            if (sans.length > 0 && cert.getPublicKey() instanceof RSAPublicKey)
                for (List<?> san : sans)
                {
                    Object type = san.get(0);
                    if (Integer.valueOf(type.toString()).equals(SAN_URI_NAME))
                    {
                        Object value = san.get(1);
                        return new URI(value.toString());
                    }
                }
        }
        
        return null;
    }
    
    /**
     * Verifies the given public key against the given WebID profile document.
     * 
     * @param webIDModel WebID document model
     * @param webID WebID URI
     * @param publicKey RSA public key
     * @return agent resource
     */
    public Resource authenticate(Model webIDModel, URI webID, RSAPublicKey publicKey)
    {
        ParameterizedSparqlString pss = getWebIDQuery();
        pss.setLiteral("exp", ResourceFactory.createTypedLiteral(publicKey.getPublicExponent()));
        pss.setLiteral("mod", ResourceFactory.createTypedLiteral(publicKey.getModulus().toString(16), XSDDatatype.XSDhexBinary));

        try (QueryExecution qex = QueryExecution.create(pss.asQuery(), webIDModel))
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
  
    /**
     * Loads WebID document model for the given WebID URI.
     * Checks WebID cache first, falls back to dereferencing the WebID URI.
     * 
     * @param webID webID URI
     * @return WebID document model
     */
    public Model loadWebID(URI webID)
    {
        if (getSystem().getWebIDModelCache().containsKey(webID)) return getSystem().getWebIDModelCache().get(webID);
        
        Model model = loadWebIDFromURI(webID);
        
        return model;
    }
    
    /**
     * Loads WebID document model by dereferencing the given WebID URI.
     * 
     * @param webID WebID URI
     * @return document model
     */
    public Model loadWebIDFromURI(URI webID)
    {
        try
        {
            Model model = ModelFactory.createDefaultModel();
            
            // remove fragment identifier to get document URI
            URI webIDDoc = new URI(webID.getScheme(), webID.getSchemeSpecificPart(), null).normalize();
            
            try (Response cr1 = getClient().target(webIDDoc).
                    request(getAcceptableMediaTypes()).
                    get())
            {
                if (!cr1.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
                {
                    if (log.isErrorEnabled()) log.error("Could not load WebID Agent: {}", webID.toString());
                    throw new WebIDLoadingException(webID, cr1);
                }
                cr1.getHeaders().putSingle(ModelProvider.REQUEST_URI_HEADER, webIDDoc.toString()); // provide a base URI hint to ModelProvider
                model.add(cr1.readEntity(Model.class));
                
                Resource certKeyRes = model.createResource(webID.toString()).getPropertyResourceValue(Cert.key);
                // load PublicKey separately - only if it's a URI resource. If it's a blank node, its description should be present in the WebID model
                if (certKeyRes != null && certKeyRes.isURIResource())
                {
                    URI certKey = URI.create(certKeyRes.getURI());
                    // remove fragment identifier to get document URI
                    URI certKeyDoc = new URI(certKey.getScheme(), certKey.getSchemeSpecificPart(), null).normalize();

                    try (Response cr2 = getClient().target(certKeyDoc).
                            request(getAcceptableMediaTypes()).
                            get())
                    {
                        if (!cr2.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
                        {
                            if (log.isErrorEnabled()) log.error("Could not load WebID Key: {}", certKey.toString());
                            throw new WebIDLoadingException(webID, cr2);
                        }
                        cr2.getHeaders().putSingle(ModelProvider.REQUEST_URI_HEADER, certKey.toString()); // provide a base URI hint to ModelProvider
                        model.add(cr2.readEntity(Model.class));
                    }
                }
                
                return model;
            }
        }
        catch (URISyntaxException ex)
        {
            // can't happen
        }
        
        return null;
    }
    
    /**
     * Returns HTTP servlet request
     * 
     * @return servlet request
     */
    public HttpServletRequest getHttpServletRequest()
    {
        return httpServletRequest;
    }
    
    /**
     * Returns WebID verification query.
     * 
     * @return SPARQL query
     */
    public ParameterizedSparqlString getWebIDQuery()
    {
        return webIDQuery.copy();
    }
    
    /**
     * Returns HTTP client.
     * This client instance does not send the WebID client certificate.
     * 
     * @return HTTP client
     */
    public Client getClient()
    {
        return getSystem().getNoCertClient();
    }
    
    /**
     * Returns readable media types.
     * 
     * @return readable media types
     */
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