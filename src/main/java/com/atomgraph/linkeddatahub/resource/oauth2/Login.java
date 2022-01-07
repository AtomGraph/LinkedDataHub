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
package com.atomgraph.linkeddatahub.resource.oauth2;

import com.atomgraph.core.MediaTypes;
import com.atomgraph.core.exception.ConfigurationException;
import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.listener.EMailListener;
import com.atomgraph.linkeddatahub.model.Service;
import static com.atomgraph.linkeddatahub.resource.SignUp.AGENT_PATH;
import static com.atomgraph.linkeddatahub.resource.SignUp.AUTHORIZATION_PATH;
import com.atomgraph.linkeddatahub.resource.oauth2.google.Authorize;
import com.atomgraph.linkeddatahub.server.filter.request.auth.IDTokenFilter;
import com.atomgraph.linkeddatahub.server.model.impl.GraphStoreImpl;
import com.atomgraph.linkeddatahub.server.util.MessageBuilder;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.linkeddatahub.vocabulary.ADM;
import com.atomgraph.linkeddatahub.vocabulary.APLC;
import com.atomgraph.linkeddatahub.vocabulary.FOAF;
import com.atomgraph.linkeddatahub.vocabulary.Google;
import com.atomgraph.linkeddatahub.vocabulary.LACL;
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
import javax.mail.MessagingException;
import javax.servlet.ServletConfig;
import javax.ws.rs.BadRequestException;
import javax.ws.rs.DefaultValue;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
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
import javax.ws.rs.core.UriBuilder;
import javax.ws.rs.core.UriInfo;
import javax.ws.rs.ext.Providers;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.query.ParameterizedSparqlString;
import org.apache.jena.query.Query;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.NodeIterator;
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
@Path("oauth2/login")
public class Login extends GraphStoreImpl
{

    private static final Logger log = LoggerFactory.getLogger(Login.class);

    public static final String TOKEN_ENDPOINT = "https://oauth2.googleapis.com/token";
    public static final String USER_INFO_ENDPOINT = "https://openidconnect.googleapis.com/v1/userinfo";
    public static final String ACCOUNT_PATH = "acl/users/";

    private final HttpHeaders httpHeaders;
    private final Application application;
    private final String emailSubject;
    private final String emailText;
    private final Query userAccountQuery;
    private final String clientID, clientSecret;
    
