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
import static com.atomgraph.client.writer.ModelXSLTWriterBase.getSource;
import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.writer.factory.xslt.XsltExecutableSupplier;
import com.atomgraph.linkeddatahub.model.auth.Agent;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.linkeddatahub.vocabulary.LDH;
import com.atomgraph.linkeddatahub.vocabulary.LDHT;
import com.atomgraph.linkeddatahub.vocabulary.Google;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import com.atomgraph.client.vocabulary.LDT;
import com.atomgraph.core.vocabulary.SD;
import com.atomgraph.linkeddatahub.server.io.ValidatingModelProvider;
import com.atomgraph.linkeddatahub.server.security.AuthorizationContext;
import com.atomgraph.linkeddatahub.vocabulary.FOAF;
import com.atomgraph.linkeddatahub.vocabulary.LDHC;
import java.io.IOException;
import java.io.OutputStream;
import java.lang.annotation.Annotation;
import java.lang.reflect.Type;
import java.math.BigInteger;
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
import javax.inject.Inject;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.EntityTag;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.MultivaluedMap;
import javax.ws.rs.core.SecurityContext;
import javax.xml.transform.Source;
import javax.xml.transform.TransformerException;
import net.sf.saxon.s9api.QName;
import net.sf.saxon.s9api.SaxonApiException;
import net.sf.saxon.s9api.XdmAtomicValue;
import net.sf.saxon.s9api.XdmValue;
import net.sf.saxon.s9api.XsltExecutable;
import org.apache.http.HttpHeaders;
import org.apache.jena.ontology.OntModelSpec;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.StmtIterator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * XSLT writer subclass with LinkedDataHub specific parameters.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public abstract class ModelXSLTWriterBase extends com.atomgraph.client.writer.ModelXSLTWriterBase
{
    private static final Logger log = LoggerFactory.getLogger(ModelXSLTWriterBase.class);
    private static final Set<String> NAMESPACES;
    /** The relative URL of the RDF file with localized labels */
    public static final String TRANSLATIONS_PATH = "static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf";
    
    static
    {
        NAMESPACES = new HashSet<>();
        NAMESPACES.add(AC.NS);
        NAMESPACES.add(LDHT.NS);
    }
    
    @Context SecurityContext securityContext;

    @Inject com.atomgraph.linkeddatahub.Application system;
    @Inject javax.inject.Provider<com.atomgraph.linkeddatahub.apps.model.Application> application;
    @Inject javax.inject.Provider<DataManager> dataManager;
    @Inject javax.inject.Provider<XsltExecutableSupplier> xsltExecSupplier;
    @Inject javax.inject.Provider<List<Mode>> modes;
    @Inject javax.inject.Provider<ContainerRequestContext> crc;
    @Inject javax.inject.Provider<Optional<AuthorizationContext>> authorizationContext;

    private final MessageDigest messageDigest;
    
    /**
     * Constructs XSLT writer.
     * 
     * @param xsltExec compiled XSLT stylesheet
     * @param ontModelSpec ontology specification
     * @param dataManager RDF data manager
     * @param messageDigest message digest
     */
    public ModelXSLTWriterBase(XsltExecutable xsltExec, OntModelSpec ontModelSpec, DataManager dataManager, MessageDigest messageDigest)
    {
        super(xsltExec, ontModelSpec, dataManager); // this DataManager will be unused as we override getDataManager() with the injected (subclassed) one
        this.messageDigest = messageDigest;
    }
    
    @Override
    public void writeTo(Model model, Class<?> type, Type genericType, Annotation[] annotations, MediaType mediaType, MultivaluedMap<String, Object> headerMap, OutputStream entityStream) throws IOException
    {
        // authenticated agents get a different HTML representation and therefore a different entity tag
        if (headerMap.containsKey(HttpHeaders.ETAG) && headerMap.getFirst(HttpHeaders.ETAG) instanceof EntityTag && getSecurityContext() != null && getSecurityContext().getUserPrincipal() instanceof Agent)
        {
            EntityTag eTag = (EntityTag)headerMap.getFirst(HttpHeaders.ETAG);
            BigInteger eTagHash = new BigInteger(eTag.getValue(), 16);
            Agent agent = (Agent)getSecurityContext().getUserPrincipal();
            eTagHash = eTagHash.add(BigInteger.valueOf(agent.hashCode()));
            headerMap.replace(HttpHeaders.ETAG, Arrays.asList(new EntityTag(eTagHash.toString(16))));
        }
        
        super.writeTo(processWrite(model), type, type, annotations, mediaType, headerMap, entityStream);
    }
    
    @Override
    public <T extends XdmValue> Map<QName, XdmValue> getParameters(MultivaluedMap<String, Object> headerMap) throws TransformerException
    {
        Map<QName, XdmValue> params = super.getParameters(headerMap);

        try
        {
            params.put(new QName("ldh", LDH.absolutePath.getNameSpace(), LDH.absolutePath.getLocalName()), new XdmAtomicValue(getAbsolutePath()));
            params.put(new QName("ldh", LDH.requestUri.getNameSpace(), LDH.requestUri.getLocalName()), new XdmAtomicValue(getRequestURI()));
            if (getURI() != null) params.put(new QName("ac", AC.uri.getNameSpace(), AC.uri.getLocalName()), new XdmAtomicValue(getURI()));
            else params.put(new QName("ac", AC.uri.getNameSpace(), AC.uri.getLocalName()), new XdmAtomicValue(getAbsolutePath()));

            com.atomgraph.linkeddatahub.apps.model.Application app = getApplication().get();
            if (log.isDebugEnabled()) log.debug("Passing $lapp:Application to XSLT: <{}>", app);
            params.put(new QName("ldt", LDT.base.getNameSpace(), LDT.base.getLocalName()), new XdmAtomicValue(app.getBaseURI()));
            params.put(new QName("ldt", LDT.ontology.getNameSpace(), LDT.ontology.getLocalName()), new XdmAtomicValue(URI.create(app.getOntology().getURI())));
            params.put(new QName("lapp", LAPP.Application.getNameSpace(), LAPP.Application.getLocalName()),
                getXsltExecutable().getProcessor().newDocumentBuilder().build(getSource(getAppModel(app, true))));
            
            URI endpointURI = getLinkURI(headerMap, SD.endpoint);
            if (endpointURI != null) params.put(new QName("sd", SD.endpoint.getNameSpace(), SD.endpoint.getLocalName()), new XdmAtomicValue(endpointURI));
            
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

            if (getUriInfo().getQueryParameters().containsKey(LDH.createGraph.getLocalName()))
                params.put(new QName("ldh", LDH.createGraph.getNameSpace(), LDH.createGraph.getLocalName()),
                    new XdmAtomicValue(Boolean.valueOf(getUriInfo().getQueryParameters().getFirst(LDH.createGraph.getLocalName()))));

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

            Object localModel = getContainerRequestContext().getProperty(LDH.localGraph.getURI());
            if (localModel instanceof Model model)
                params.put(new QName("ldh", LDH.localGraph.getNameSpace(), LDH.localGraph.getLocalName()),
                    getXsltExecutable().getProcessor().newDocumentBuilder().build(getSource(model)));
            Object originalModel = getContainerRequestContext().getProperty(LDH.originalGraph.getURI());
            if (originalModel instanceof Model model)
                params.put(new QName("ldh", LDH.originalGraph.getNameSpace(), LDH.originalGraph.getLocalName()),
                    getXsltExecutable().getProcessor().newDocumentBuilder().build(getSource(model)));
            
            params.put(new QName("ldhc", LDHC.enableWebIDSignUp.getNameSpace(), LDHC.enableWebIDSignUp.getLocalName()), new XdmAtomicValue(getSystem().isEnableWebIDSignUp()));
            if (getSystem().getProperty(Google.clientID.getURI()) != null)
                params.put(new QName("google", Google.clientID.getNameSpace(), Google.clientID.getLocalName()), new XdmAtomicValue((String)getSystem().getProperty(Google.clientID.getURI())));
            
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
     * Hook for RDF model processing before write.
     * 
     * @param model RDF model
     * @return RDF model
     */
    public Model processWrite(Model model)
    {
        // show foaf:mbox in end-user apps
        if (getApplication().get().canAs(EndUserApplication.class)) return model;
        // show foaf:mbox for authenticated agents
        if (getSecurityContext() != null && getSecurityContext().getUserPrincipal() instanceof Agent) return model;

        // show foaf:mbox_sha1sum for all other agents (in admin apps)
        return ValidatingModelProvider.hashMboxes(getMessageDigest()).apply(model); // apply processing from superclasses
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
    public javax.inject.Provider<DataManager> getDataManagerProvider()
    {
        return dataManager;
    }
    
    @Override
    public URI getURI() throws URISyntaxException
    {
        return getURIParam(getUriInfo(), AC.uri.getLocalName());
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
    public javax.inject.Provider<com.atomgraph.linkeddatahub.apps.model.Application> getApplication()
    {
        return application;
    }

    /**
     * Returns optional ACL authorizationContext.
     * 
     * @return optional authorizationContext
     */
    public javax.inject.Provider<Optional<AuthorizationContext>> getAuthorizationContext()
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
    
}