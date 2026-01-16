/*
 * Copyright 2020 Martynas Jusevičius <martynas@atomgraph.com>.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.atomgraph.linkeddatahub.writer;

import com.atomgraph.client.util.DataManager;
import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.writer.factory.xslt.XsltExecutableSupplier;
import com.atomgraph.linkeddatahub.model.auth.Agent;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.linkeddatahub.vocabulary.LDH;
import com.atomgraph.linkeddatahub.vocabulary.LDHT;
import com.atomgraph.linkeddatahub.vocabulary.Google;
import com.atomgraph.linkeddatahub.vocabulary.ORCID;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import com.atomgraph.client.vocabulary.LDT;
import com.atomgraph.core.util.Link;
import com.atomgraph.core.vocabulary.SD;
import com.atomgraph.linkeddatahub.server.security.AuthorizationContext;
import com.atomgraph.linkeddatahub.vocabulary.FOAF;
import com.atomgraph.linkeddatahub.vocabulary.LDHC;
import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.security.MessageDigest;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;
import jakarta.inject.Inject;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.core.SecurityContext;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import javax.xml.transform.Source;
import javax.xml.transform.TransformerException;
import javax.xml.transform.stream.StreamSource;
import net.sf.saxon.s9api.QName;
import net.sf.saxon.s9api.SaxonApiException;
import net.sf.saxon.s9api.XdmAtomicValue;
import net.sf.saxon.s9api.XdmValue;
import net.sf.saxon.s9api.XsltExecutable;
import org.apache.http.HttpHeaders;
import org.apache.jena.ontology.ObjectProperty;
import org.apache.jena.ontology.OntModelSpec;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.StmtIterator;
import org.apache.jena.riot.RDFLanguages;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * XSLT writer subclass with LinkedDataHub specific parameters.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public abstract class XSLTWriterBase extends com.atomgraph.client.writer.XSLTWriterBase
{
    private static final Logger log = LoggerFactory.getLogger(XSLTWriterBase.class);
    private static final Set<String> NAMESPACES;
    /** The relative URL of the RDF file with localized labels */
    public static final String TRANSLATIONS_PATH = "static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf";
    /** System property name for the XSLT system ID. */
    public static final String SYSTEM_ID_PROPERTY = "com.atomgraph.linkeddatahub.writer.XSLTWriterBase.systemId";
    
    static
    {
        NAMESPACES = new HashSet<>();
        NAMESPACES.add(AC.NS);
        NAMESPACES.add(LDHT.NS);
    }
    
    @Context SecurityContext securityContext;

    @Inject com.atomgraph.linkeddatahub.Application system;
    @Inject jakarta.inject.Provider<Optional<com.atomgraph.linkeddatahub.apps.model.Application>> application;
    @Inject jakarta.inject.Provider<DataManager> dataManager;
    @Inject jakarta.inject.Provider<XsltExecutableSupplier> xsltExecSupplier;
    @Inject jakarta.inject.Provider<List<Mode>> modes;
    @Inject jakarta.inject.Provider<ContainerRequestContext> crc;
    @Inject jakarta.inject.Provider<Optional<AuthorizationContext>> authorizationContext;

    private final MessageDigest messageDigest;
    
    /**
     * Constructs XSLT writer.
     * 
     * @param xsltExec compiled XSLT stylesheet
     * @param ontModelSpec ontology specification
     * @param dataManager RDF data manager
     * @param messageDigest message digest
     */
    public XSLTWriterBase(XsltExecutable xsltExec, OntModelSpec ontModelSpec, DataManager dataManager, MessageDigest messageDigest)
    {
        super(xsltExec, ontModelSpec, dataManager); // this DataManager will be unused as we override getDataManager() with the injected (subclassed) one
        this.messageDigest = messageDigest;
    }

    @Override
    public <T extends XdmValue> Map<QName, XdmValue> getParameters(MultivaluedMap<String, Object> headerMap) throws TransformerException
    {
        Map<QName, XdmValue> params = super.getParameters(headerMap);

        try
        {
            params.put(new QName("ldh", LDH.requestUri.getNameSpace(), LDH.requestUri.getLocalName()), new XdmAtomicValue(getRequestURI()));
            if (getURI() != null) params.put(new QName("ac", AC.uri.getNameSpace(), AC.uri.getLocalName()), new XdmAtomicValue(getURI()));
            else params.put(new QName("ac", AC.uri.getNameSpace(), AC.uri.getLocalName()), new XdmAtomicValue(getRequestURI()));

            Optional<com.atomgraph.linkeddatahub.apps.model.Application> appOpt = getApplication().get();
            if (!appOpt.isPresent())
            {
                if (log.isWarnEnabled()) log.warn("Application not present in XSLTWriterBase.getParameters()");
                return params; // return early if no application
            }

            com.atomgraph.linkeddatahub.apps.model.Application app = appOpt.get();
            if (log.isDebugEnabled()) log.debug("Passing $lapp:Application to XSLT: <{}>", app);
            params.put(new QName("ldt", LDT.base.getNameSpace(), LDT.base.getLocalName()), new XdmAtomicValue(app.getBaseURI()));
            params.put(new QName("lapp", LAPP.origin.getNameSpace(), LAPP.origin.getLocalName()), new XdmAtomicValue(app.getOriginURI()));
            params.put(new QName("ldt", LDT.ontology.getNameSpace(), LDT.ontology.getLocalName()), new XdmAtomicValue(URI.create(app.getOntology().getURI())));
            params.put(new QName("lapp", LAPP.Application.getNameSpace(), LAPP.Application.getLocalName()),
                getXsltExecutable().getProcessor().newDocumentBuilder().build(getSource(getAppModel(app, true))));
            
            URI endpointURI = getLinkURI(headerMap, SD.endpoint);
            if (endpointURI != null) params.put(new QName("sd", SD.endpoint.getNameSpace(), SD.endpoint.getLocalName()), new XdmAtomicValue(endpointURI));
            
            String forShapeURI = getUriInfo().getQueryParameters().getFirst(LDH.forShape.getLocalName());
            if (forShapeURI != null) params.put(new QName("ldh", LDH.forShape.getNameSpace(), LDH.forShape.getLocalName()), new XdmAtomicValue(URI.create(forShapeURI)));

            if (getSecurityContext() != null && getSecurityContext().getUserPrincipal() instanceof Agent)
            {
                Agent agent = (Agent)getSecurityContext().getUserPrincipal();
                if (log.isDebugEnabled()) log.debug("Passing $foaf:Agent to XSLT: <{}>", agent);
                Source source = getSource(agent.getModel());
                
                URI agentURI = URI.create(agent.getURI());
                URI agentDocUri = new URI(agentURI.getScheme(), agentURI.getSchemeSpecificPart(), null); // strip the fragment identifier
                source.setSystemId(agentDocUri.toString()); // URI accessible via document-uri($foaf:Agent)

                params.put(new QName("acl", ACL.agent.getNameSpace(), ACL.agent.getLocalName()),
                    new XdmAtomicValue(URI.create(agent.getURI())));
                params.put(new QName("foaf", FOAF.Agent.getNameSpace(), FOAF.Agent.getLocalName()),
                    getXsltExecutable().getProcessor().newDocumentBuilder().build(source));
            }
            if (getAuthorizationContext().get().isPresent())
                params.put(new QName("acl", ACL.mode.getNameSpace(), ACL.mode.getLocalName()),
                    XdmValue.makeSequence(getAuthorizationContext().get().get().getModeURIs()));

            // TO-DO: move to client-side?
            if (getUriInfo().getQueryParameters().containsKey(LDH.access_to.getLocalName()))
                params.put(new QName("ldh", LDH.access_to.getNameSpace(), LDH.access_to.getLocalName()),
                    new XdmAtomicValue(URI.create(getUriInfo().getQueryParameters().getFirst(LDH.access_to.getLocalName()))));
            
            if (getHttpHeaders().getRequestHeader(HttpHeaders.REFERER) != null)
            {
                URI referer = URI.create(getHttpHeaders().getRequestHeader(HttpHeaders.REFERER).get(0));
                if (log.isDebugEnabled()) log.debug("Passing $Referer URI to XSLT: {}", referer);
                params.put(new QName("", "", "Referer"), new XdmAtomicValue(referer)); // TO-DO: move to ac: namespace
            }
            
            params.put(new QName("ldhc", LDHC.enableWebIDSignUp.getNameSpace(), LDHC.enableWebIDSignUp.getLocalName()), new XdmAtomicValue(getSystem().isEnableWebIDSignUp()));
            if (getSystem().getProperty(Google.clientID.getURI()) != null)
                params.put(new QName("google", Google.clientID.getNameSpace(), Google.clientID.getLocalName()), new XdmAtomicValue((String)getSystem().getProperty(Google.clientID.getURI())));
            if (getSystem().getProperty(ORCID.clientID.getURI()) != null)
                params.put(new QName("orcid", ORCID.clientID.getNameSpace(), ORCID.clientID.getLocalName()), new XdmAtomicValue((String)getSystem().getProperty(ORCID.clientID.getURI())));

            return params;
        }
        catch (IOException | URISyntaxException | SaxonApiException ex)
        {
            if (log.isErrorEnabled()) log.error("Error reading Source stream");
            throw new TransformerException(ex);
        }
    }
    /**
     * Returns RDF model of the specified application.
     * 
     * @param app application resource
     * @param includeEndUserAdmin true if paired app's description should be included as well
     * @return RDF model
     */
    public Model getAppModel(Application app, boolean includeEndUserAdmin)
    {
        StmtIterator appStmts = app.listProperties();
        Model model = ModelFactory.createDefaultModel().add(appStmts);
        appStmts.close();

        if (includeEndUserAdmin)
        {
            // for AdminApplication, add EndUserApplication statements, and the way around
            if (app.canAs(AdminApplication.class))
            {
                AdminApplication adminApp = app.as(AdminApplication.class);
                StmtIterator endUserAppStmts = adminApp.getEndUserApplication().listProperties();
                model.add(endUserAppStmts);
                endUserAppStmts.close();
            }
            // for EndUserApplication, add AdminApplication statements
            if (app.canAs(EndUserApplication.class))
            {
                EndUserApplication endUserApp = app.as(EndUserApplication.class);
                StmtIterator adminApp = endUserApp.getAdminApplication().listProperties();
                model.add(adminApp);
                adminApp.close();
            }
        }
        
        return model;
    }

    /**
     * Override the Web-Client's implementation because LinkedDataHub concatenates <code>Link</code> headers into a single value.
     * 
     * @param headerMap response headers
     * @param property rel property
     * @return filtered headers
     * @see com.atomgraph.linkeddatahub.server.filter.response.ResponseHeadersFilter
     */
    @Override
    public URI getLinkURI(MultivaluedMap<String, Object> headerMap, ObjectProperty property)
    {
        if (headerMap.get(jakarta.ws.rs.core.HttpHeaders.LINK) == null) return null;
        
        List<String> linkTokens = Arrays.asList(headerMap.get(jakarta.ws.rs.core.HttpHeaders.LINK).get(0).toString().split(","));
        
        List<URI> baseLinks = linkTokens.stream().
            map((String header) ->
            {
                try
                {
                    return Link.valueOf(header.trim());
                }
                catch (URISyntaxException ex)
                {
                    if (log.isWarnEnabled()) log.warn("Could not parse Link URI", ex);
                    return null;
                }
            }).
            filter(link -> link != null && link.getRel() != null && link.getRel().equals(property.getURI())).
            map(link -> link.getHref()).
            collect(Collectors.toList());

        if (!baseLinks.isEmpty()) return baseLinks.get(0);

        return null;
    }
    
    /**
     * Creates stream source from RDF model.
     * The model is serialized using the RDF/XML syntax.
     * 
     * @param model RDF model
     * @return XML stream source
     * @throws IOException I/O error
     */
    public StreamSource getSource(Model model) throws IOException
    {
        if (model == null) throw new IllegalArgumentException("Model cannot be null");

        try (ByteArrayOutputStream stream = new ByteArrayOutputStream())
        {
            model.write(stream, RDFLanguages.RDFXML.getName(), null);
            return new StreamSource(new ByteArrayInputStream(stream.toByteArray()));
        }
    }
    
    /**
     * Returns the base URI of the main RDF/XML document being transformed.
     * 
     * @return base URL
     */
    @Override
    public String getSystemId()
    {
        if (getContainerRequestContext().hasProperty(SYSTEM_ID_PROPERTY))
            return getContainerRequestContext().getProperty(SYSTEM_ID_PROPERTY).toString();
        
        return null;
    }
    
    /**
     * Returns system application.
     * 
     * @return JAX-RS application
     */
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }
    
    @Override
    public OntModelSpec getOntModelSpec()
    {
        return getSystem().getOntModelSpec();
    }
    
    /**
     * Returns JAX-RS security context.
     * 
     * @return security context
     */
    public SecurityContext getSecurityContext()
    {
        return securityContext;
    }
    
    @Override
    public DataManager getDataManager()
    {
        return getDataManagerProvider().get();
    }

    /**
     * Returns a JAX-RS provider for the RDF data manager.
     *
     * @return provider
     */
    public jakarta.inject.Provider<DataManager> getDataManagerProvider()
    {
        return dataManager;
    }

    @Override
    public String getQuery()
    {
        if (getUriInfo().getQueryParameters().containsKey(AC.query.getLocalName()))
            return getUriInfo().getQueryParameters().getFirst(AC.query.getLocalName());
        
        return null;
    }

    @Override
    public XsltExecutable getXsltExecutable()
    {
        return xsltExecSupplier.get().get();
    }
    
    @Override
    public List<URI> getModes(Set<String> namespaces)
    {
        return getModes().stream().map(Mode::get).collect(Collectors.toList());
    }

    /**
     * Returns a list of enabled layout modes.
     * 
     * @return list of modes
     */
    public List<Mode> getModes()
    {
        return modes.get();
    }
    
    @Override
    public Set<String> getSupportedNamespaces()
    {
        return NAMESPACES;
    }

    /**
     * Returns a JAX-RS provider for the current application.
     *
     * @return provider
     */
    public jakarta.inject.Provider<Optional<com.atomgraph.linkeddatahub.apps.model.Application>> getApplication()
    {
        return application;
    }

    /**
     * Returns optional ACL authorizationContext.
     * 
     * @return optional authorizationContext
     */
    public jakarta.inject.Provider<Optional<AuthorizationContext>> getAuthorizationContext()
    {
        return authorizationContext;
    }
    
    /**
     * Returns message digest.
     * 
     * @return digest
     */
    public MessageDigest getMessageDigest()
    {
        return messageDigest;
    }
    
    /**
     * Returns request context.
     * 
     * @return request context
     */
    public ContainerRequestContext getContainerRequestContext()
    {
        return crc.get();
    }
    
    /**
     * Returns the base URI of this LinkedDataHub instance.
     * It equals to the base URI of the root dataspace.
     *
     * @return root context URI
     */
    @Override
    public URI getContextURI()
    {
        return getSystem().getBaseURI();
    }
    
}