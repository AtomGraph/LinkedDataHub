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
package com.atomgraph.linkeddatahub.resource.admin;

import javax.ws.rs.core.Context;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.Request;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.core.exception.ConfigurationException;
import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.listener.EMailListener;
import com.atomgraph.linkeddatahub.server.model.impl.GraphStoreImpl;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.atomgraph.linkeddatahub.server.util.MessageBuilder;
import com.atomgraph.linkeddatahub.server.util.Skolemizer;
import com.atomgraph.linkeddatahub.server.util.WebIDCertGen;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.linkeddatahub.vocabulary.LDHC;
import com.atomgraph.linkeddatahub.vocabulary.Cert;
import com.atomgraph.linkeddatahub.vocabulary.FOAF;
import com.atomgraph.linkeddatahub.vocabulary.LACL;
import com.atomgraph.processor.vocabulary.DH;
import com.atomgraph.processor.vocabulary.SIOC;
import com.atomgraph.server.exception.SPINConstraintViolationException;
import com.atomgraph.server.exception.SkolemizationException;
import com.atomgraph.spinrdf.constraints.ConstraintViolation;
import com.atomgraph.spinrdf.constraints.ObjectPropertyPath;
import com.atomgraph.spinrdf.constraints.SimplePropertyPath;
import com.google.common.base.CharMatcher;
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
import javax.mail.MessagingException;
import javax.servlet.ServletConfig;
import javax.ws.rs.DefaultValue;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.QueryParam;
import javax.ws.rs.InternalServerErrorException;
import javax.ws.rs.Path;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.SecurityContext;
import javax.ws.rs.core.UriInfo;
import javax.ws.rs.ext.Providers;
import static org.apache.jena.datatypes.xsd.XSDDatatype.XSDhexBinary;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.query.ParameterizedSparqlString;
import org.apache.jena.query.Query;
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
 * JAX-RS endpoint that handles signups.
 * Creates a new agent with a public key and sends a notification email with an attached WebID certificate.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Path("sign up")
public class SignUp extends GraphStoreImpl
{
    
    private static final Logger log = LoggerFactory.getLogger(SignUp.class);
    
    /** Keystore type */
    public static final String STORE_TYPE = "PKCS12";
    /** WebID client certificate alias */
    public static final String KEY_ALIAS = "linkeddatahub-client";
    /** Minimum length of the WebID client certificate password */
    public static final int MIN_PASSWORD_LENGTH = 6;
    /** Media type of the WebID client certificate */
    public static final MediaType PKCS12_MEDIA_TYPE = MediaType.valueOf("application/x-pkcs12");
    /** Relative URL to the RDF file with country metadata */
    public static final String COUNTRY_DATASET_PATH = "/static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/countries.rdf";
    /** Relative URL of the agent container */
    public static final String AGENT_PATH = "acl/agents/";
    /** Relative URL of the public key container */
    public static final String PUBLIC_KEY_PATH = "acl/public-keys/";
    /** Relative URL of the authorization container */
    public static final String AUTHORIZATION_PATH = "acl/authorizations/";

    private final Model countryModel;
    private final String emailSubject;
    private final String emailText;
    private final int validityDays;
    private final boolean download;

