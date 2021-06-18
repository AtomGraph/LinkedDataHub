package com.atomgraph.linkeddatahub.resource.oauth2;

import com.atomgraph.core.MediaTypes;
import com.atomgraph.core.exception.ConfigurationException;
import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.listener.EMailListener;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.resource.oauth2.google.Authorize;
import com.atomgraph.linkeddatahub.server.filter.request.auth.IDTokenFilter;
import com.atomgraph.linkeddatahub.server.model.impl.GraphStoreImpl;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.linkeddatahub.vocabulary.APLC;
import com.atomgraph.linkeddatahub.vocabulary.FOAF;
import com.atomgraph.linkeddatahub.vocabulary.Google;
import com.atomgraph.linkeddatahub.vocabulary.LACL;
import com.atomgraph.processor.util.Skolemizer;
import com.atomgraph.processor.vocabulary.DH;
import com.atomgraph.processor.vocabulary.SIOC;
import com.auth0.jwt.JWT;
import com.auth0.jwt.interfaces.DecodedJWT;
import java.io.UnsupportedEncodingException;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.Base64;
import java.util.GregorianCalendar;
import java.util.Optional;
import java.util.UUID;
import java.util.regex.Pattern;
import javax.inject.Inject;
import javax.json.JsonObject;
import javax.mail.Address;
import javax.mail.MessagingException;
import javax.mail.internet.AddressException;
import javax.mail.internet.InternetAddress;
import javax.servlet.ServletConfig;
import javax.ws.rs.BadRequestException;
import javax.ws.rs.DefaultValue;
import javax.ws.rs.GET;
import javax.ws.rs.QueryParam;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.client.Entity;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.Cookie;
import javax.ws.rs.core.Form;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.NewCookie;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.UriInfo;
import javax.ws.rs.ext.Providers;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.query.ParameterizedSparqlString;
import org.apache.jena.query.Query;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;
import org.glassfish.jersey.server.internal.process.MappableException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class Login extends GraphStoreImpl
{

    private static final Logger log = LoggerFactory.getLogger(Login.class);

    public static final String TOKEN_ENDPOINT = "https://oauth2.googleapis.com/token";
    public static final String USER_INFO_ENDPOINT = "https://openidconnect.googleapis.com/v1/userinfo";
    
    private final HttpHeaders httpHeaders;
    private final Application application;
    private final Ontology ontology;
    private final Address signUpAddress;
    private final String emailSubject;
    private final String emailText;
    private final Query userAccountQuery;
    private final String clientID, clientSecret;
    
    @Inject
    public Login(@Context UriInfo uriInfo, @Context Request request, MediaTypes mediaTypes, @Context HttpHeaders httpHeaders,
            Optional<Service> service, Optional<com.atomgraph.linkeddatahub.apps.model.Application> application, Optional<Ontology> ontology,
            @Context Providers providers, com.atomgraph.linkeddatahub.Application system, @Context ServletConfig servletConfig)
    {
        super(request, service, mediaTypes,
            uriInfo, providers, system);
        this.httpHeaders = httpHeaders;
        this.application = application.get();
        this.ontology = ontology.get();

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

        emailText = servletConfig.getServletContext().getInitParameter(APLC.oAuthSignUpEMailText.getURI());
        if (emailText == null) throw new WebApplicationException(new ConfigurationException(APLC.oAuthSignUpEMailText));
        
        userAccountQuery = system.getUserAccountQuery();
        clientID = (String)system.getProperty(Google.clientID.getURI());
        clientSecret = (String)system.getProperty(Google.clientSecret.getURI());
    }
    
    @GET
    @Override
    public Response get(@QueryParam("default") @DefaultValue("false") Boolean defaultGraph, @QueryParam("graph") URI graphUri)
    {
        if (getClientID() == null) throw new ConfigurationException(Google.clientID);
        if (getClientSecret() == null) throw new ConfigurationException(Google.clientSecret);
        
        String error = getUriInfo().getQueryParameters().getFirst("error");
        
        if (error != null)
        {
            if (log.isErrorEnabled()) log.error("OAuth callback error: {}", error);
            throw new WebApplicationException(error);
        }

        String code = getUriInfo().getQueryParameters().getFirst("code");
        String state = getUriInfo().getQueryParameters().getFirst("state"); // TO-DO: verify by matching against state generated in Authorize
        Cookie stateCookie = getHttpHeaders().getCookies().get(Authorize.COOKIE_NAME);
        if (!state.equals(stateCookie.getValue())) throw new BadRequestException("OAuth 'state' parameter failed to validate");
        
        Form form = new Form().
            param("grant_type", "authorization_code").
            param("client_id", getClientID()).
            param("redirect_uri", getUriInfo().getAbsolutePath().toString()).
            param("client_secret", getClientSecret()).
            param("code", code);
                
        try (Response cr = getSystem().getClient().target(TOKEN_ENDPOINT).
                request().post(Entity.form(form)))
        {
            JsonObject response = cr.readEntity(JsonObject.class);
            if (response.containsKey("error"))
            {
                if (log.isErrorEnabled()) log.error("OAuth error: '{}'", response.getString("error"));
                throw new WebApplicationException(response.getString("error"));
            }

            String idToken = response.getString("id_token");
            DecodedJWT jwt = JWT.decode(idToken);

            ParameterizedSparqlString pss = new ParameterizedSparqlString(getUserAccountQuery().toString());
            pss.setLiteral(SIOC.ID.getLocalName(), jwt.getSubject());
            pss.setLiteral(LACL.issuer.getLocalName(), jwt.getIssuer());
            boolean accountExists = !getAgentService().getSPARQLClient().loadModel(pss.asQuery()).isEmpty();

            if (!accountExists) // UserAccount with this ID does not exist yet
            {
                Model agentModel = ModelFactory.createDefaultModel();
//                InfModel infModel = ModelFactory.createRDFSModel(getOntology().getOntModel(), agentModel);
                String email = jwt.getClaim("email").asString();
                //String issuer = jwt.getIssuer();
                createAgent(agentModel,
                    getOntology().getURI(),
                    agentModel.createResource(getUriInfo().getBaseUri().resolve("acl/agents/").toString()),
                    jwt.getClaim("given_name").asString(),
                    jwt.getClaim("family_name").asString(),
                    email,
                    jwt.getClaim("picture") != null ? jwt.getClaim("picture").asString() : null);
                // skolemize here because this Model will not go through SkolemizingModelProvider
                agentModel = new Skolemizer(getOntology(), getUriInfo().getBaseUriBuilder(), getUriInfo().getBaseUriBuilder().path("acl/agents/")).build(agentModel);
                
                ResIterator it = agentModel.listResourcesWithProperty(FOAF.mbox);
                try
                {
                    // we need to retrieve resources again because they've changed from bnodes to URIs
                    Resource agent = it.next();
                
                    Model accountModel = ModelFactory.createDefaultModel();
                    Resource userAccount = createUserAccount(accountModel,
                        getOntology().getURI(),
                        accountModel.createResource(getUriInfo().getBaseUri().resolve("acl/users/").toString()),
                        jwt.getSubject(),
                        jwt.getIssuer(),
                        jwt.getClaim("name").asString(),
                        email);
                    userAccount.addProperty(SIOC.ACCOUNT_OF, agent);
                    accountModel = new Skolemizer(getOntology(), getUriInfo().getBaseUriBuilder(), getUriInfo().getBaseUriBuilder().path("acl/users/")).build(accountModel);

                    Resource userAccountForClass = ResourceFactory.createResource(getOntology().getNameSpace() + LACL.PublicKey.getLocalName());
                    Response userAccountResponse = super.post(accountModel, URI.create(userAccountForClass.getURI()));
                    if (userAccountResponse.getStatus() != Response.Status.CREATED.getStatusCode())
                    {
                        if (log.isErrorEnabled()) log.error("Cannot create UserAccount");
                        throw new WebApplicationException("Cannot create UserAccount");
                    }
                    if (log.isDebugEnabled()) log.debug("Created UserAccount for user ID: {}", jwt.getSubject());

                    URI userAccountGraphUri = userAccountResponse.getLocation();
                    accountModel = (Model)super.get(false, userAccountGraphUri).getEntity();
                    userAccount = accountModel.createResource(userAccountGraphUri.toString()).getPropertyResourceValue(FOAF.primaryTopic);

                    agent.addProperty(FOAF.account, userAccount);
                    agentModel.add(agentModel.createResource(getSystem().getSecretaryWebIDURI().toString()), ACL.delegates, agent); // make secretary delegate whis agent

                    URI agentGraphUri = URI.create(agent.getURI());
                    agentGraphUri = new URI(agentGraphUri.getScheme(), agentGraphUri.getSchemeSpecificPart(), null).normalize(); // strip the possible fragment identifier

                    try (Response agentResponse = super.post(agentModel, false, agentGraphUri))
                    {
                        if (agentResponse.getStatus() != Response.Status.CREATED.getStatusCode())
                        {
                            if (log.isErrorEnabled()) log.error("Cannot create Agent");
                            throw new WebApplicationException("Cannot create Agent");
                        }

                        // remove secretary WebID from cache
                        getSystem().getEventBus().post(new com.atomgraph.linkeddatahub.server.event.SignUp(getSystem().getSecretaryWebIDURI()));

                        if (log.isDebugEnabled()) log.debug("Created Agent for user ID: {}", jwt.getSubject());
                        sendEmail(agent);
                    }
                }
                catch (UnsupportedEncodingException | URISyntaxException | MessagingException | WebApplicationException ex)
                {
                    throw new MappableException(ex);
                }
                finally
                {
                    it.close();
                }
            }
            
            String path = getApplication().as(AdminApplication.class).getEndUserApplication().getBaseURI().getPath();
            NewCookie jwtCookie = new NewCookie(IDTokenFilter.COOKIE_NAME, idToken, path, null, NewCookie.DEFAULT_VERSION, null, NewCookie.DEFAULT_MAX_AGE, false);
            URI originalReferer = URI.create(new String(Base64.getDecoder().decode(stateCookie.getValue())).split(Pattern.quote(";"))[1]);
            
            return Response.seeOther(originalReferer). // redirect to where the user started authentication
                cookie(jwtCookie).
                build();
        }
    }
    
    public boolean verify(DecodedJWT jwt)
    {
//            Algorithm algorithm = Algorithm.RSA256(null);
//            JWTVerifier verifier = JWT.require(algorithm).
//                withIssuer("auth0").
//                build();
//            DecodedJWT jwt = verifier.verify(idToken);
        return true;
        //throw new JWTVerificationException();
    }
    
    public Resource createAgent(Model model, String namespace, Resource container, String givenName, String familyName, String email, String imgUrl)
    {
        // TO-DO: improve class URI retrieval
        Resource cls = model.createResource(namespace + LACL.Agent.getLocalName()); // subclassOf LACL.Agent
        Resource itemCls = model.createResource(namespace + LACL.Agent.getLocalName() + "Item");

        Resource agentDoc =  model.createResource().
            addProperty(RDF.type, itemCls).
            addProperty(SIOC.HAS_CONTAINER, container).
            addLiteral(DH.slug, UUID.randomUUID().toString());
        
        Resource agent = model.createResource().
            addProperty(RDF.type, cls).
            addLiteral(FOAF.givenName, givenName).
            addLiteral(FOAF.familyName, familyName).
            addProperty(FOAF.mbox, model.createResource("mailto:" + email)).
            addProperty(FOAF.isPrimaryTopicOf, agentDoc);
        if (imgUrl != null) agent.addProperty(FOAF.img, model.createResource(imgUrl));
            
        agentDoc.addProperty(FOAF.primaryTopic, agent);
        
        return agent;
    }
    
    public Resource createUserAccount(Model model, String namespace, Resource container, String id, String issuer, String name, String email)
    {
        // TO-DO: improve class URI retrieval
        Resource cls = model.createResource(namespace + LACL.UserAccount.getLocalName()); // subclassOf LACL.UserAccount
        Resource itemCls = model.createResource(namespace + LACL.UserAccount.getLocalName() + "Item");

        Resource accountDoc = model.createResource().
            addProperty(RDF.type, itemCls).
            addProperty(SIOC.HAS_CONTAINER, container).
            addLiteral(DH.slug, UUID.randomUUID().toString());
        
        Resource account = model.createResource().
            addLiteral(DCTerms.created, GregorianCalendar.getInstance()).
            addProperty(RDF.type, cls).
            addLiteral(SIOC.ID, id).
            addLiteral(LACL.issuer, issuer).
            addLiteral(SIOC.NAME, name).
            addProperty(SIOC.EMAIL, model.createResource("mailto:" + email)).
            addProperty(FOAF.isPrimaryTopicOf, accountDoc);
        accountDoc.addProperty(FOAF.primaryTopic, account);

        return account;
    }

    public void sendEmail(Resource agent) throws MessagingException, UnsupportedEncodingException
    {
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
                agent.getURI())).
            build());
    }

    public EndUserApplication getEndUserApplication()
    {
        if (getApplication().canAs(EndUserApplication.class))
            return getApplication().as(EndUserApplication.class);
        else
            return getApplication().as(AdminApplication.class).getEndUserApplication();
    }
    
    public HttpHeaders getHttpHeaders()
    {
        return httpHeaders;
    }
    
    public Application getApplication()
    {
        return application;
    }

    public Ontology getOntology()
    {
        return ontology;
    }
    
    public Service getAgentService()
    {
        return getApplication().getService();
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

    public Query getUserAccountQuery()
    {
        return userAccountQuery;
    }
    
    private String getClientID()
    {
        return clientID;
    }
    
    private String getClientSecret()
    {
        return clientSecret;
    }
    
}
