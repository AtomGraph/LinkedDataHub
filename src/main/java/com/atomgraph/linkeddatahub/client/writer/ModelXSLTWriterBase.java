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
package com.atomgraph.linkeddatahub.client.writer;

import com.atomgraph.client.util.DataManager;
import com.atomgraph.client.vocabulary.AC;
import static com.atomgraph.client.writer.ModelXSLTWriterBase.getSource;
import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.client.factory.xslt.XsltExecutableSupplier;
import com.atomgraph.linkeddatahub.model.Agent;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.linkeddatahub.vocabulary.APL;
import com.atomgraph.linkeddatahub.vocabulary.APLT;
import com.atomgraph.linkeddatahub.vocabulary.FOAF;
import com.atomgraph.linkeddatahub.vocabulary.Google;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import com.atomgraph.client.vocabulary.LDT;
import java.io.IOException;
import java.io.OutputStream;
import java.lang.annotation.Annotation;
import java.lang.reflect.Type;
import java.math.BigInteger;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import javax.inject.Inject;
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
import org.apache.jena.ontology.Ontology;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.StmtIterator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public abstract class ModelXSLTWriterBase extends com.atomgraph.client.writer.ModelXSLTWriterBase
{
    private static final Logger log = LoggerFactory.getLogger(ModelXSLTWriterBase.class);
    
    private static final Set<String> NAMESPACES;
    
    static
    {
        NAMESPACES = new HashSet<>();
        NAMESPACES.add(AC.NS);
        NAMESPACES.add(APLT.NS);
    }
    
    @Context SecurityContext securityContext;

    @Inject com.atomgraph.linkeddatahub.Application system;
    @Inject javax.inject.Provider<Optional<Application>> application;
    @Inject javax.inject.Provider<Optional<Ontology>> ontology;
    @Inject javax.inject.Provider<DataManager> dataManager;
    @Inject javax.inject.Provider<XsltExecutableSupplier> xsltExecSupplier;

    public ModelXSLTWriterBase(XsltExecutable xsltExec, OntModelSpec ontModelSpec, DataManager dataManager)
    {
        super(xsltExec, ontModelSpec, dataManager); // this DataManager will be unused as we override getDataManager() with the injected (subclassed) one
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
            headerMap.addFirst(HttpHeaders.ETAG, new EntityTag(eTagHash.toString(16)));
        }
       
        super.writeTo(model, type, type, annotations, mediaType, headerMap, entityStream);
    }
    
    @Override
    public <T extends XdmValue> Map<QName, XdmValue> getParameters(MultivaluedMap<String, Object> headerMap) throws TransformerException
    {
        Map<QName, XdmValue> params = super.getParameters(headerMap);

        try
        {
            // TO-DO: unify by setting UriInfo::requestUri in a response filter?
            if (getURI() != null) params.put(new QName("ac", AC.uri.getNameSpace(), AC.uri.getLocalName()), new XdmAtomicValue(getURI()));
            else params.put(new QName("ac", AC.uri.getNameSpace(), AC.uri.getLocalName()), new XdmAtomicValue(getAbsolutePath()));

            if (getOntology().get().isPresent())
                params.put(new QName("ldt", LDT.ontology.getNameSpace(), LDT.ontology.getLocalName()), new XdmAtomicValue(URI.create(getOntology().get().get().getURI())));

            Optional<Application> app = getApplication().get();
            if (getApplication().get().isPresent())
            {
                params.put(new QName("ldt", LDT.base.getNameSpace(), LDT.base.getLocalName()), new XdmAtomicValue(app.get().getBaseURI()));

                if (log.isDebugEnabled()) log.debug("Passing $lapp:Application to XSLT: {}", app);
                StmtIterator appStmts = app.get().listProperties();
                Model appModel = ModelFactory.createDefaultModel().add(appStmts);
                appStmts.close();

                // for AdminApplication, add EndUserApplication statements
                if (app.get().canAs(AdminApplication.class))
                {
                    AdminApplication adminApp = app.get().as(AdminApplication.class);
                    StmtIterator endUserAppStmts = adminApp.getEndUserApplication().listProperties();
                    appModel.add(endUserAppStmts);
                    endUserAppStmts.close();
                }
                // for EndUserApplication, add AdminApplication statements
                if (app.get().canAs(EndUserApplication.class))
                {
                    EndUserApplication endUserApp = app.get().as(EndUserApplication.class);
                    StmtIterator adminApp = endUserApp.getAdminApplication().listProperties();
                    appModel.add(adminApp);
                    adminApp.close();
                }

                Source source = getSource(appModel); // TO-DO: change hash code?
                if (app.get().hasProperty(FOAF.isPrimaryTopicOf) && app.get().getProperty(FOAF.isPrimaryTopicOf).getObject().isURIResource())
                    source.setSystemId(app.get().getPropertyResourceValue(FOAF.isPrimaryTopicOf).getURI()); // URI accessible via document-uri($lapp:Application)

                params.put(new QName("lapp", LAPP.Application.getNameSpace(), LAPP.Application.getLocalName()),
                    getXsltExecutable().getProcessor().newDocumentBuilder().build(source));
            }
                
            if (getSecurityContext() != null && getSecurityContext().getUserPrincipal() instanceof Agent)
            {
                Agent agent = (Agent)getSecurityContext().getUserPrincipal();
                if (log.isDebugEnabled()) log.debug("Passing $lacl:Agent to XSLT: {}", agent);
                Source source = getSource(agent.getModel());
                if (agent.hasProperty(FOAF.isPrimaryTopicOf) && agent.getProperty(FOAF.isPrimaryTopicOf).getObject().isURIResource())
                    source.setSystemId(agent.getPropertyResourceValue(FOAF.isPrimaryTopicOf).getURI()); // URI accessible via document-uri($lacl:Agent)

                params.put(new QName("acl", ACL.agent.getNameSpace(), ACL.agent.getLocalName()),
                    new XdmAtomicValue(URI.create(agent.getURI())));
                params.put(new QName("acl", ACL.Agent.getNameSpace(), ACL.Agent.getLocalName()),
                    getXsltExecutable().getProcessor().newDocumentBuilder().build(source));
            }

            // TO-DO: move to client-side?
            if (getUriInfo().getQueryParameters().containsKey(APL.access_to.getLocalName()))
                params.put(new QName("apl", APL.access_to.getNameSpace(), APL.access_to.getLocalName()),
                    new XdmAtomicValue(URI.create(getUriInfo().getQueryParameters().getFirst(APL.access_to.getLocalName()))));
            
            if (getHttpHeaders().getRequestHeader(HttpHeaders.REFERER) != null)
            {
                URI referer = URI.create(getHttpHeaders().getRequestHeader(HttpHeaders.REFERER).get(0));
                if (log.isDebugEnabled()) log.debug("Passing $Referer URI to XSLT: {}", referer);
                params.put(new QName("", "", "Referer"), new XdmAtomicValue(referer)); // TO-DO: move to ac: namespace
            }

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
    
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }
    
    @Override
    public OntModelSpec getOntModelSpec()
    {
        return getSystem().getOntModelSpec();
    }
    
    public SecurityContext getSecurityContext()
    {
        return securityContext;
    }
    
    public javax.inject.Provider<Optional<Application>> getApplication()
    {
        return application;
    }
    
    public javax.inject.Provider<Optional<Ontology>> getOntology()
    {
        return ontology;
    }
    
    @Override
    public DataManager getDataManager()
    {
        return getDataManagerProvider().get();
    }

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
    public URI getEndpointURI() throws URISyntaxException
    {
        return getURIParam(getUriInfo(), AC.endpoint.getLocalName());
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
        return getModes(getUriInfo(), namespaces);
    }

    @Override
    public Set<String> getSupportedNamespaces()
    {
        return NAMESPACES;
    }

}