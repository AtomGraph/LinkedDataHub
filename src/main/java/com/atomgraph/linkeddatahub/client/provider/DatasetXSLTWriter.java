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
package com.atomgraph.linkeddatahub.client.provider;

import java.net.URI;
import java.net.URISyntaxException;
import javax.ws.rs.Produces;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.MultivaluedMap;
import javax.ws.rs.core.SecurityContext;
import javax.ws.rs.ext.Provider;
import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.core.util.Link;
import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.model.Agent;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.client.util.DataManager;
import com.atomgraph.linkeddatahub.server.model.ClientUriInfo;
import com.atomgraph.linkeddatahub.vocabulary.APL;
import com.atomgraph.linkeddatahub.vocabulary.APLT;
import com.atomgraph.linkeddatahub.vocabulary.FOAF;
import com.atomgraph.linkeddatahub.vocabulary.LACL;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import com.atomgraph.processor.vocabulary.LDT;
import java.io.IOException;
import java.io.OutputStream;
import java.lang.annotation.Annotation;
import java.lang.reflect.Type;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import javax.inject.Inject;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.core.UriInfo;
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
import org.apache.jena.query.Dataset;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.StmtIterator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS writer which uses an XSLT stylesheet to transform the RDF dataset.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Provider
@Produces({MediaType.TEXT_HTML + ";charset=UTF-8"}) // MediaType.APPLICATION_XHTML_XML + ";charset=UTF-8", 
public class DatasetXSLTWriter extends com.atomgraph.client.writer.DatasetXSLTWriter
{
    private static final Logger log = LoggerFactory.getLogger(DatasetXSLTWriter.class);

    @Context SecurityContext securityContext;
    
    @Inject com.atomgraph.linkeddatahub.Application system;
    @Inject Application application;
    @Inject Ontology ontology;
    @Inject ClientUriInfo clientUriInfo;
    @Inject DataManager dataManager;

    private static final Set<String> NAMESPACES;
    
    static
    {
        NAMESPACES = new HashSet<>();
        NAMESPACES.add(AC.NS);
        NAMESPACES.add(APLT.NS);
    }
    
    @Inject
    public DatasetXSLTWriter(XsltExecutable xsltExec, OntModelSpec ontModelSpec)
    {
        super(xsltExec, ontModelSpec);
    }
    
    @Override
    public void writeTo(Dataset dataset, Class<?> type, Type genericType, Annotation[] annotations, MediaType mediaType, MultivaluedMap<String, Object> headerMap, OutputStream entityStream) throws IOException
    {
        if (headerMap == null) throw new IllegalArgumentException("MultivaluedMap cannot be null");
        
        // set request attributes based on response headers if they are not already set by Web-Client's ProxyResourceBase
        try
        {
            Link ontologyLink = getLink(headerMap, "Link", LDT.ontology.getURI());
            if (ontologyLink != null && getHttpServletRequest().getAttribute(LDT.ontology.getURI()) == null)
                getHttpServletRequest().setAttribute(LDT.ontology.getURI(), ontologyLink.getHref());
            Link baseLink = getLink(headerMap, "Link", LDT.base.getURI());
            if (baseLink != null && getHttpServletRequest().getAttribute(LDT.base.getURI()) == null)
                getHttpServletRequest().setAttribute(LDT.base.getURI(), baseLink.getHref());
            Link templateLink = getLink(headerMap, "Link", LDT.template.getURI());
            if (templateLink != null && getHttpServletRequest().getAttribute(LDT.template.getURI()) == null)
                getHttpServletRequest().setAttribute(LDT.template.getURI(), templateLink.getHref());
        }
        catch (URISyntaxException ex)
        {
            if (log.isErrorEnabled()) log.error("Could not parse Link URI: {}", ex.getInput());
            throw new WebApplicationException(ex); // TO-DO: specific Exception and Mapper?
        }

        super.writeTo(dataset, type, genericType, annotations, mediaType, headerMap, entityStream);
    }
    
    @Override
    public <T extends XdmValue> Map<QName, XdmValue> getParameters(Dataset dataset, MultivaluedMap<String, Object> headerMap) throws TransformerException
    {
        Map<QName, XdmValue> params = super.getParameters(dataset, headerMap);

        try
        {
            if (getURI() != null) params.put(new QName("ac", AC.uri.getNameSpace(), AC.uri.getLocalName()), new XdmAtomicValue(getURI()));
            else params.put(new QName("ac", AC.uri.getNameSpace(), AC.uri.getLocalName()), new XdmAtomicValue(getAbsolutePath()));

            Application app = getApplication();
            if (app != null)
            {
                params.put(new QName("ldt", LDT.base.getNameSpace(), LDT.base.getLocalName()), new XdmAtomicValue(getBaseUri()));

                if (log.isDebugEnabled()) log.debug("Passing $lapp:Application to XSLT: {}", app);
                StmtIterator appStmts = app.listProperties();
                Model appModel = ModelFactory.createDefaultModel().add(appStmts);
                appStmts.close();

                // for AdminApplication, add EndUserApplication statements
                if (app.canAs(AdminApplication.class))
                {
                    AdminApplication adminApp = app.as(AdminApplication.class);
                    StmtIterator endUserAppStmts = adminApp.getEndUserApplication().listProperties();
                    appModel.add(endUserAppStmts);
                    endUserAppStmts.close();
                }
                // for EndUserApplication, add AdminApplication statements
                if (app.canAs(EndUserApplication.class))
                {
                    EndUserApplication endUserApp = app.as(EndUserApplication.class);
                    StmtIterator adminApp = endUserApp.getAdminApplication().listProperties();
                    appModel.add(adminApp);
                    adminApp.close();
                }

                Source source = getSource(appModel); // TO-DO: change hash code?
                if (app.hasProperty(FOAF.isPrimaryTopicOf) && app.getProperty(FOAF.isPrimaryTopicOf).getObject().isURIResource())
                    source.setSystemId(app.getPropertyResourceValue(FOAF.isPrimaryTopicOf).getURI()); // URI accessible via document-uri($lapp:Application)

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

                params.put(new QName("lacl", LACL.Agent.getNameSpace(), LACL.Agent.getLocalName()),
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
    
    public Ontology getOntology()
    {
        return ontology;
    }

    public Application getApplication()
    {
        return application;
    }
    
    @Override
    public DataManager getDataManager()
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
    public UriInfo getUriInfo()
    {
        return clientUriInfo;
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
    
    public Link getLink(MultivaluedMap<String, Object> headerMap, String headerName, String rel) throws URISyntaxException
    {
        if (headerMap == null) throw new IllegalArgumentException("Header Map cannot be null");
        if (headerName == null) throw new IllegalArgumentException("String header name cannot be null");
        if (rel == null) throw new IllegalArgumentException("Property Map cannot be null");
        
        List<Object> links = headerMap.get(headerName);
        if (links != null)
        {
            Iterator<Object> it = links.iterator();
            while (it.hasNext())
            {
                String linkHeader = it.next().toString();
                Link link = Link.valueOf(linkHeader);
                if (link.getRel().equals(rel)) return link;
            }
        }
        
        return null;
    }

}
