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
package com.atomgraph.linkeddatahub;

import com.atomgraph.linkeddatahub.server.mapper.ResourceExistsExceptionMapper;
import com.atomgraph.linkeddatahub.server.mapper.HttpHostConnectExceptionMapper;
import com.atomgraph.linkeddatahub.server.mapper.MessagingExceptionMapper;
import com.atomgraph.linkeddatahub.server.mapper.auth.WebIDLoadingExceptionMapper;
import com.atomgraph.linkeddatahub.server.mapper.auth.InvalidWebIDURIExceptionMapper;
import com.atomgraph.linkeddatahub.server.mapper.auth.AuthorizationExceptionMapper;
import com.atomgraph.linkeddatahub.server.mapper.auth.AuthenticationExceptionMapper;
import com.atomgraph.linkeddatahub.server.mapper.auth.WebIDCertificateExceptionMapper;
import com.atomgraph.client.MediaTypes;
import com.atomgraph.client.locator.PrefixMapper;
import org.apache.jena.ontology.OntDocumentManager;
import org.apache.jena.util.FileManager;
import org.apache.jena.util.LocationMapper;
import com.atomgraph.linkeddatahub.client.provider.DatasetXSLTWriter;
import javax.annotation.PostConstruct;
import javax.servlet.ServletConfig;
import javax.ws.rs.core.Context;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFFormat;
import org.apache.jena.riot.RDFWriterRegistry;
import com.atomgraph.client.mapper.ClientErrorExceptionMapper;
import com.atomgraph.client.util.DataManager;
import com.atomgraph.client.util.DataManagerImpl;
import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.core.exception.ConfigurationException;
import com.atomgraph.core.io.DatasetProvider;
import com.atomgraph.core.io.ModelProvider;
import com.atomgraph.core.io.QueryProvider;
import com.atomgraph.core.io.ResultSetProvider;
import com.atomgraph.core.io.UpdateRequestReader;
import com.atomgraph.linkeddatahub.client.provider.DataManagerProvider;
import com.atomgraph.linkeddatahub.client.provider.TemplatesProvider;
import com.atomgraph.server.mapper.NotFoundExceptionMapper;
import com.atomgraph.core.provider.QueryParamProvider;
import com.atomgraph.core.riot.RDFLanguages;
import com.atomgraph.core.riot.lang.RDFPostReaderFactory;
import com.atomgraph.core.vocabulary.A;
import com.atomgraph.linkeddatahub.server.mapper.auth.InvalidWebIDPublicKeyExceptionMapper;
import com.atomgraph.linkeddatahub.server.mapper.ModelExceptionMapper;
import com.atomgraph.linkeddatahub.server.mapper.OntClassNotFoundExceptionMapper;
import com.atomgraph.linkeddatahub.server.mapper.jena.QueryExecExceptionMapper;
import com.atomgraph.linkeddatahub.server.mapper.jena.RiotParseExceptionMapper;
import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.model.Agent;
import com.atomgraph.linkeddatahub.model.CSVImport;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.model.File;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.apps.model.impl.AdminApplicationImpl;
import com.atomgraph.linkeddatahub.apps.model.impl.ApplicationImpl;
import com.atomgraph.linkeddatahub.apps.model.impl.EndUserApplicationImpl;
import com.atomgraph.linkeddatahub.server.mapper.auth.WebIDDelegationExceptionMapper;
import com.atomgraph.linkeddatahub.server.factory.ApplicationFactory;
import com.atomgraph.linkeddatahub.model.impl.AgentImpl;
import com.atomgraph.linkeddatahub.model.impl.CSVImportImpl;
import com.atomgraph.linkeddatahub.model.impl.FileImpl;
import com.atomgraph.linkeddatahub.server.event.SignUp;
import com.atomgraph.linkeddatahub.server.filter.request.ApplicationFilter;
import com.atomgraph.linkeddatahub.server.filter.request.ClientUriInfoFilter;
import com.atomgraph.linkeddatahub.server.filter.request.auth.UnauthorizedFilter;
import com.atomgraph.linkeddatahub.server.factory.ClientUriInfoFactory;
import com.atomgraph.linkeddatahub.server.util.SPARQLClientOntologyLoader;
import com.atomgraph.linkeddatahub.server.filter.request.auth.WebIDFilter;
import com.atomgraph.linkeddatahub.server.io.SkolemizingDatasetProvider;
import com.atomgraph.linkeddatahub.server.io.SkolemizingModelProvider;
import com.atomgraph.linkeddatahub.server.model.ClientUriInfo;
import com.atomgraph.server.mapper.ConfigurationExceptionMapper;
import com.atomgraph.linkeddatahub.server.model.impl.ResourceBase;
import com.atomgraph.linkeddatahub.server.factory.OntologyFactory;
import com.atomgraph.linkeddatahub.server.factory.ServiceFactory;
import com.atomgraph.linkeddatahub.server.factory.TemplateCallFactory;
import com.atomgraph.linkeddatahub.server.filter.request.OntologyFilter;
import com.atomgraph.linkeddatahub.server.interceptor.RDFPostCleanupInterceptor;
import com.atomgraph.linkeddatahub.server.filter.request.TemplateCallFilter;
import com.atomgraph.linkeddatahub.server.util.MessageBuilder;
import com.atomgraph.linkeddatahub.vocabulary.APLC;
import com.atomgraph.processor.model.Parameter;
import com.atomgraph.processor.model.Template;
import com.atomgraph.processor.model.TemplateCall;
import com.atomgraph.processor.model.impl.ParameterImpl;
import com.atomgraph.processor.model.impl.TemplateImpl;
import com.atomgraph.processor.vocabulary.AP;
import com.atomgraph.server.mapper.ConstraintViolationExceptionMapper;
import com.atomgraph.server.mapper.OntologyExceptionMapper;
import com.atomgraph.server.mapper.ParameterExceptionMapper;
import com.atomgraph.server.mapper.jena.DatatypeFormatExceptionMapper;
import com.atomgraph.server.mapper.jena.QueryParseExceptionMapper;
import com.atomgraph.server.mapper.jena.RiotExceptionMapper;
import com.google.common.eventbus.EventBus;
import com.google.common.eventbus.Subscribe;
import org.apache.jena.enhanced.BuiltinPersonalities;
import org.apache.jena.ontology.OntModelSpec;
import org.apache.jena.riot.RDFParserRegistry;
import org.slf4j.Logger;
import java.net.URI;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.net.URISyntaxException;
import java.security.KeyManagementException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.UnrecoverableKeyException;
import java.security.cert.Certificate;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;
import javax.mail.Authenticator;
import javax.mail.PasswordAuthentication;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManagerFactory;
import javax.servlet.ServletContext;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.core.CacheControl;
import javax.xml.transform.Source;
import javax.xml.transform.Templates;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.sax.SAXTransformerFactory;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.query.Dataset;
import org.apache.jena.query.DatasetFactory;
import org.apache.jena.query.Query;
import org.apache.jena.query.QueryExecution;
import org.apache.jena.query.QueryExecutionFactory;
import org.apache.jena.query.QueryFactory;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.riot.RDFDataMgr;
import org.apache.jena.update.UpdateFactory;
import org.apache.jena.update.UpdateRequest;
import org.slf4j.LoggerFactory;
import com.atomgraph.processor.vocabulary.LDT;
import com.atomgraph.spinrdf.vocabulary.SP;
import static com.atomgraph.spinrdf.vocabulary.SPIN.THIS_VAR_NAME;
import java.util.Iterator;
import java.util.Optional;
import java.util.TreeMap;
import javax.ws.rs.client.Client;
import javax.ws.rs.client.ClientBuilder;
import org.apache.http.config.Registry;
import org.apache.http.config.RegistryBuilder;
import org.apache.http.conn.socket.ConnectionSocketFactory;
import org.apache.http.conn.socket.PlainConnectionSocketFactory;
import org.apache.http.conn.ssl.NoopHostnameVerifier;
import org.apache.http.conn.ssl.SSLConnectionSocketFactory;
import org.apache.http.impl.conn.PoolingHttpClientConnectionManager;
import org.apache.jena.query.QuerySolutionMap;
import org.apache.jena.rdf.model.RDFNode;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.rdf.model.Statement;
import org.apache.jena.rdf.model.StmtIterator;
import org.glassfish.hk2.api.TypeLiteral;
import org.glassfish.hk2.utilities.binding.AbstractBinder;
import org.glassfish.jersey.client.ClientConfig;
import org.glassfish.jersey.apache.connector.ApacheClientProperties;
import org.glassfish.jersey.apache.connector.ApacheConnectorProvider;
import org.glassfish.jersey.client.ClientProperties;
import org.glassfish.jersey.media.multipart.MultiPartFeature;
import org.glassfish.jersey.process.internal.RequestScoped;
import org.glassfish.jersey.server.ResourceConfig;
import org.glassfish.jersey.server.filter.HttpMethodOverrideFilter;