    @Inject
    public Login(@Context Request request, @Context UriInfo uriInfo, MediaTypes mediaTypes, @Context HttpHeaders httpHeaders,
            com.atomgraph.linkeddatahub.apps.model.Application application, Optional<Ontology> ontology, Optional<Service> service,
            @Context Providers providers, com.atomgraph.linkeddatahub.Application system, @Context ServletConfig servletConfig)
    {
        super(request, uriInfo, mediaTypes, ontology, service, providers, system);
        this.httpHeaders = httpHeaders;
        this.application = application;
        
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
                URI agentGraphUri = getUriInfo().getBaseUriBuilder().path(AGENT_PATH).path("{slug}/").build(UUID.randomUUID().toString());

                String email = jwt.getClaim("email").asString();
                createAgent(agentModel,
                    agentGraphUri,
                    agentModel.createResource(getUriInfo().getBaseUri().resolve(AGENT_PATH).toString()),
                    jwt.getClaim("given_name").asString(),
                    jwt.getClaim("family_name").asString(),
                    email,
                    jwt.getClaim("picture") != null ? jwt.getClaim("picture").asString() : null);
                // skolemize here because this Model will not go through SkolemizingModelProvider
                getSkolemizer(getUriInfo().getBaseUriBuilder(), UriBuilder.fromUri(agentGraphUri)).build(agentModel);
                
                ResIterator it = agentModel.listResourcesWithProperty(FOAF.mbox);
                try
                {
                    // we need to retrieve resources again because they've changed from bnodes to URIs
                    Resource agent = it.next();
                
                    Model accountModel = ModelFactory.createDefaultModel();
                    URI userAccountGraphUri = getUriInfo().getBaseUriBuilder().path(ACCOUNT_PATH).path("{slug}/").build(UUID.randomUUID().toString());
                    Resource userAccount = createUserAccount(accountModel,
                        userAccountGraphUri,
                        accountModel.createResource(getUriInfo().getBaseUri().resolve(ACCOUNT_PATH).toString()),
                        jwt.getSubject(),
                        jwt.getIssuer(),
                        jwt.getClaim("name").asString(),
                        email);
                    userAccount.addProperty(SIOC.ACCOUNT_OF, agent);
                        
                    getSkolemizer(getUriInfo().getBaseUriBuilder(), UriBuilder.fromUri(userAccountGraphUri)).build(accountModel);
                    Response userAccountResponse = super.post(accountModel, false, userAccountGraphUri);
                    if (userAccountResponse.getStatus() != Response.Status.CREATED.getStatusCode())
                    {
                        if (log.isErrorEnabled()) log.error("Cannot create UserAccount");
                        throw new WebApplicationException("Cannot create UserAccount");
                    }
                    if (log.isDebugEnabled()) log.debug("Created UserAccount for user ID: {}", jwt.getSubject());

                    NodeIterator userAccountIt = accountModel.listObjectsOfProperty(ResourceFactory.createResource(userAccountGraphUri.toString()), FOAF.primaryTopic);
                    try
                    {
                        userAccount = userAccountIt.next().asResource();

                        agent.addProperty(FOAF.account, userAccount);
                        agentModel.add(agentModel.createResource(getSystem().getSecretaryWebIDURI().toString()), ACL.delegates, agent); // make secretary delegate whis agent

                        Response agentResponse = super.post(agentModel, false, agentGraphUri);
                        if (agentResponse.getStatus() != Response.Status.CREATED.getStatusCode())
                        {
                            if (log.isErrorEnabled()) log.error("Cannot create Agent");
                            throw new WebApplicationException("Cannot create Agent");
                        }

                        Model authModel = ModelFactory.createDefaultModel();
                        URI authGraphUri = getUriInfo().getBaseUriBuilder().path(AUTHORIZATION_PATH).path("{slug}/").build(UUID.randomUUID().toString());
                        createAuthorization(authModel,
                            authGraphUri,
                            getOntology().getURI(),
                            accountModel.createResource(getUriInfo().getBaseUri().resolve(AUTHORIZATION_PATH).toString()),
                            agentGraphUri,
                            userAccountGraphUri);
                        getSkolemizer(getUriInfo().getBaseUriBuilder(), UriBuilder.fromUri(authGraphUri)).build(authModel);
                        Response authResponse = super.post(authModel, false, authGraphUri);
                        if (authResponse.getStatus() != Response.Status.CREATED.getStatusCode())
                        {
                            if (log.isErrorEnabled()) log.error("Cannot create Authorization");
                            throw new WebApplicationException("Cannot create Authorization");
                        }

                        // remove secretary WebID from cache
                        getSystem().getEventBus().post(new com.atomgraph.linkeddatahub.server.event.SignUp(getSystem().getSecretaryWebIDURI()));

                        if (log.isDebugEnabled()) log.debug("Created Agent for user ID: {}", jwt.getSubject());
                        sendEmail(agent);
                    }
                    finally
                    {
                        userAccountIt.close();
                    }
                }
                catch (UnsupportedEncodingException | MessagingException | WebApplicationException ex)
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
    
    public Resource createAgent(Model model, URI graphURI, Resource container, String givenName, String familyName, String email, String imgUrl)
    {
        Resource item =  model.createResource(graphURI.toString()).
            addProperty(RDF.type, ADM.Item).
            addProperty(SIOC.HAS_CONTAINER, container).
            addLiteral(DH.slug, UUID.randomUUID().toString());
        
        Resource agent = model.createResource().
            addProperty(RDF.type, ADM.Agent).
            addLiteral(FOAF.givenName, givenName).
            addLiteral(FOAF.familyName, familyName).
            addProperty(FOAF.mbox, model.createResource("mailto:" + email)).
            addLiteral(DH.slug, UUID.randomUUID().toString()); // TO-DO: get rid of slug properties!
        if (imgUrl != null) agent.addProperty(FOAF.img, model.createResource(imgUrl));
            
        item.addProperty(FOAF.primaryTopic, agent);
        
        return agent;
    }
    
    public Resource createUserAccount(Model model, URI graphURI, Resource container, String id, String issuer, String name, String email)
    {
        Resource item = model.createResource(graphURI.toString()).
            addProperty(RDF.type, ADM.Item).
            addProperty(SIOC.HAS_CONTAINER, container).
            addLiteral(DH.slug, UUID.randomUUID().toString());
        
        Resource account = model.createResource().
            addLiteral(DCTerms.created, GregorianCalendar.getInstance()).
            addProperty(RDF.type, ADM.UserAccount).
            addLiteral(SIOC.ID, id).
            addLiteral(LACL.issuer, issuer).
            addLiteral(SIOC.NAME, name).
            addProperty(SIOC.EMAIL, model.createResource("mailto:" + email)).
            addLiteral(DH.slug, UUID.randomUUID().toString()); // TO-DO: get rid of slug properties!
        
        item.addProperty(FOAF.primaryTopic, account);
        
        return account;
    }

    public Resource createAuthorization(Model model, URI graphURI, String namespace, Resource container, URI agentGraphURI, URI userAccountGraphURI)
    {
        Resource item = model.createResource(graphURI.toString()).
            addProperty(RDF.type, ADM.Item).
            addProperty(SIOC.HAS_CONTAINER, container).
            addLiteral(DH.slug, UUID.randomUUID().toString());
        
        Resource auth = model.createResource().
            addProperty(RDF.type, ADM.Authorization).
            addLiteral(DH.slug, UUID.randomUUID().toString()). // TO-DO: get rid of slug properties!
            addProperty(ACL.accessTo, ResourceFactory.createResource(agentGraphURI.toString())).
            addProperty(ACL.accessTo, ResourceFactory.createResource(userAccountGraphURI.toString())).
            addProperty(ACL.mode, ACL.Read).
            addProperty(ACL.agentClass, FOAF.Agent).
            addProperty(ACL.agentClass, ACL.AuthenticatedAgent);
        
        item.addProperty(FOAF.primaryTopic, auth);
        
        return auth;
    }
    
    public void sendEmail(Resource agent) throws MessagingException, UnsupportedEncodingException
    {
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
                agent.getURI()));
        
        if (getSystem().getNotificationAddress() != null) builder = builder.from(getSystem().getNotificationAddress());

        EMailListener.submit(builder.build());
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
    
    public Service getAgentService()
    {
        return getApplication().getService();
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
