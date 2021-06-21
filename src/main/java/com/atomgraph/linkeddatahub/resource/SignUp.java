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
package com.atomgraph.linkeddatahub.resource;

import javax.ws.rs.core.Context;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.Request;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.core.exception.ConfigurationException;
import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.listener.EMailListener;
import com.atomgraph.linkeddatahub.server.model.impl.GraphStoreImpl;
import com.atomgraph.linkeddatahub.server.util.WebIDCertGen;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.linkeddatahub.vocabulary.APLC;
import com.atomgraph.linkeddatahub.vocabulary.APLT;
import com.atomgraph.linkeddatahub.vocabulary.Cert;
import com.atomgraph.linkeddatahub.vocabulary.FOAF;
import com.atomgraph.linkeddatahub.vocabulary.LACL;
import com.atomgraph.processor.util.Skolemizer;
import com.atomgraph.processor.vocabulary.DH;
import com.atomgraph.server.exception.SPINConstraintViolationException;
import com.atomgraph.server.exception.SkolemizationException;
import com.atomgraph.spinrdf.constraints.ConstraintViolation;
import com.atomgraph.spinrdf.constraints.ObjectPropertyPath;
import com.atomgraph.spinrdf.constraints.SimplePropertyPath;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.security.KeyStore;
import java.security.cert.Certificate;
import java.security.interfaces.RSAPublicKey;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import javax.inject.Inject;
import javax.mail.Address;
import javax.mail.MessagingException;
import javax.mail.internet.AddressException;
import javax.mail.internet.InternetAddress;
import javax.servlet.ServletConfig;
import javax.ws.rs.BadRequestException;
import javax.ws.rs.DefaultValue;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.QueryParam;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.UriBuilder;
import javax.ws.rs.core.UriInfo;
import javax.ws.rs.ext.Providers;
import static org.apache.jena.datatypes.xsd.XSDDatatype.XSDhexBinary;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Property;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.rdf.model.Statement;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFDataMgr;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;
import org.glassfish.jersey.server.internal.process.MappableException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS resource that handles signups.
 * Creates a new agent with a public key and sends a notification email with an attached WebID certificate.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class SignUp extends GraphStoreImpl
{
    
    private static final Logger log = LoggerFactory.getLogger(SignUp.class);
    
    public static final String STORE_TYPE = "PKCS12";
    public static final String KEY_ALIAS = "linkeddatahub-client";
    public static final int MIN_PASSWORD_LENGTH = 6;
    public static final MediaType PKCS12_MEDIA_TYPE = MediaType.valueOf("application/x-pkcs12");
    public static final String COUNTRY_DATASET_PATH = "/static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/countries.rdf";
    public static final String AGENT_PATH = "acl/agents/";
    public static final String AUTHORIZATION_PATH = "acl/authorizations/";

    private final URI uri;
    private final Application application;
    private final Ontology ontology;
    private final Model countryModel;
    private final UriBuilder agentContainerUriBuilder, authorizationContainerUriBuilder;
    private final Address signUpAddress;
    private final String emailSubject;
    private final String emailText;
    private final int validityDays;
    private final boolean download;

    // TO-DO: move to AuthenticationExceptionMapper and handle as state instead of URI resource?
    @Inject
    public SignUp(@Context UriInfo uriInfo, @Context Request request, MediaTypes mediaTypes,
            Optional<Service> service, Optional<com.atomgraph.linkeddatahub.apps.model.Application> application, Optional<Ontology> ontology,
            @Context Providers providers, com.atomgraph.linkeddatahub.Application system, @Context ServletConfig servletConfig)
    {
        super(request, service, mediaTypes, uriInfo, providers, system);
        if (log.isDebugEnabled()) log.debug("Constructing {}", getClass());
        
        if (application.isEmpty() || !application.get().canAs(AdminApplication.class)) // we are supposed to be in the admin app
            throw new IllegalStateException("Application cannot be cast to apl:AdminApplication");
        
        this.uri = uriInfo.getAbsolutePath();
        this.application = application.get();
        this.ontology = ontology.get();
        
        try (InputStream countries = servletConfig.getServletContext().getResourceAsStream(COUNTRY_DATASET_PATH))
        {
            countryModel = ModelFactory.createDefaultModel();
            RDFDataMgr.read(countryModel, countries, null, Lang.RDFXML);
        }
        catch (IOException ex)
        {
            throw new WebApplicationException(ex);
        }
        
        // TO-DO: extract Agent container URI from ontology Restrictions
        agentContainerUriBuilder = uriInfo.getBaseUriBuilder().path(AGENT_PATH);
        authorizationContainerUriBuilder = uriInfo.getBaseUriBuilder().path(AUTHORIZATION_PATH);
       
        try
        {
            String signUpAddressParam = servletConfig.getServletContext().getInitParameter(APLC.signUpAddress.getURI());
            if (signUpAddressParam == null) throw new WebApplicationException(new ConfigurationException(APLC.signUpAddress));
            InternetAddress[] signUpAddresses = InternetAddress.parse(signUpAddressParam);
            // if (signUpAddresses.size() == 0) throw Exception...
            signUpAddress = signUpAddresses[0];
        }
        catch (AddressException ex)
        {
            throw new WebApplicationException(ex);
        }
        
        emailSubject = servletConfig.getServletContext().getInitParameter(APLC.signUpEMailSubject.getURI());
        if (emailSubject == null) throw new WebApplicationException(new ConfigurationException(APLC.signUpEMailSubject));

        emailText = servletConfig.getServletContext().getInitParameter(APLC.webIDSignUpEMailText.getURI());
        if (emailText == null) throw new WebApplicationException(new ConfigurationException(APLC.webIDSignUpEMailText));
        
        if (servletConfig.getServletContext().getInitParameter(APLC.signUpCertValidity.getURI()) == null)
            throw new WebApplicationException(new ConfigurationException(APLC.signUpCertValidity));
        validityDays = Integer.parseInt(servletConfig.getServletContext().getInitParameter(APLC.signUpCertValidity.getURI()));
        
        download = uriInfo.getQueryParameters().containsKey("download"); // debug param that allows downloading the certificate
    }
    
    @GET
    @Override
    public Response get(@QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        return super.get(false, getURI());
    }
    
    @POST
    @Override
    public Response post(Model model, @QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        if (!getUriInfo().getQueryParameters().containsKey(APLT.forClass.getLocalName())) throw new BadRequestException("aplt:forClass argument is mandatory for aplt:SignUp template");

        Resource forClass = model.createResource(getUriInfo().getQueryParameters().getFirst(APLT.forClass.getLocalName()));
        ResIterator it = model.listResourcesWithProperty(RDF.type, forClass);
        try
        {
            Resource agent = it.next();
            String password = validateAndRemovePassword(agent);
            // TO-DO: trim values
            String givenName = agent.getRequiredProperty(FOAF.givenName).getString();
            String familyName = agent.getRequiredProperty(FOAF.familyName).getString();
            String fullName = givenName + " " + familyName;
            String orgName = null;
            if (agent.hasProperty(FOAF.member))
            {
                Resource org = agent.getPropertyResourceValue(FOAF.member);
                if (org.hasProperty(FOAF.name)) orgName = org.getProperty(FOAF.name).getString();
            }
            Resource country = agent.getRequiredProperty(FOAF.based_near).getResource();
            String countryName = getCountryModel().createResource(country.getURI()).
                    getRequiredProperty(DCTerms.title).getString();

            String uuid = UUID.randomUUID().toString();
            String keyStoreFileName = uuid + ".p12";
            java.nio.file.Path keyStorePath = Paths.get(System.getProperty("java.io.tmpdir") + File.separator + keyStoreFileName);

            new WebIDCertGen("RSA", STORE_TYPE).generate(keyStorePath, password, password, KEY_ALIAS,
                fullName, null, orgName, null, null, countryName, agent.getURI(), getValidityDays());

            // load certificate to retrieve public key metadata
            KeyStore keyStore = KeyStore.getInstance(STORE_TYPE);
            byte[] keyStoreBytes = Files.readAllBytes(keyStorePath);
            try (InputStream bis = new ByteArrayInputStream(keyStoreBytes))
            {
                keyStore.load(bis, password.toCharArray());
                Certificate cert = keyStore.getCertificate(KEY_ALIAS);
                if (!(cert.getPublicKey() instanceof RSAPublicKey)) throw new IllegalStateException("Certificate PublicKey is not an RSAPublicKey");

                RSAPublicKey certPublicKey = (RSAPublicKey)cert.getPublicKey();
                Model publicKeyModel = ModelFactory.createDefaultModel();
                createPublicKey(publicKeyModel, forClass.getNameSpace(), certPublicKey);
                publicKeyModel = new Skolemizer(getOntology(), getUriInfo().getBaseUriBuilder(), getAgentContainerUriBuilder()).build(publicKeyModel);

                Resource publicKeyForClass = ResourceFactory.createResource(forClass.getNameSpace() + LACL.PublicKey.getLocalName());
                Response publicKeyResponse = super.post(publicKeyModel, URI.create(publicKeyForClass.getURI()));
                if (publicKeyResponse.getStatus() != Response.Status.CREATED.getStatusCode())
                {
                    if (log.isErrorEnabled()) log.error("Cannot create PublicKey");
                    throw new WebApplicationException("Cannot create PublicKey");
                }

                URI publicKeyGraphUri = publicKeyResponse.getLocation();
                publicKeyModel = (Model)super.get(false, publicKeyGraphUri).getEntity();
                Resource publicKey = publicKeyModel.createResource(publicKeyGraphUri.toString()).getPropertyResourceValue(FOAF.primaryTopic);

                agent.addProperty(Cert.key, publicKey); // add public key
                model.add(model.createResource(getSystem().getSecretaryWebIDURI().toString()), ACL.delegates, agent); // make secretary delegate whis agent

                URI agentGraphUri = URI.create(agent.getURI());
                agentGraphUri = new URI(agentGraphUri.getScheme(), agentGraphUri.getSchemeSpecificPart(), null).normalize(); // strip the possible fragment identifier
                
                Response agentResponse = super.post(model, false, agentGraphUri);
                if (agentResponse.getStatus() != Response.Status.CREATED.getStatusCode())
                {
                    if (log.isErrorEnabled()) log.error("Cannot create Agent");
                    throw new WebApplicationException("Cannot create Agent");
                }

                // remove secretary WebID from cache
                getSystem().getEventBus().post(new com.atomgraph.linkeddatahub.server.event.SignUp(getSystem().getSecretaryWebIDURI()));

                if (download)
                {
                    return Response.ok(keyStoreBytes).
                        type(PKCS12_MEDIA_TYPE).
                        header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=cert.p12").
                        build();
                }
                else
                {
                    LocalDate certExpires = LocalDate.now().plusDays(getValidityDays()); // ((X509Certificate)cert).getNotAfter(); 
                    sendEmail(agent, certExpires, keyStoreBytes, keyStoreFileName);

                    return agentResponse;
                }
            }
        }
        catch (SPINConstraintViolationException ex)
        {
            throw ex; // propagate
        }
        catch (IllegalArgumentException ex)
        {
            throw new SkolemizationException(ex, model);
        }
        catch (Exception ex)
        {
            throw new MappableException(ex);
        }
        finally
        {
            it.close();
        }
    }

    public String validateAndRemovePassword(Resource agent) throws SPINConstraintViolationException
    {
        Statement certStmt = agent.getProperty(Cert.key);
        if (certStmt == null)
            throw createSPINConstraintViolationException(agent, Cert.key, "cert:key is missing");
        
        if (certStmt.getResource().listProperties(LACL.password).toList().size() > 1)
            throw createSPINConstraintViolationException(certStmt.getResource(), LACL.password, "Certificate passwords do not match");
        Statement passwordStmt = certStmt.getResource().getProperty(LACL.password);
        if (passwordStmt == null)
            throw createSPINConstraintViolationException(certStmt.getResource(), LACL.password, "Certificate password is missing");
        String password = passwordStmt.getString();
        if (password.length() < MIN_PASSWORD_LENGTH)
            throw createSPINConstraintViolationException(certStmt.getResource(), LACL.password, "Certificate password must be at least " + MIN_PASSWORD_LENGTH + " characters long");
        // remove password so we don't store it as RDF
        passwordStmt.remove();
        certStmt.remove();
        return password;
    }
    
    public SPINConstraintViolationException createSPINConstraintViolationException(Resource resource, Property property, String message)
    {
        List<ConstraintViolation> cvs = new ArrayList<>();
        List<SimplePropertyPath> paths = new ArrayList<>();
        paths.add(new ObjectPropertyPath(resource, property));
        cvs.add(new ConstraintViolation(resource, paths, null, message, null));
        return new SPINConstraintViolationException(cvs, resource.getModel());
    }

    public Resource createPublicKey(Model model, String namespace, RSAPublicKey publicKey)
    {
        // TO-DO: improve class URI retrieval
        Resource cls = model.createResource(namespace + LACL.PublicKey.getLocalName()); // subclassOf LACL.PublicKey
        Resource itemCls = model.createResource(namespace + LACL.PublicKey.getLocalName() + "Item");

        Resource publicKeyItem = model.createResource().
            addProperty(RDF.type, itemCls).
            addLiteral(DH.slug, UUID.randomUUID().toString());
        Resource publicKeyRes = model.createResource().
            addProperty(RDF.type, cls).
            addLiteral(Cert.exponent, publicKey.getPublicExponent()).
            addLiteral(Cert.modulus, ResourceFactory.createTypedLiteral(publicKey.getModulus().toString(16), XSDhexBinary));
        publicKeyItem.addProperty(FOAF.primaryTopic, publicKeyRes);
        publicKeyRes.addProperty(FOAF.isPrimaryTopicOf, publicKeyItem);
        
        return publicKeyRes;
    }
    
    public void sendEmail(Resource agent, LocalDate certExpires, byte[] keyStoreBytes, String keyStoreFileName) throws MessagingException, UnsupportedEncodingException
    {
        // send email with attached KeyStore
        String givenName = agent.getRequiredProperty(FOAF.givenName).getString();
        String familyName = agent.getRequiredProperty(FOAF.familyName).getString();
        String fullName = givenName + " " + familyName;
        // we expect foaf:mbox value as mailto: URI (it gets converted from literal in Model provider)
        String mbox = agent.getRequiredProperty(FOAF.mbox).getResource().getURI().substring("mailto:".length());

        // labels and links need to come from the end-user app
        EMailListener.submit(getSystem().getMessageBuilder().
            subject(String.format(getEmailSubject(),
                getEndUserApplication().getProperty(DCTerms.title).getString(),
                fullName)).
            from(getSignUpAddress()).
            to(mbox, fullName).
            textBodyPart(String.format(getEmailText(),
                getEndUserApplication().getProperty(DCTerms.title).getString(),
                getEndUserApplication().getBase(),
                agent.getURI(),
                certExpires.format(DateTimeFormatter.ISO_LOCAL_DATE))).
            byteArrayBodyPart(keyStoreBytes, PKCS12_MEDIA_TYPE.toString(), keyStoreFileName).
            build());
    }
    
    public EndUserApplication getEndUserApplication()
    {
        if (getApplication().canAs(EndUserApplication.class))
            return getApplication().as(EndUserApplication.class);
        else
            return getApplication().as(AdminApplication.class).getEndUserApplication();
    }

    public URI getURI()
    {
        return uri;
    }
    
    public Application getApplication()
    {
        return application;
    }
    
    public Ontology getOntology()
    {
        return ontology;
    }

    public int getValidityDays()
    {
        return validityDays;
    }
      
    public Model getCountryModel()
    {
        return countryModel;
    }
    
    public UriBuilder getAgentContainerUriBuilder()
    {
        return agentContainerUriBuilder.clone();
    }

    public UriBuilder getAuthorizationContainerUriBuilder()
    {
        return authorizationContainerUriBuilder.clone();
    }
    
    public Address getSignUpAddress()
    {
        return signUpAddress;
    }
    
    public String getEmailSubject()
    {
        return emailSubject;
    }
    
    public String getEmailText()
    {
        return emailText;
    }
    
}