/**
 * JAX-RS 1.x application subclass.
 * Used to configure the JAX-RS web application in <code>web.xml</code>.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see <a href="https://jersey.github.io/documentation/1.19.1/jax-rs.html#d4e186">Deploying a RESTful Web Service</a>
 */
public class Application extends ResourceConfig
{
    
    private static final Logger log = LoggerFactory.getLogger(Application.class);

    public static final String REQUEST_ACCESS_PATH = "request access";
    public static final String AUTHORIZATION_REQUEST_PATH = "acl/authorization-requests/";
    
    private final EventBus eventBus = new EventBus();
    private final DataManager dataManager;
    private final MediaTypes mediaTypes;
    private final Client client, noCertClient;
    private final Query authQuery, ownerAuthQuery, webIDQuery, sitemapQuery, appQuery, graphDocumentQuery; // no relative URIs
    private final String postUpdateString, deleteUpdateString;
    private final Integer maxGetRequestSize;
    private final boolean preemptiveAuth;
    private final boolean remoteVariableBindings;
    private final Templates templates;
    private final OntModelSpec ontModelSpec;
    private final Source stylesheet;
    private final boolean cacheStylesheet;
    private final boolean resolvingUncached;
    private final URI uploadRoot;
    private final boolean invalidateCache;
    private final Integer cookieMaxAge;
    private final CacheControl authCacheControl;
    private final Authenticator authenticator;
    private final Properties emailProperties = new Properties();
    private final KeyStore keyStore, trustStore;
    private final URI secretaryWebIDURI;
    private final Map<URI, Model> webIDmodelCache = new HashMap<>();
    
    private Dataset contextDataset;
    