    /**
     * Constructs signup resource.
     * 
     * @param request current request
     * @param uriInfo request URI information
     * @param mediaTypes registry of readable/writable media types
     * @param application current application
     * @param ontology current application's ontology
     * @param service current application's service
     * @param securityContext JAX-RS security context
     * @param agentContext authenticated agent's context
     * @param providers registry of JAX-RS providers
     * @param system system application
     * @param servletConfig servlet config
     */
    // TO-DO: move to AuthenticationExceptionMapper and handle as state instead of URI resource?
    @Inject
    public SignUp(@Context Request request, @Context UriInfo uriInfo, MediaTypes mediaTypes,
            com.atomgraph.linkeddatahub.apps.model.Application application, Optional<Ontology> ontology, Optional<Service> service,
            @Context SecurityContext securityContext, Optional<AgentContext> agentContext,
            @Context Providers providers, com.atomgraph.linkeddatahub.Application system, @Context ServletConfig servletConfig)
    {
        super(request, uriInfo, mediaTypes, application, ontology, service, securityContext, agentContext, providers, system);
        if (log.isDebugEnabled()) log.debug("Constructing {}", getClass());
        
        if (!application.canAs(AdminApplication.class)) // we are supposed to be in the admin app
            throw new IllegalStateException("Application cannot be cast to apl:AdminApplication");
        
        try (InputStream countries = servletConfig.getServletContext().getResourceAsStream(COUNTRY_DATASET_PATH))
        {
            countryModel = ModelFactory.createDefaultModel();
            RDFDataMgr.read(countryModel, countries, null, Lang.RDFXML);
        }
        catch (IOException ex)
        {
            throw new InternalServerErrorException(ex);
        }
        
        emailSubject = servletConfig.getServletContext().getInitParameter(LDHC.signUpEMailSubject.getURI());
        if (emailSubject == null) throw new InternalServerErrorException(new ConfigurationException(LDHC.signUpEMailSubject));

        emailText = servletConfig.getServletContext().getInitParameter(LDHC.webIDSignUpEMailText.getURI());
        if (emailText == null) throw new InternalServerErrorException(new ConfigurationException(LDHC.webIDSignUpEMailText));
        
        if (servletConfig.getServletContext().getInitParameter(LDHC.signUpCertValidity.getURI()) == null)
            throw new InternalServerErrorException(new ConfigurationException(LDHC.signUpCertValidity));
        validityDays = Integer.parseInt(servletConfig.getServletContext().getInitParameter(LDHC.signUpCertValidity.getURI()));
        
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
    public Response post(Model agentModel, @QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        URI agentGraphUri = getUriInfo().getBaseUriBuilder().path(AGENT_PATH).path("{slug}/").build(UUID.randomUUID().toString());
        new Skolemizer(agentGraphUri.toString()).apply(agentModel);
        
        ResIterator it = agentModel.listResourcesWithProperty(RDF.type, FOAF.Person);
        try
        {
            Resource agent = it.next();
            String password = validateAndRemovePassword(agent);
            // TO-DO: trim values
            Resource mbox = agent.getRequiredProperty(FOAF.mbox).getResource();
            
            ParameterizedSparqlString pss = new ParameterizedSparqlString(getAgentQuery().toString());
            pss.setParam(FOAF.mbox.getLocalName(), mbox);
            boolean agentExists = !getAgentService().getSPARQLClient().loadModel(pss.asQuery()).isEmpty();
            if (agentExists) throw createSPINConstraintViolationException(agent, FOAF.mbox, "Agent with this mailbox already exists");
            
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
            agent = appendItem(agentModel,
                agentGraphUri,
                agentModel.createResource(getUriInfo().getBaseUri().resolve(AGENT_PATH).toString()),
                agent); // append Item data
            
            String uuid = UUID.randomUUID().toString();
            String keyStoreFileName = uuid + ".p12";
            java.nio.file.Path keyStorePath = Paths.get(System.getProperty("java.io.tmpdir") + File.separator + keyStoreFileName);

            if (!agent.isURIResource()) throw new IllegalStateException("Agent is not a URI resource");
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
                URI publicKeyGraphUri = getUriInfo().getBaseUriBuilder().path(PUBLIC_KEY_PATH).path("{slug}/").build(UUID.randomUUID().toString());
                Model publicKeyModel = ModelFactory.createDefaultModel();
                createPublicKey(publicKeyModel,
                    publicKeyGraphUri,
                    publicKeyModel.createResource(getUriInfo().getBaseUri().resolve(PUBLIC_KEY_PATH).toString()),
                    certPublicKey);
                new Skolemizer(publicKeyGraphUri.toString()).apply(publicKeyModel);
                
                Response publicKeyResponse = super.post(publicKeyModel, false, publicKeyGraphUri);
                if (publicKeyResponse.getStatus() != Response.Status.CREATED.getStatusCode())
                {
                    if (log.isErrorEnabled()) log.error("Cannot create PublicKey");
                    throw new InternalServerErrorException("Cannot create PublicKey");
                }

                Resource publicKey = publicKeyModel.createResource(publicKeyGraphUri.toString()).getPropertyResourceValue(FOAF.primaryTopic);
                agent.addProperty(Cert.key, publicKey); // add public key
                agentModel.add(agentModel.createResource(getSystem().getSecretaryWebIDURI().toString()), ACL.delegates, agent); // make secretary delegate whis agent

                Response agentResponse = super.post(agentModel, false, agentGraphUri);
                if (agentResponse.getStatus() != Response.Status.CREATED.getStatusCode())
                {
                    if (log.isErrorEnabled()) log.error("Cannot create Agent");
                    throw new InternalServerErrorException("Cannot create Agent");
                }

                URI authGraphUri = getUriInfo().getBaseUriBuilder().path(AUTHORIZATION_PATH).path("{slug}/").build(UUID.randomUUID().toString());
                Model authModel = ModelFactory.createDefaultModel();
                // creating authorizations for the Agent and PublicKey documents
                createAuthorization(authModel,
                    authGraphUri,
                    authModel.createResource(getUriInfo().getBaseUri().resolve(AUTHORIZATION_PATH).toString()),
                    agentGraphUri,
                    publicKeyGraphUri);
                new Skolemizer(authGraphUri.toString()).apply(authModel);

                Response authResponse = super.post(authModel, false, authGraphUri);
                if (authResponse.getStatus() != Response.Status.CREATED.getStatusCode())
                {
                    if (log.isErrorEnabled()) log.error("Cannot create Authorization");
                    throw new InternalServerErrorException("Cannot create Authorization");
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

                    return Response.ok().
                        entity(agentModel.add(publicKeyModel)).
                        build(); // don't return 201 Created as we don't want a redirect in client.xsl
                }
            }
        }
        catch (SPINConstraintViolationException ex)
        {
            throw ex; // propagate
        }
        catch (IllegalArgumentException ex)
        {
            throw new SkolemizationException(ex, agentModel);
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

    /**
     * Validates agent metadata and removes plain-text password value.
     * 
     * @param agent wannabe agent resource
     * @return password string
     * @throws SPINConstraintViolationException thrown if password is invalid
     */
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
        if (!CharMatcher.ascii().matchesAllOf(password))
            throw createSPINConstraintViolationException(certStmt.getResource(), LACL.password, "Certificate password must only contain ASCII characters");

        // remove password so we don't store it as RDF
        passwordStmt.remove();
        certStmt.remove();
        return password;
    }
    
    /**
     * Creates constraint violation exception.
     * This is done to emulate SPIN validation so the same UI logic can still apply.
     * 
     * @param resource violating RDF resource
     * @param property violating property
     * @param message violation message
     * @return violation exception
     */
    public SPINConstraintViolationException createSPINConstraintViolationException(Resource resource, Property property, String message)
    {
        List<ConstraintViolation> cvs = new ArrayList<>();
        List<SimplePropertyPath> paths = new ArrayList<>();
        paths.add(new ObjectPropertyPath(resource, property));
        cvs.add(new ConstraintViolation(resource, paths, null, message, null));
        return new SPINConstraintViolationException(cvs, resource.getModel());
    }

    /**
     * Appends Item document resource to the RDF model.
     * 
     * @param model agent model
     * @param graphURI graph URI
     * @param container agent container resource
     * @param agent agent resource
     * @return item resource
     */
    public Resource appendItem(Model model, URI graphURI, Resource container, Resource agent)
    {
        Resource item = model.createResource(graphURI.toString()).
            addProperty(RDF.type, DH.Item).
            addProperty(SIOC.HAS_CONTAINER, container).
            addLiteral(DH.slug, UUID.randomUUID().toString()); // TO-DO: does not match the URI

        item.addProperty(FOAF.primaryTopic, agent);

        return agent;
    }
    
    /**
     * Creates new public key resource.
     * 
     * @param model RDF model
     * @param graphURI graph URI
     * @param container container resource
     * @param publicKey RSA public key
     * @return public key resource
     */
    public Resource createPublicKey(Model model, URI graphURI, Resource container, RSAPublicKey publicKey)
    {
        Resource item = model.createResource(graphURI.toString()).
            addProperty(RDF.type, DH.Item).
            addProperty(SIOC.HAS_CONTAINER, container).
            addLiteral(DH.slug, UUID.randomUUID().toString());
        
        Resource publicKeyRes = model.createResource().
            addProperty(RDF.type, Cert.PublicKey).
            addLiteral(Cert.exponent, publicKey.getPublicExponent()).
            addLiteral(Cert.modulus, ResourceFactory.createTypedLiteral(publicKey.getModulus().toString(16), XSDhexBinary));
        
        item.addProperty(FOAF.primaryTopic, publicKeyRes);
        
        return publicKeyRes;
    }
    
    /**
     * Creates new authorization resource.
     * 
     * @param model RDF model
     * @param graphURI graph URI
     * @param container container resource
     * @param agentGraphURI agent's graph URI
     * @param publicKeyGraphURI public key's graph URI
     * @return authorization resource
     */
    public Resource createAuthorization(Model model, URI graphURI, Resource container, URI agentGraphURI, URI publicKeyGraphURI)
    {
        Resource item = model.createResource(graphURI.toString()).
            addProperty(RDF.type, DH.Item).
            addProperty(SIOC.HAS_CONTAINER, container).
            addLiteral(DH.slug, UUID.randomUUID().toString());
        
        Resource auth = model.createResource().
            addProperty(RDF.type, ACL.Authorization).
            addLiteral(DH.slug, UUID.randomUUID().toString()). // TO-DO: get rid of slug properties!
            addProperty(ACL.accessTo, ResourceFactory.createResource(agentGraphURI.toString())).
            addProperty(ACL.accessTo, ResourceFactory.createResource(publicKeyGraphURI.toString())).
            addProperty(ACL.mode, ACL.Read).
            addProperty(ACL.agentClass, FOAF.Agent).
            addProperty(ACL.agentClass, ACL.AuthenticatedAgent);

        item.addProperty(FOAF.primaryTopic, auth);
        
        return auth;
    }
    
    /**
     * Sends signup notification email to agent.
     * 
     * @param agent agent resource
     * @param certExpires WebID client certificate's expiration date
     * @param keyStoreBytes binary key store
     * @param keyStoreFileName keystore filename
     * @throws MessagingException error sending email
     * @throws UnsupportedEncodingException encoding error
     */
    
    public void sendEmail(Resource agent, LocalDate certExpires, byte[] keyStoreBytes, String keyStoreFileName) throws MessagingException, UnsupportedEncodingException
    {
        // send email with attached KeyStore
        String givenName = agent.getRequiredProperty(FOAF.givenName).getString();
        String familyName = agent.getRequiredProperty(FOAF.familyName).getString();
        String fullName = givenName + " " + familyName;
        // we expect foaf:mbox value as mailto: URI (it gets converted from literal in Model provider)
        String mbox = agent.getRequiredProperty(FOAF.mbox).getResource().getURI().substring("mailto:".length());

        // labels and links need to come from the end-user app
        MessageBuilder builder = getSystem().getMessageBuilder().
            subject(String.format(getEmailSubject(),
                getEndUserApplication().getProperty(DCTerms.title).getString(),
                fullName)).
            to(mbox, fullName).
            textBodyPart(String.format(getEmailText(),
                getEndUserApplication().getProperty(DCTerms.title).getString(),
                getEndUserApplication().getBase(),
                agent.getURI(),
                certExpires.format(DateTimeFormatter.ISO_LOCAL_DATE))).
            byteArrayBodyPart(keyStoreBytes, PKCS12_MEDIA_TYPE.toString(), keyStoreFileName);
        
        if (getSystem().getNotificationAddress() != null) builder = builder.from(getSystem().getNotificationAddress());

        EMailListener.submit(builder.build());
    }
    
    /**
     * Returns the end-user application of the current dataspace.
     * 
     * @return end-user application
     */
    public EndUserApplication getEndUserApplication()
    {
        if (getApplication().canAs(EndUserApplication.class))
            return getApplication().as(EndUserApplication.class);
        else
            return getApplication().as(AdminApplication.class).getEndUserApplication();
    }
    
    /**
     * Returns the SPARQL service from which agent data is retrieved.
     * 
     * @return SPARQL service
     */
    public Service getAgentService()
    {
        return getApplication().getService();
    }
    
    /**
     * Returns URI of this resource.
     * 
     * @return resource URI
     */
    public URI getURI()
    {
        return getUriInfo().getAbsolutePath();
    }

    /**
     * Returns the number of days until the WebID certificate expires.
     * 
     * @return number of days
     */
    public int getValidityDays()
    {
        return validityDays;
    }

    /**
     * Returns RDF model with country metadata.
     * 
     * @return RDF model
     */
    public Model getCountryModel()
    {
        return countryModel;
    }

    /**
     * Returns the subject of the notification email.
     * 
     * @return email subject
     */
    public String getEmailSubject()
    {
        return emailSubject;
    }
    
    /**
     * Returns the text of the notification email.
     * 
     * @return email text
     */
    public String getEmailText()
    {
        return emailText;
    }
    
    /**
     * Returns SPARQL query used to load agent by mailbox.
     * 
     * @return SPARQL query
     */
    public Query getAgentQuery()
    {
        return getSystem().getAgentQuery();
    }
    
}