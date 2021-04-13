package com.atomgraph.linkeddatahub.resource.oauth2;

import com.atomgraph.client.util.DataManager;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.core.exception.ConfigurationException;
import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.listener.EMailListener;
import com.atomgraph.linkeddatahub.model.Agent;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.resource.oauth2.google.Authorize;
import com.atomgraph.linkeddatahub.server.filter.request.auth.IDTokenFilter;
import com.atomgraph.linkeddatahub.server.model.ClientUriInfo;
import com.atomgraph.linkeddatahub.server.model.impl.ClientUriInfoImpl;
import com.atomgraph.linkeddatahub.server.model.impl.ResourceBase;
import com.atomgraph.linkeddatahub.server.security.AgentContext;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.linkeddatahub.vocabulary.APLC;
import com.atomgraph.linkeddatahub.vocabulary.APLT;
import com.atomgraph.linkeddatahub.vocabulary.FOAF;
import com.atomgraph.linkeddatahub.vocabulary.Google;
import com.atomgraph.linkeddatahub.vocabulary.LACL;
import com.atomgraph.processor.model.TemplateCall;
import com.atomgraph.processor.util.Skolemizer;
import com.atomgraph.processor.vocabulary.DH;
import com.atomgraph.processor.vocabulary.SIOC;
import com.auth0.jwt.JWT;
import com.auth0.jwt.interfaces.DecodedJWT;
import java.io.UnsupportedEncodingException;
import java.net.URI;
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
import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.BadRequestException;
import javax.ws.rs.GET;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.client.Entity;
import javax.ws.rs.container.ResourceContext;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.Cookie;
import javax.ws.rs.core.Form;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.MultivaluedHashMap;
import javax.ws.rs.core.MultivaluedMap;
import javax.ws.rs.core.NewCookie;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.Status;
import javax.ws.rs.core.SecurityContext;
import javax.ws.rs.core.UriInfo;
import javax.ws.rs.ext.Providers;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.query.Dataset;
import org.apache.jena.query.DatasetFactory;
import org.apache.jena.query.ParameterizedSparqlString;
import org.apache.jena.query.Query;
import org.apache.jena.rdf.model.InfModel;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;
import org.glassfish.jersey.server.internal.process.MappableException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class Login extends ResourceBase
{

    private static final Logger log = LoggerFactory.getLogger(Login.class);

    public static final String TOKEN_ENDPOINT = "https://oauth2.googleapis.com/token";
    public static final String USER_INFO_ENDPOINT = "https://openidconnect.googleapis.com/v1/userinfo";
    
    private final Address signUpAddress;
    private final String emailSubject;
    private final String emailText;
    private final Query userAccountQuery;
    private final String clientID, clientSecret;
    
    @Inject
    public Login(@Context UriInfo uriInfo, ClientUriInfo clientUriInfo, @Context Request request, MediaTypes mediaTypes,
            Service service, com.atomgraph.linkeddatahub.apps.model.Application application,
            Ontology ontology, Optional<TemplateCall> templateCall,
            @Context HttpHeaders httpHeaders, @Context ResourceContext resourceContext,
            @Context HttpServletRequest httpServletRequest, @Context SecurityContext securityContext,
            DataManager dataManager, @Context Providers providers,
            com.atomgraph.linkeddatahub.Application system, @Context ServletConfig servletConfig)
    {
        super(uriInfo, clientUriInfo, request, mediaTypes,
            service, application,
            ontology, templateCall,
            httpHeaders, resourceContext,
            httpServletRequest, securityContext,
            dataManager, providers,
            system);
        
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
    public Response get()
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
            Model agentModel = getAgentService().getSPARQLClient().loadModel(pss.asQuery());
            boolean accountExists = !agentModel.isEmpty();

            if (!accountExists) // UserAccount with this ID does not exist yet
            {
                Model model = ModelFactory.createDefaultModel();
                InfModel infModel = ModelFactory.createRDFSModel(getOntology().getOntModel(), model);
                String email = jwt.getClaim("email").asString();
                //String issuer = jwt.getIssuer();
                Resource agent = createAgent(model,
                    getOntology().getURI(),
                    model.createResource(getUriInfo().getBaseUri().resolve("acl/agents/").toString()),
                    jwt.getClaim("given_name").asString(),
                    jwt.getClaim("family_name").asString(),
                    email,
                    jwt.getClaim("picture") != null ? jwt.getClaim("picture").asString() : null);
                Resource userAccount = createUserAccount(model,
                    getOntology().getURI(),
                    model.createResource(getUriInfo().getBaseUri().resolve("acl/users/").toString()),
                    jwt.getSubject(),
                    jwt.getIssuer(),
                    jwt.getClaim("name").asString(),
                    email);
                userAccount.addProperty(SIOC.ACCOUNT_OF, agent);
                agent.addProperty(FOAF.account, userAccount);

                model.add(model.createResource(getSystem().getSecretaryWebIDURI().toString()), ACL.delegates, agent); // make secretary delegate whis agent
                
                // skolemize here because this Model will not go through SkolemizingModelProvider
                new Skolemizer(getOntology(), getUriInfo().getBaseUriBuilder(), getUriInfo().getBaseUriBuilder().path("acl/users/")).build(model);

                ResIterator it = model.listResourcesWithProperty(RDF.type, model.createResource(getOntology().getURI() + LACL.Agent.getLocalName()));
                try
                {
                    // we need to retrieve resources again because they've changed from bnodes to URIs
                    agent = it.next();
                    
                    SecurityContext securityContext = new AgentContext("JWT", agent.inModel(infModel).as(Agent.class));
                    Dataset dataset = DatasetFactory.create(model);
                    Response resp = createContainer(getUriInfo().getBaseUri().resolve("acl/users/"), LACL.UserAccount, securityContext).
                        post(dataset);

                    if (resp.getStatus() != Status.OK.getStatusCode())
                    {
                        if (log.isErrorEnabled()) log.error("Could not create UserAccount for user ID: {}", jwt.getSubject());
                        throw new WebApplicationException();
                    }
                    
                    // remove secretary WebID from cache
                    getSystem().getEventBus().post(new com.atomgraph.linkeddatahub.server.event.SignUp(getSystem().getSecretaryWebIDURI()));

                    if (log.isDebugEnabled()) log.debug("Created UserAccount for user ID: {}", jwt.getSubject());
                    sendEmail(agent);
                }
                catch (MessagingException | UnsupportedEncodingException ex)
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
                getApplication().getEndUserApplication().getProperty(DCTerms.title).getString(),
                fullName)).
            from(getSignUpAddress()).
            to(mbox, fullName).
            textBodyPart(String.format(getEmailText(),
                getApplication().getEndUserApplication().getProperty(DCTerms.title).getString(),
                getApplication().getEndUserApplication().getBase(),
                agent.getURI())).
            build());
    }
        
    public com.atomgraph.linkeddatahub.server.model.Resource createContainer(URI uri, Resource forClass, SecurityContext securityContext)
    {
        MultivaluedMap<String, String> queryParams = new MultivaluedHashMap();
        queryParams.add(APLT.forClass.getLocalName(), forClass.getURI());
        
        return createResource(uri, queryParams, securityContext);
    }
    
    public com.atomgraph.linkeddatahub.server.model.Resource createResource(URI requestUri, MultivaluedMap<String, String> queryParams, SecurityContext securityContext)
    {
        return new ResourceBase(
            new ClientUriInfoImpl(getUriInfo().getBaseUri(), requestUri, queryParams), getClientUriInfo(), getRequest(), getMediaTypes(),
            getService(), Optional.of(getApplication()), Optional.of(getOntology()), getTemplateCall(), getHttpHeaders(), getResourceContext(),
            getHttpServletRequest(), securityContext, getDataManager(), getProviders(),
            getSystem());
    }
    
    public Service getAgentService()
    {
        return getApplication().getService();
    }
    
    @Override
    public AdminApplication getApplication()
    {
        return super.getApplication().as(AdminApplication.class);
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