    public Application(@Context ServletConfig servletConfig) throws URISyntaxException, MalformedURLException, IOException
    {
        this(
            new MediaTypes(),
            servletConfig.getServletContext().getInitParameter(A.maxGetRequestSize.getURI()) != null ? Integer.parseInt(servletConfig.getServletContext().getInitParameter(A.maxGetRequestSize.getURI())) : null,
            servletConfig.getServletContext().getInitParameter(A.preemptiveAuth.getURI()) != null ? Boolean.parseBoolean(servletConfig.getServletContext().getInitParameter(A.preemptiveAuth.getURI())) : false,
            servletConfig.getServletContext().getInitParameter(AP.cacheSitemap.getURI()) != null ? Boolean.valueOf(servletConfig.getServletContext().getInitParameter(AP.cacheSitemap.getURI())) : true,
            new PrefixMapper(servletConfig.getServletContext().getInitParameter(AC.prefixMapping.getURI()) != null ? servletConfig.getServletContext().getInitParameter(AC.prefixMapping.getURI()) : null),            
            com.atomgraph.client.Application.getSource(servletConfig.getServletContext(), servletConfig.getServletContext().getInitParameter(AC.stylesheet.getURI()) != null ? servletConfig.getServletContext().getInitParameter(AC.stylesheet.getURI()) : null),
            servletConfig.getServletContext().getInitParameter(AC.cacheStylesheet.getURI()) != null ? Boolean.parseBoolean(servletConfig.getServletContext().getInitParameter(AC.cacheStylesheet.getURI())) : false,
            servletConfig.getServletContext().getInitParameter(AC.resolvingUncached.getURI()) != null ? Boolean.parseBoolean(servletConfig.getServletContext().getInitParameter(AC.resolvingUncached.getURI())) : true,
            servletConfig.getServletContext().getInitParameter(APLC.clientKeyStore.getURI()) != null ? servletConfig.getServletContext().getInitParameter(APLC.clientKeyStore.getURI()) : null,
            servletConfig.getServletContext().getInitParameter(APLC.clientKeyStorePassword.getURI()) != null ? servletConfig.getServletContext().getInitParameter(APLC.clientKeyStorePassword.getURI()) : null,
            servletConfig.getServletContext().getInitParameter(APLC.secretaryCertAlias.getURI()) != null ? servletConfig.getServletContext().getInitParameter(APLC.secretaryCertAlias.getURI()) : null,
            servletConfig.getServletContext().getInitParameter(APLC.clientTrustStore.getURI()) != null ? servletConfig.getServletContext().getInitParameter(APLC.clientTrustStore.getURI()) : null,
            servletConfig.getServletContext().getInitParameter(APLC.clientTrustStorePassword.getURI()) != null ? servletConfig.getServletContext().getInitParameter(APLC.clientTrustStorePassword.getURI()) : null,
            servletConfig.getServletContext().getInitParameter(APLC.remoteVariableBindings.getURI()) != null ? Boolean.parseBoolean(servletConfig.getServletContext().getInitParameter(APLC.remoteVariableBindings.getURI())) : false,
            servletConfig.getServletContext().getInitParameter(APLC.authQuery.getURI()) != null ? servletConfig.getServletContext().getInitParameter(APLC.authQuery.getURI()) : null,
            servletConfig.getServletContext().getInitParameter(APLC.ownerAuthQuery.getURI()) != null ? servletConfig.getServletContext().getInitParameter(APLC.ownerAuthQuery.getURI()) : null,
            servletConfig.getServletContext().getInitParameter(APLC.webIDQuery.getURI()) != null ? servletConfig.getServletContext().getInitParameter(APLC.webIDQuery.getURI()) : null,
            servletConfig.getServletContext().getInitParameter(APLC.appQuery.getURI()) != null ? servletConfig.getServletContext().getInitParameter(APLC.appQuery.getURI()) : null,
            servletConfig.getServletContext().getInitParameter(APLC.sitemapQuery.getURI()) != null ? servletConfig.getServletContext().getInitParameter(APLC.sitemapQuery.getURI()) : null,
            servletConfig.getServletContext().getInitParameter(APLC.graphDocumentQuery.getURI()) != null ? servletConfig.getServletContext().getInitParameter(APLC.graphDocumentQuery.getURI()) : null,
            servletConfig.getServletContext().getInitParameter(APLC.postUpdate.getURI()) != null ? servletConfig.getServletContext().getInitParameter(APLC.postUpdate.getURI()) : null,
            servletConfig.getServletContext().getInitParameter(APLC.deleteUpdate.getURI()) != null ? servletConfig.getServletContext().getInitParameter(APLC.deleteUpdate.getURI()) : null,
            servletConfig.getServletContext().getResource("/").toString(),
            servletConfig.getServletContext().getInitParameter(APLC.uploadRoot.getURI()) != null ? servletConfig.getServletContext().getInitParameter(APLC.uploadRoot.getURI()) : null,
            servletConfig.getServletContext().getInitParameter(APLC.invalidateCache.getURI()) != null ? Boolean.parseBoolean(servletConfig.getServletContext().getInitParameter(APLC.invalidateCache.getURI())) : false,
            servletConfig.getServletContext().getInitParameter(APLC.cookieMaxAge.getURI()) != null ? Integer.valueOf(servletConfig.getServletContext().getInitParameter(APLC.cookieMaxAge.getURI())) : null,
            servletConfig.getServletContext().getInitParameter(APLC.authCacheControl.getURI()) != null ? CacheControl.valueOf(servletConfig.getServletContext().getInitParameter(APLC.authCacheControl.getURI())) : null,
            servletConfig.getServletContext().getInitParameter(APLC.maxConnPerRoute.getURI()) != null ? Integer.valueOf(servletConfig.getServletContext().getInitParameter(APLC.maxConnPerRoute.getURI())) : null,
            servletConfig.getServletContext().getInitParameter(APLC.maxTotalConn.getURI()) != null ? Integer.valueOf(servletConfig.getServletContext().getInitParameter(APLC.maxTotalConn.getURI())) : null,
            servletConfig.getServletContext().getInitParameter("mail.user") != null ? servletConfig.getServletContext().getInitParameter("mail.user") : null,
            servletConfig.getServletContext().getInitParameter("mail.password") != null ? servletConfig.getServletContext().getInitParameter("mail.password") : null,
            servletConfig.getServletContext().getInitParameter("mail.smtp.host") != null ? servletConfig.getServletContext().getInitParameter("mail.smtp.host") : null,
            servletConfig.getServletContext().getInitParameter("mail.smtp.port") != null ? servletConfig.getServletContext().getInitParameter("mail.smtp.port") : null
        );

        URI contextDatasetURI = servletConfig.getServletContext().getInitParameter(APLC.contextDataset.getURI()) != null ? new URI(servletConfig.getServletContext().getInitParameter(APLC.contextDataset.getURI())) : null;
        if (contextDatasetURI == null)
        {
            if (log.isErrorEnabled()) log.error("Context dataset URI '{}' not configured", APLC.contextDataset.getURI());
            throw new ConfigurationException(APLC.contextDataset);
        }
        this.contextDataset = getDataset(servletConfig.getServletContext(), contextDatasetURI);
    }
    
    public Application(final MediaTypes mediaTypes,
            final Integer maxGetRequestSize, final boolean preemptiveAuth,
            boolean cacheSitemap,
            final LocationMapper locationMapper, final Source stylesheet, final boolean cacheStylesheet, final boolean resolvingUncached,
            final String clientKeyStoreURIString, final String clientKeyStorePassword,
            final String secretaryCertAlias,
            final String clientTrustStoreURIString, final String clientTrustStorePassword,
            final boolean remoteVariableBindings,
            final String authQueryString, final String ownerAuthQueryString, final String webIDQueryString,
            final String appQueryString, final String sitemapQueryString,
            final String graphDocumentQueryString, final String postUpdateString, final String deleteUpdateString,
            final String systemBase,
            final String uploadRootString, final boolean invalidateCache,
            final Integer cookieMaxAge, final CacheControl authCacheControl,
            final Integer maxConnPerRoute, final Integer maxTotalConn,
            final String mailUser, final String mailPassword, final String smtpHost, final String smtpPort)
    {
        if (clientKeyStoreURIString == null)
        {
            if (log.isErrorEnabled()) log.error("Client key store ({}) not configured", APLC.clientKeyStore.getURI());
            throw new ConfigurationException(APLC.clientKeyStore);
        }

        if (secretaryCertAlias == null)
        {
            if (log.isErrorEnabled()) log.error("Secretary client certificate alias ({}) not configured", APLC.secretaryCertAlias.getURI());
            throw new ConfigurationException(APLC.secretaryCertAlias);
        }
        
        if (clientTrustStoreURIString == null)
        {
            if (log.isErrorEnabled()) log.error("Client truststore store ({}) not configured", APLC.clientTrustStore.getURI());
            throw new ConfigurationException(APLC.clientTrustStore);
        }
        
        if (authQueryString == null)
        {
            if (log.isErrorEnabled()) log.error("Authentication SPARQL query is not configured properly");
            throw new ConfigurationException(APLC.authQuery);
        }
        this.authQuery = QueryFactory.create(authQueryString);
        
        if (ownerAuthQueryString == null)
        {
            if (log.isErrorEnabled()) log.error("Owner authorization SPARQL query is not configured properly");
            throw new ConfigurationException(APLC.ownerAuthQuery);
        }
        this.ownerAuthQuery = QueryFactory.create(ownerAuthQueryString);
        
        if (webIDQueryString == null)
        {
            if (log.isErrorEnabled()) log.error("WebID SPARQL query is not configured properly");
            throw new ConfigurationException(APLC.webIDQuery);
        }
        this.webIDQuery = QueryFactory.create(webIDQueryString);
        
        if (appQueryString == null)
        {
            if (log.isErrorEnabled()) log.error("Query property '{}' not configured", APLC.appQuery.getURI());
            throw new ConfigurationException(APLC.appQuery);
        }        
        appQuery = QueryFactory.create(appQueryString, systemBase);
        appQuery.setBaseURI(systemBase); // for some reason the above is not enough
        
        if (sitemapQueryString == null)
        {
            if (log.isErrorEnabled()) log.error("Query property '{}' not configured", APLC.sitemapQuery.getURI());
            throw new ConfigurationException(APLC.sitemapQuery);
        }        
        sitemapQuery = QueryFactory.create(sitemapQueryString);
        
        if (graphDocumentQueryString == null)
        {
            if (log.isErrorEnabled()) log.error("Query property '{}' not configured", APLC.graphDocumentQuery);
            throw new ConfigurationException(APLC.graphDocumentQuery);
        }
        this.graphDocumentQuery =  QueryFactory.create(graphDocumentQueryString);
                
        if (uploadRootString == null)
        {
            if (log.isErrorEnabled()) log.error("Upload root ({}) not configured", APLC.uploadRoot.getURI());
            throw new ConfigurationException(APLC.uploadRoot);
        }
        
        if (postUpdateString == null)
        {
            if (log.isErrorEnabled()) log.error("Update property '{}' not configured", APLC.postUpdate);
            throw new ConfigurationException(APLC.postUpdate);
        }
        this.postUpdateString = postUpdateString;
        
        if (deleteUpdateString == null)
        {
            if (log.isErrorEnabled()) log.error("Update property '{}' not configured", APLC.deleteUpdate);
            throw new ConfigurationException(APLC.deleteUpdate);
        }
        this.deleteUpdateString = deleteUpdateString;
        
        if (cookieMaxAge == null)
        {
            if (log.isErrorEnabled()) log.error("JWT cookie max age property '{}' not configured", APLC.cookieMaxAge.getURI());
            throw new ConfigurationException(APLC.cookieMaxAge);
        }
        this.cookieMaxAge = cookieMaxAge;

        this.mediaTypes = mediaTypes;
        this.maxGetRequestSize = maxGetRequestSize;
        this.preemptiveAuth = preemptiveAuth;
        this.remoteVariableBindings = remoteVariableBindings;
        this.stylesheet = stylesheet;
        this.cacheStylesheet = cacheStylesheet;
        this.resolvingUncached = resolvingUncached;
        
        try
        {
            this.uploadRoot = new URI(uploadRootString);
        }
        catch (URISyntaxException ex)
        {
            if (log.isErrorEnabled()) log.error("Upload root URI syntax error: {}", ex);
            throw new WebApplicationException(ex);
        }
        
        this.invalidateCache = invalidateCache;
        this.authCacheControl = authCacheControl;

        this.ontModelSpec = OntModelSpec.OWL_MEM_RDFS_INF;

        // add RDF/POST serialization
        RDFLanguages.register(RDFLanguages.RDFPOST);
        RDFParserRegistry.registerLangTriples(RDFLanguages.RDFPOST, new RDFPostReaderFactory());
        // register plain RDF/XML writer as default
        RDFWriterRegistry.register(Lang.RDFXML, RDFFormat.RDFXML_PLAIN); 

        // initialize mapping for locally stored vocabularies
        LocationMapper.setGlobalLocationMapper(locationMapper);
        if (log.isDebugEnabled()) log.debug("LocationMapper.get(): {}", locationMapper);
        
        
        try
        {
            keyStore = KeyStore.getInstance("PKCS12");
            keyStore.load(new FileInputStream(new java.io.File(new URI(clientKeyStoreURIString))), clientKeyStorePassword.toCharArray());

            trustStore = KeyStore.getInstance("JKS");
            trustStore.load(new FileInputStream(new java.io.File(new URI(clientTrustStoreURIString))), clientTrustStorePassword.toCharArray());
            
            client = getClient(keyStore, clientKeyStorePassword, trustStore, maxConnPerRoute, maxTotalConn);
            noCertClient = getNoCertClient(trustStore, maxConnPerRoute, maxTotalConn);
            
            Certificate secretaryCert = keyStore.getCertificate(secretaryCertAlias);
            if (secretaryCert == null)
            {
                if (log.isErrorEnabled()) log.error("Secretary certificate with alias {} does not exist in client keystore {}", secretaryCertAlias, clientKeyStoreURIString);
                throw new WebApplicationException(new CertificateException("Secretary certificate with alias '" + secretaryCertAlias + "' does not exist in client keystore '" + clientKeyStoreURIString + "'"));
            }
            if (!(secretaryCert instanceof X509Certificate))
            {
                if (log.isErrorEnabled()) log.error("Secretary certificate with alias {} is not a X509Certificate", secretaryCertAlias);
                throw new WebApplicationException(new CertificateException("Secretary certificate with alias " + secretaryCertAlias + " is not a X509Certificate"));
            }
            X509Certificate secretaryX509Cert = (X509Certificate)secretaryCert;
            secretaryX509Cert.checkValidity();// check if secretary WebID client certificate is valid
            secretaryWebIDURI = WebIDFilter.getWebIDURI(secretaryX509Cert);
            if (secretaryWebIDURI == null)
            {
                if (log.isErrorEnabled()) log.error("Secretary certificate with alias {} is not a valid WebID sertificate (SNA URI is missing)", secretaryCertAlias);
                throw new WebApplicationException(new CertificateException("Secretary certificate with alias " + secretaryCertAlias + " not a valid WebID sertificate (SNA URI is missing)"));
            }
            
            SP.init(BuiltinPersonalities.model);
            BuiltinPersonalities.model.add(Parameter.class, ParameterImpl.factory);
            BuiltinPersonalities.model.add(Template.class, TemplateImpl.factory);
            BuiltinPersonalities.model.add(Agent.class, AgentImpl.factory);
            //BuiltinPersonalities.model.add(UserAccount.class, UserAccountImpl.factory);
            BuiltinPersonalities.model.add(AdminApplication.class, AdminApplicationImpl.factory);
            BuiltinPersonalities.model.add(EndUserApplication.class, EndUserApplicationImpl.factory);
            BuiltinPersonalities.model.add(com.atomgraph.linkeddatahub.apps.model.Application.class, ApplicationImpl.factory);
            BuiltinPersonalities.model.add(Service.class, new com.atomgraph.linkeddatahub.model.generic.ServiceImplementation(noCertClient, mediaTypes, maxGetRequestSize));
            BuiltinPersonalities.model.add(com.atomgraph.linkeddatahub.model.dydra.Service.class, new com.atomgraph.linkeddatahub.model.dydra.impl.ServiceImplementation(noCertClient, mediaTypes, maxGetRequestSize));
            BuiltinPersonalities.model.add(CSVImport.class, CSVImportImpl.factory);
            BuiltinPersonalities.model.add(File.class, FileImpl.factory);
        
            dataManager = new DataManagerImpl(locationMapper, client, mediaTypes, preemptiveAuth, resolvingUncached);
//            FileManager.setStdLocators((FileManager)dataManager);
//            FileManager.setGlobalFileManager((FileManager)dataManager);
            if (log.isDebugEnabled()) log.debug("FileManager.get(): {}", dataManager);
            
            if (mailUser != null && mailPassword !=  null) // enable SMTP authentication
            {
                emailProperties.put("mail.smtp.auth", "true");
                emailProperties.put("mail.smtp.starttls.enable", "true"); // connect via TLS https://support.google.com/a/answer/2956491?hl=en
                authenticator = new Authenticator() 
                {
                    @Override
                    protected PasswordAuthentication getPasswordAuthentication()
                    {
                        return new PasswordAuthentication(mailUser, mailPassword);
                    }
                };
            }
            else authenticator = null;

            if (smtpHost == null) throw new WebApplicationException(new IllegalStateException("Cannot initialize email service: SMTP host not configured"));
            emailProperties.put("mail.smtp.host", smtpHost);
            if (smtpPort == null) throw new WebApplicationException(new IllegalStateException("Cannot initialize email service: SMTP port not configured"));
            emailProperties.put("mail.smtp.port", Integer.valueOf(smtpPort));
            
            SAXTransformerFactory transformerFactory = ((SAXTransformerFactory)TransformerFactory.newInstance("net.sf.saxon.TransformerFactoryImpl", null));
            transformerFactory.setURIResolver(dataManager);
            this.templates = transformerFactory.newTemplates(stylesheet);
        }
        catch (FileNotFoundException ex)
        {
            if (log.isErrorEnabled()) log.error("Truststore file not found");
            throw new WebApplicationException(ex);
        }
        catch (IOException ex)
        {
            if (log.isErrorEnabled()) log.error("Could not load truststore");
            throw new WebApplicationException(ex);
        }
        catch (KeyStoreException ex)
        {
            if (log.isErrorEnabled()) log.error("Key store error");
            throw new WebApplicationException(ex);
        }
        catch (NoSuchAlgorithmException ex)
        {
            if (log.isErrorEnabled()) log.error("No such algorithm");
            throw new WebApplicationException(ex);
        }
        catch (CertificateException ex)
        {
            if (log.isErrorEnabled()) log.error("Certificate error");
            throw new WebApplicationException(ex);
        }
        catch (KeyManagementException | UnrecoverableKeyException ex)
        {
            if (log.isErrorEnabled()) log.error("Key management error: {}", ex);
            throw new WebApplicationException(ex);
        }
        catch (URISyntaxException ex)
        {
            if (log.isErrorEnabled()) log.error("URI syntax error: {}", ex);
            throw new WebApplicationException(ex);
        }
        catch (TransformerConfigurationException ex)
        {
            if (log.isErrorEnabled()) log.error("System XSLT stylesheet error: {}", ex);
            throw new WebApplicationException(ex);
        }
        
        ontModelSpec.setImportModelGetter(dataManager);
        OntDocumentManager.getInstance().setFileManager((FileManager)dataManager);
        OntDocumentManager.getInstance().setCacheModels(cacheSitemap); // need to re-set after changing FileManager
        if (log.isDebugEnabled()) log.debug("OntDocumentManager.getInstance().getFileManager(): {} Cache ontologies: {}", OntDocumentManager.getInstance().getFileManager(), cacheSitemap);
        ontModelSpec.setDocumentManager(OntDocumentManager.getInstance());
    }
    
    @PostConstruct
    public void init()
    {
        register(MultiPartFeature.class);
        register(ResourceBase.class); // handles /
        
        register(new HttpMethodOverrideFilter());
        register(ClientUriInfoFilter.class);
        register(ApplicationFilter.class);
        register(OntologyFilter.class);
        register(TemplateCallFilter.class);
        register(WebIDFilter.class);
        register(UnauthorizedFilter.class);
        register(new RDFPostCleanupInterceptor());
        
        eventBus.register(this); // this system application will be receiving events about context changes
        
        register(new SkolemizingDatasetProvider());
        register(new SkolemizingModelProvider());
        register(new ResultSetProvider());
        register(new QueryParamProvider());
        register(new UpdateRequestReader());
        register(NotFoundExceptionMapper.class);
        register(ConfigurationExceptionMapper.class);
        register(OntologyExceptionMapper.class);
        register(ModelExceptionMapper.class);
        register(ConstraintViolationExceptionMapper.class);
        register(DatatypeFormatExceptionMapper.class);
        register(ParameterExceptionMapper.class);
        register(QueryExecExceptionMapper.class);
        register(RiotExceptionMapper.class);
        register(RiotParseExceptionMapper.class); // move to Processor?
        register(ClientErrorExceptionMapper.class);
        register(HttpHostConnectExceptionMapper.class);
        register(OntClassNotFoundExceptionMapper.class);
        register(InvalidWebIDPublicKeyExceptionMapper.class);
        register(InvalidWebIDURIExceptionMapper.class);
        register(WebIDCertificateExceptionMapper.class);
        register(WebIDDelegationExceptionMapper.class);
        register(WebIDLoadingExceptionMapper.class);
        register(ResourceExistsExceptionMapper.class);
        register(QueryParseExceptionMapper.class);
        register(AuthenticationExceptionMapper.class);
        register(AuthorizationExceptionMapper.class);
        register(MessagingExceptionMapper.class);

        if (log.isDebugEnabled()) log.debug("Adding XSLT @Providers");
        register(new DatasetXSLTWriter(getTemplates(), getOntModelSpec())); // writes XHTML responses

        final com.atomgraph.linkeddatahub.Application system = this;
        register(new AbstractBinder()
        {
            @Override
            protected void configure()
            {
                bind(system).to(com.atomgraph.linkeddatahub.Application.class);
            }
        });
        register(new AbstractBinder()
        {
            @Override
            protected void configure()
            {
                bind(new com.atomgraph.client.MediaTypes()).to(com.atomgraph.client.MediaTypes.class).to(com.atomgraph.core.MediaTypes.class);
            }
        });
        register(new AbstractBinder()
        {
            @Override
            protected void configure()
            {
                bindFactory(ServiceFactory.class).to(Service.class).
                proxy(true).proxyForSameScope(false).
                in(RequestScoped.class);
            }
        });
        register(new AbstractBinder()
        {
            @Override
            protected void configure()
            {
                bindFactory(ApplicationFactory.class).to(com.atomgraph.linkeddatahub.apps.model.Application.class).
                proxy(true).proxyForSameScope(false).
                in(RequestScoped.class);
            }
        });
        register(new AbstractBinder()
        {
            @Override
            protected void configure()
            {
                bindFactory(OntologyFactory.class).to(Ontology.class).
                proxy(true).proxyForSameScope(false).
                in(RequestScoped.class);
            }
        });
        register(new AbstractBinder()
        {
            @Override
            protected void configure()
            {
                bindFactory(TemplateCallFactory.class).to(new TypeLiteral<Optional<TemplateCall>>() {}).
                in(RequestScoped.class);
            }
        });
        register(new AbstractBinder()
        {
            @Override
            protected void configure()
            {
                bindFactory(new com.atomgraph.core.provider.DataManagerProvider(getDataManager())).to(com.atomgraph.core.util.jena.DataManager.class);
            }
        });
        register(new AbstractBinder()
        {
            @Override
            protected void configure()
            {
                bindFactory(DataManagerProvider.class).to(com.atomgraph.client.util.DataManager.class).
                proxy(true).proxyForSameScope(false).
                in(RequestScoped.class);
            }
        });
        register(new AbstractBinder()
        {
            @Override
            protected void configure()
            {
                bindFactory(ClientUriInfoFactory.class).to(ClientUriInfo.class).
                proxy(true).proxyForSameScope(false).
                in(RequestScoped.class);
            }
        });
        register(new AbstractBinder()
        {
            @Override
            protected void configure()
            {
                bindFactory(new TemplatesProvider(((SAXTransformerFactory)TransformerFactory.newInstance("net.sf.saxon.TransformerFactoryImpl", null)),
                    getDataManager(), getTemplates(), isCacheStylesheet())).to(Templates.class);
            }
        });
        
//        if (log.isTraceEnabled()) log.trace("Application.init() with Classes: {} and Singletons: {}", getClasses(), getSingletons());
    }
    
    public static Dataset getDataset(final ServletContext servletContext, final URI uri) throws FileNotFoundException, MalformedURLException, IOException
    {
        String baseURI = servletContext.getResource("/").toString();

        InputStream datasetStream = null;
        try
        {
            if (uri.isAbsolute()) datasetStream = new FileInputStream(new java.io.File(uri));
            else datasetStream = servletContext.getResourceAsStream(uri.toString());

            if (datasetStream == null) throw new IOException("Dataset not found at URI: " + uri.toString());
            Lang lang = RDFDataMgr.determineLang(uri.toString(), null, null);
            if (lang == null) throw new IOException("Could not determing RDF format from dataset URI: " + uri.toString());

            Dataset dataset = DatasetFactory.create();
            if (log.isDebugEnabled()) log.debug("Loading Model from dataset: {}", uri);
            RDFDataMgr.read(dataset, datasetStream, baseURI, lang);
            return dataset;
        }
        finally
        {
            if (datasetStream != null) datasetStream.close();
        }
    }

    public final Model getModel(Dataset dataset, Query query)
    {
        if (dataset == null) throw new IllegalArgumentException("Dataset cannot be null");
        if (query == null) throw new IllegalArgumentException("Query cannot be null");
        
        try (QueryExecution qex = QueryExecutionFactory.create(query, dataset))
        {
            if (query.isDescribeType()) return qex.execDescribe();
            if (query.isConstructType()) return qex.execConstruct();
            
            throw new IllegalStateException("Query is not DESCRIBE or CONSTRUCT");
        }
    }

    @Subscribe
    public void handleSignUp(SignUp event)
    {
        getWebIDModelCache().remove(event.getSecretaryWebID()); // clear secretary WebID from cache to get new acl:delegates statements after new signup
    }
    
    public Ontology getOntology(com.atomgraph.linkeddatahub.apps.model.Application app)
    {
        return new SPARQLClientOntologyLoader(getOntModelSpec(), getSitemapQuery()).getOntology(app);
    }

    public Resource matchApp(URI absolutePath)
    {
        return matchApp(getAppModel(ResourceFactory.createResource(absolutePath.toString())), absolutePath);
    }
    
    public Resource matchApp(Model appModel, URI absolutePath)
    {
        return getLongestURIApp(getLengthMap(getRelativeBaseApps(appModel, absolutePath)));
    }
    
    public Resource getLongestURIApp(Map<Integer, Resource> lengthMap)
    {
        // select the app with the longest URI match, as the model contains a pair of EndUserApplication/AdminApplication
        TreeMap<Integer, Resource> appMap = new TreeMap(lengthMap);
        if (!appMap.isEmpty()) return appMap.lastEntry().getValue();
        
        return null;
    }
    
    public Map<URI, Resource> getRelativeBaseApps(Model model, URI absolutePath)
    {
        if (model == null) throw new IllegalArgumentException("Model cannot be null");
        if (absolutePath == null) throw new IllegalArgumentException("URI cannot be null");

        Map<URI, Resource> appMap = new HashMap<>();
        
        // an app can have multiple base URIs
        StmtIterator it = model.listStatements(null, LDT.base, (RDFNode)null);
        try
        {
            while (it.hasNext())
            {
                Statement stmt = it.next();
                Resource app = stmt.getSubject();
                URI base = URI.create(stmt.getResource().getURI());
                URI relative = base.relativize(absolutePath);
                if (!relative.isAbsolute()) appMap.put(base, app);
            }
        }
        finally
        {
            it.close();
        }

        return appMap;
    }
    
    public Map<Integer, Resource> getLengthMap(Map<URI, Resource> apps)
    {
        if (apps == null) throw new IllegalArgumentException("Map cannot be null");

        Map<Integer, Resource> lengthMap = new HashMap<>();
        
        Iterator<Map.Entry<URI, Resource>> it = apps.entrySet().iterator();
        while (it.hasNext())
        {
            Map.Entry<URI, Resource> entry = it.next();
            lengthMap.put(entry.getKey().toString().length(), entry.getValue());
        }
        
        return lengthMap;
    }
    
    public Model getAppModel(Resource absolutePath)
    {
        if (absolutePath == null) throw new IllegalArgumentException("Absolute path Resource cannot be null");

        QuerySolutionMap qsm = new QuerySolutionMap();
        qsm.add(THIS_VAR_NAME, absolutePath);
        
        QueryExecution qex = QueryExecutionFactory.create(getAppQuery(), getContextDataset(), qsm);
        if (getAppQuery().isConstructType()) return qex.execConstruct();
        if (getAppQuery().isDescribeType()) return qex.execDescribe();
        
        throw new WebApplicationException(new IllegalStateException("Query is not a DESCRIBE or CONSTRUCT"));
    }
    
    public static Client getClient(KeyStore keyStore, String keyStorePassword, KeyStore trustStore, Integer maxConnPerRoute, Integer maxTotalConn) throws NoSuchAlgorithmException, KeyStoreException, UnrecoverableKeyException, KeyManagementException
    {
        if (keyStore == null) throw new IllegalArgumentException("KeyStore cannot be null");
        if (keyStorePassword == null) throw new IllegalArgumentException("KeyStore password string cannot be null");
        if (trustStore == null) throw new IllegalArgumentException("KeyStore (truststore) cannot be null");

        // for client authentication
        KeyManagerFactory kmf = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
        kmf.init(keyStore, keyStorePassword.toCharArray());

        // for trusting server certificate
        TrustManagerFactory tmf = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
        tmf.init(trustStore);

        SSLContext ctx = SSLContext.getInstance("SSL");
        ctx.init(kmf.getKeyManagers(), tmf.getTrustManagers(), null);

        Registry<ConnectionSocketFactory> socketFactoryRegistry = RegistryBuilder.<ConnectionSocketFactory>create().
            register("https", new SSLConnectionSocketFactory(ctx)).
            register("http", new PlainConnectionSocketFactory()).
            build();

        PoolingHttpClientConnectionManager conman = new PoolingHttpClientConnectionManager(socketFactoryRegistry);
        if (maxConnPerRoute != null) conman.setDefaultMaxPerRoute(maxConnPerRoute);
        if (maxTotalConn != null) conman.setMaxTotal(maxTotalConn);
//        if (log.isDebugEnabled()) client.addFilter(new LoggingFilter(System.out));

        ClientConfig config = new ClientConfig();
        config.connectorProvider(new ApacheConnectorProvider());
        config.register(MultiPartFeature.class);
        config.register(new ModelProvider());
        config.register(new DatasetProvider());
        config.register(new ResultSetProvider());
        config.register(new QueryProvider());
        config.register(new UpdateRequestReader());
        config.property(ClientProperties.FOLLOW_REDIRECTS, true);
        config.property(ApacheClientProperties.CONNECTION_MANAGER, conman);
        
        return ClientBuilder.newBuilder().
            withConfig(config).
            sslContext(ctx).
            hostnameVerifier(NoopHostnameVerifier.INSTANCE).
            build();
    }
    
    public static Client getNoCertClient(KeyStore trustStore, Integer maxConnPerRoute, Integer maxTotalConn)
    {
        try
        {
            // for trusting server certificate
            TrustManagerFactory tmf = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
            tmf.init(trustStore);
            
            SSLContext ctx = SSLContext.getInstance("SSL");
            ctx.init(null, tmf.getTrustManagers(), null);

            Registry<ConnectionSocketFactory> socketFactoryRegistry = RegistryBuilder.<ConnectionSocketFactory>create().
                register("https", new SSLConnectionSocketFactory(ctx)).
                register("http", new PlainConnectionSocketFactory()).
                build();
        
            PoolingHttpClientConnectionManager conman = new PoolingHttpClientConnectionManager(socketFactoryRegistry);
            if (maxConnPerRoute != null) conman.setDefaultMaxPerRoute(maxConnPerRoute);
            if (maxTotalConn != null) conman.setMaxTotal(maxTotalConn);

            ClientConfig config = new ClientConfig();
            config.connectorProvider(new ApacheConnectorProvider());
            config.register(MultiPartFeature.class);
            config.register(new ModelProvider());
            config.register(new DatasetProvider());
            config.register(new ResultSetProvider());
            config.register(new QueryProvider());
            config.register(new UpdateRequestReader()); // TO-DO: UpdateRequestProvider
            config.property(ClientProperties.FOLLOW_REDIRECTS, true);
            config.property(ApacheClientProperties.CONNECTION_MANAGER, conman);

            return ClientBuilder.newBuilder().
                withConfig(config).
                sslContext(ctx).
                hostnameVerifier(NoopHostnameVerifier.INSTANCE).
                build();
        }
        catch (NoSuchAlgorithmException ex)
        {
            if ( log.isErrorEnabled()) log.error("No such algorithm: {}", ex);
            throw new WebApplicationException(ex);
        }
        catch (KeyStoreException ex)
        {
            if ( log.isErrorEnabled()) log.error("Key store error: {}", ex);
            throw new WebApplicationException(ex);
        }
        catch (KeyManagementException ex)
        {
            if ( log.isErrorEnabled()) log.error("Key management error: {}", ex);
            throw new WebApplicationException(ex);
        }
        
        //if (log.isDebugEnabled()) client.addFilter(new LoggingFilter(System.out));
    }
    
    public EventBus getEventBus()
    {
        return eventBus;
    }
    
    public DataManager getDataManager()
    {
        return dataManager;
    }
    
    public MediaTypes getMediaTypes()
    {
        return mediaTypes;
    }
    
    public Client getClient()
    {
        return client;
    }
    
    public URI getSecretaryWebIDURI()
    {
        return secretaryWebIDURI;
    }
    
    public Query getAuthQuery()
    {
        return authQuery;
    }
    
    public Query getOwnerAuthQuery()
    {
        return ownerAuthQuery;
    }
    
    public Query getWebIDQuery()
    {
        return webIDQuery;
    }
    
    public Query getSitemapQuery()
    {
        return sitemapQuery;
    }
    
    public Query getAppQuery()
    {
        return appQuery;
    }

    public Query getGraphDocumentQuery()
    {
        return graphDocumentQuery;
    }
    
    public UpdateRequest getPostUpdate(String baseURI)
    {
        return UpdateFactory.create(postUpdateString, baseURI);
    }

    public UpdateRequest getDeleteUpdate(String baseURI)
    {
        return UpdateFactory.create(deleteUpdateString, baseURI);
    }
    
    public Integer getMaxGetRequestSize()
    {
        return maxGetRequestSize;
    }
    
    public boolean isPreemptiveAuth()
    {
        return preemptiveAuth;
    }

    public boolean isRemoteVariableBindings()
    {
        return remoteVariableBindings;
    }
    
    public OntModelSpec getOntModelSpec()
    {
        return ontModelSpec;
    }
    
    public Templates getTemplates()
    {
        return templates;
    }
    
    public Source getStylesheet()
    {
        return stylesheet;
    }

    public boolean isCacheStylesheet()
    {
        return cacheStylesheet;
    }

    public boolean isResolvingUncached()
    {
        return resolvingUncached;
    }
    
    public URI getUploadRoot()
    {
        return uploadRoot;
    }
    
    public Dataset getContextDataset()
    {
        return contextDataset;
    }

    public boolean isInvalidateCache()
    {
        return invalidateCache;
    }

    public Integer getCookieMaxAge()
    {
        return cookieMaxAge;
    }

    public CacheControl getAuthCacheControl()
    {
        return authCacheControl;
    }
    
    public KeyStore getKeyStore()
    {
        return keyStore;
    }
    
    public KeyStore getTrustStore()
    {
        return trustStore;
    }
    
    public Client getNoCertClient()
    {
        return noCertClient;
    }
    
    public final MessageBuilder getMessageBuilder()
    {
        if (authenticator != null) return MessageBuilder.fromPropertiesAndAuth(emailProperties, authenticator);
        else return MessageBuilder.fromProperties(emailProperties);
    }
    
    public Map<URI, Model> getWebIDModelCache()
    {
        return webIDmodelCache;
    }
    
}