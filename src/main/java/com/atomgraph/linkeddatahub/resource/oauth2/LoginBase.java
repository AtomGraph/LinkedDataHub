/**
 *  Copyright 2025 Martynas Jusevičius <martynas@atomgraph.com>
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
 */package com.atomgraph.linkeddatahub.resource.oauth2;

import com.atomgraph.core.exception.ConfigurationException;
import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.apps.model.Application;
import com.atomgraph.linkeddatahub.apps.model.EndUserApplication;
import com.atomgraph.linkeddatahub.listener.EMailListener;
import com.atomgraph.linkeddatahub.model.Service;
import static com.atomgraph.linkeddatahub.resource.admin.SignUp.AGENT_PATH;
import static com.atomgraph.linkeddatahub.resource.admin.SignUp.AUTHORIZATION_PATH;
import com.atomgraph.linkeddatahub.server.filter.response.CacheInvalidationFilter;
import com.atomgraph.linkeddatahub.server.util.MessageBuilder;
import com.atomgraph.linkeddatahub.server.util.Skolemizer;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.linkeddatahub.vocabulary.DH;
import com.atomgraph.linkeddatahub.vocabulary.FOAF;
import com.atomgraph.linkeddatahub.vocabulary.LACL;
import com.atomgraph.linkeddatahub.vocabulary.LDHC;
import com.atomgraph.linkeddatahub.vocabulary.SIOC;
import com.auth0.jwt.JWT;
import com.auth0.jwt.interfaces.DecodedJWT;
import jakarta.json.JsonObject;
import jakarta.mail.MessagingException;
import jakarta.servlet.ServletConfig;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.InternalServerErrorException;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.Cookie;
import jakarta.ws.rs.core.Form;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.URI;
import java.security.NoSuchAlgorithmException;
import java.security.spec.InvalidKeySpecException;
import java.util.Base64;
import java.util.GregorianCalendar;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.regex.Pattern;
import org.apache.jena.query.ParameterizedSparqlString;
import org.apache.jena.query.Query;
import org.apache.jena.query.QuerySolution;
import org.apache.jena.query.ResultSet;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;
import org.glassfish.jersey.server.internal.process.MappableException;
import org.glassfish.jersey.uri.UriComponent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Abstract base class for OAuth 2.0 login endpoints.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public abstract class LoginBase
{
    
    private static final Logger log = LoggerFactory.getLogger(LoginBase.class);

    /** Relative path to the user container */
    public static final String ACCOUNT_PATH = "acl/users/";

    private final UriInfo uriInfo;
    private final HttpHeaders httpHeaders;
    private final com.atomgraph.linkeddatahub.apps.model.Application application;
    private final com.atomgraph.linkeddatahub.Application system;
    private final String emailSubject;
    private final String emailText;
    private final String clientID, clientSecret;

    
    /**
     * Constructs endpoint.
     * 
     * @param request current request
     * @param uriInfo URI information of the current request
     * @param httpHeaders HTTP headers
     * @param application current application
     * @param system system application
     * @param servletConfig servlet config
     * @param clientID OAuth client ID
     * @param clientSecret OAuth client secret;
     */
    public LoginBase(@Context Request request, @Context UriInfo uriInfo, @Context HttpHeaders httpHeaders,
            com.atomgraph.linkeddatahub.apps.model.Application application,
            com.atomgraph.linkeddatahub.Application system, @Context ServletConfig servletConfig,
            String clientID, String clientSecret)
    {
        if (!application.canAs(EndUserApplication.class))
            throw new IllegalStateException("The " + getClass() + " endpoint is only available on end-user applications");
        
        this.uriInfo = uriInfo;
        this.httpHeaders = httpHeaders;
        this.application = application;
        this.system = system;
        this.clientID = clientID;
        this.clientSecret = clientSecret;
        
        emailSubject = servletConfig.getServletContext().getInitParameter(LDHC.signUpEMailSubject.getURI());
        if (emailSubject == null) throw new InternalServerErrorException(new ConfigurationException(LDHC.signUpEMailSubject));

        emailText = servletConfig.getServletContext().getInitParameter(LDHC.oAuthSignUpEMailText.getURI());
        if (emailText == null) throw new InternalServerErrorException(new ConfigurationException(LDHC.oAuthSignUpEMailText));
    }

    /**
     * Handles OAuth2 callback from the authorization server.
     * Exchanges authorization code for access and ID tokens, creates or reuses user agent and account,
     * and redirects back to the original referer with the ID token.
     *
     * @param code authorization code from OAuth provider
     * @param state state parameter for CSRF protection
     * @param error error code if authorization failed
     * @return redirect response to original referer with ID token in URL fragment
     */
    @GET
    public Response get(@QueryParam("code") String code, @QueryParam("state") String state, @QueryParam("error") String error) // TO-DO: verify state by matching against state generated in Authorize
    {
        if (error != null)
        {
            if (log.isErrorEnabled()) log.error("OAuth callback error: {}", error);
            throw new InternalServerErrorException(error);
        }
        if (state == null) throw new BadRequestException("OAuth 'state' parameter not set");
        
        Cookie stateCookie = getHttpHeaders().getCookies().get(AuthorizeBase.COOKIE_NAME);
        if (stateCookie == null) throw new BadRequestException("OAuth '" + AuthorizeBase.COOKIE_NAME + "' cookie not set");
        if (!state.equals(stateCookie.getValue())) throw new BadRequestException("OAuth 'state' parameter failed to validate");
        
        Form form = new Form().
            param("grant_type", "authorization_code").
            param("client_id", getClientID()).
            param("redirect_uri", getUriInfo().getAbsolutePath().toString()).
            param("client_secret", getClientSecret()).
            param("code", code);
                
        try (Response cr = getSystem().getClient().target(getTokenEndpoint()).
                request().post(Entity.form(form)))
        {
            JsonObject response = cr.readEntity(JsonObject.class);
            if (response.containsKey("error"))
            {
                if (log.isErrorEnabled()) log.error("OAuth error: '{}'", response.getString("error"));
                throw new InternalServerErrorException(response.getString("error"));
            }

            String idToken = response.getString("id_token");
            String accessToken = response.getString("access_token");
            DecodedJWT jwt = JWT.decode(idToken);

            // Verify the ID token
            if (!verify(jwt))
            {
                if (log.isErrorEnabled()) log.error("Failed to verify ID token for subject '{}'", jwt.getSubject());
                throw new InternalServerErrorException("ID token verification failed");
            }

            if (response.containsKey("refresh_token"))
            {
                String refreshToken = response.getString("refresh_token");
                try
                {
                    getSystem().storeRefreshToken(jwt.getSubject(), refreshToken); // store for later use in IDTokenFilter
                }
                catch (IOException ex)
                {
                    if (log.isErrorEnabled()) log.error("Error storing OAuth refresh token", ex);
                    throw new InternalServerErrorException(ex);
                }
            }

            if (!userAccountExists(jwt.getSubject(), jwt.getIssuer())) // UserAccount with this ID does not exist yet
            {
                Map<String, String> userInfo = getUserInfo(jwt, accessToken);
                Optional<String> email = Optional.ofNullable(userInfo.get("email"));
                Optional<Resource> mbox = email.map(e -> "mailto:" + e).map(ResourceFactory::createResource);

                Model accountModel = ModelFactory.createDefaultModel();
                URI userAccountGraphUri = getAdminApplication().getUriBuilder().path(ACCOUNT_PATH).path("{slug}/").build(UUID.randomUUID().toString());

                createUserAccount(accountModel,
                    userAccountGraphUri,
                    accountModel.createResource(getAdminApplication().getBaseURI().resolve(ACCOUNT_PATH).toString()),
                    jwt.getSubject(),
                    jwt.getIssuer(),
                    Optional.ofNullable(userInfo.get("name")),
                    email);
                
                new Skolemizer(userAccountGraphUri.toString()).apply(accountModel);
                // lookup UserAccount resource after its URI has been skolemized
                Resource userAccount = accountModel.createResource(userAccountGraphUri.toString()).getPropertyResourceValue(FOAF.primaryTopic);

                Resource agent;
                Optional<QuerySolution> existingAgent = mbox.flatMap(this::findAgentByEmail);

                if (existingAgent.isEmpty())
                {
                    Model agentModel = ModelFactory.createDefaultModel();
                    URI agentGraphUri = getAdminApplication().getUriBuilder().path(AGENT_PATH).path("{slug}/").build(UUID.randomUUID().toString());

                    agent = createAgent(agentModel,
                        agentGraphUri,
                        agentModel.createResource(getAdminApplication().getBaseURI().resolve(AGENT_PATH).toString()),
                        Optional.ofNullable(userInfo.get("name")),
                        Optional.ofNullable(userInfo.get("given_name")),
                        Optional.ofNullable(userInfo.get("family_name")),
                        email,
                        Optional.ofNullable(userInfo.get("picture")));

                    agent.addProperty(FOAF.account, userAccount);
                    agentModel.add(agentModel.createResource(getSystem().getSecretaryWebIDURI().toString()), ACL.delegates, agent); // make secretary delegate whis agent

                    // skolemize here because this Model will not go through SkolemizingModelProvider
                    new Skolemizer(agentGraphUri.toString()).apply(agentModel);
                    // lookup Agent resource after its URI has been skolemized
                    agent = agentModel.createResource(agentGraphUri.toString()).getPropertyResourceValue(FOAF.primaryTopic);

                    getAgentService().getGraphStoreClient().putModel(agentGraphUri.toString(), agentModel);

                    Model authModel = ModelFactory.createDefaultModel();
                    URI authGraphUri = getAdminApplication().getUriBuilder().path(AUTHORIZATION_PATH).path("{slug}/").build(UUID.randomUUID().toString());

                    // creating authorization for the Agent document
                    createAuthorization(authModel,
                        authGraphUri,
                        accountModel.createResource(getAdminApplication().getBaseURI().resolve(AUTHORIZATION_PATH).toString()),
                        agentGraphUri,
                        userAccountGraphUri);
                    new Skolemizer(authGraphUri.toString()).apply(authModel);

                    getAgentService().getGraphStoreClient().putModel(authGraphUri.toString(), authModel);

                    try
                    {
                        // purge agent lookup from proxy cache
                        if (getApplication().getService().getBackendProxy() != null) ban(getAdminApplication().getService().getBackendProxy(), jwt.getSubject());

                        // remove secretary WebID from cache
                        getSystem().getEventBus().post(new com.atomgraph.linkeddatahub.server.event.SignUp(getSystem().getSecretaryWebIDURI()));

                        if (log.isDebugEnabled()) log.debug("Created Agent for user ID: {}", jwt.getSubject());
                        if (agent.hasProperty(FOAF.mbox)) sendEmail(agent);
                    }
                    catch (UnsupportedEncodingException | MessagingException | InternalServerErrorException ex)
                    {
                        throw new MappableException(ex);
                    }
                }
                else
                {
                    QuerySolution qs = existingAgent.get();
                    Resource agentGraph = qs.getResource("agentGraph");

                    Model agentModel = ModelFactory.createDefaultModel();
                    agent = qs.getResource(FOAF.Agent.getLocalName()).inModel(agentModel);
                    agent.addProperty(FOAF.account, userAccount);
                    agentModel.add(agentModel.createResource(getSystem().getSecretaryWebIDURI().toString()), ACL.delegates, agent); // make secretary delegate whis agent

                    getAgentService().getGraphStoreClient().add(agentGraph.getURI(), agentModel);
                }
                
                userAccount.addProperty(SIOC.ACCOUNT_OF, agent);
                getAgentService().getGraphStoreClient().putModel(userAccountGraphUri.toString(), accountModel);
            }
            
            URI originalReferer = URI.create(new String(Base64.getDecoder().decode(stateCookie.getValue())).split(Pattern.quote(";"))[1]); // fails if referer param was not specified

            // Pass ID token in URL fragment for client-side cookie setting (works uniformly across all domains)
            URI redirectUri = URI.create(originalReferer + "#id_token=" + idToken);
            return Response.seeOther(redirectUri).build();
        }
    }

    /**
     * Checks if a UserAccount with the given subject ID and issuer already exists.
     *
     * @param subjectId the OAuth subject ID (e.g., ORCID iD or Google user ID)
     * @param issuer the OAuth issuer URI
     * @return true if UserAccount exists, false otherwise
     */
    protected boolean userAccountExists(String subjectId, String issuer)
    {
        ParameterizedSparqlString pss = new ParameterizedSparqlString(getUserAccountQuery().toString());
        pss.setLiteral(SIOC.ID.getLocalName(), subjectId);
        pss.setLiteral(LACL.issuer.getLocalName(), issuer);

        return !getAgentService().getSPARQLClient().loadModel(pss.asQuery()).isEmpty();
    }

    /**
     * Finds an existing agent by email address.
     * Queries the agent store for an agent with the specified foaf:mbox property.
     *
     * @param mbox the email address as a mailto: URI resource
     * @return Optional containing the QuerySolution with ?Agent and ?agentGraph bindings if found, empty otherwise
     */
    protected Optional<QuerySolution> findAgentByEmail(Resource mbox)
    {
        if (mbox == null) return Optional.empty();

        ParameterizedSparqlString pss = new ParameterizedSparqlString(getAgentQuery().toString());
        pss.setParam(FOAF.mbox.getLocalName(), mbox);

        ResultSet rs = getAgentService().getSPARQLClient().select(pss.asQuery());
        try
        {
            if (!rs.hasNext()) return Optional.empty();
            return Optional.of(rs.next());
        }
        finally
        {
            rs.close();
        }
    }

    /**
     * Verifies the decoded JWT ID token using JWKS-based signature verification.
     * Performs the following validations:
     * 1. Fetches public keys from the JWKS endpoint
     * 2. Verifies the JWT signature using RSA256 algorithm
     * 3. Validates the issuer is in the allowed list
     * 4. Validates the audience matches the client ID
     * 5. Validates the token has not expired
     *
     * @param jwt decoded JWT ID token to verify
     * @return true if verification succeeds, false otherwise
     */
    protected boolean verify(DecodedJWT jwt)
    {
        try
        {
            // Fetch JWKS from the provider
            try (Response jwksResponse = getSystem().getClient().target(getJwksEndpoint()).request().get())
            {
                if (!jwksResponse.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
                {
                    if (log.isErrorEnabled()) log.error("Failed to fetch JWKS from {}", getJwksEndpoint());
                    return false;
                }

                JsonObject jwks = jwksResponse.readEntity(JsonObject.class);

                // Find the key that matches the JWT's key ID
                String kid = jwt.getKeyId();
                if (kid == null)
                {
                    if (log.isErrorEnabled()) log.error("JWT does not contain 'kid' (key ID) header");
                    return false;
                }

                jakarta.json.JsonArray keys = jwks.getJsonArray("keys");
                if (keys == null)
                {
                    if (log.isErrorEnabled()) log.error("JWKS does not contain 'keys' array");
                    return false;
                }

                // Find matching key
                JsonObject matchingKey = null;
                for (int i = 0; i < keys.size(); i++)
                {
                    JsonObject key = keys.getJsonObject(i);
                    if (kid.equals(key.getString("kid", null)))
                    {
                        matchingKey = key;
                        break;
                    }
                }

                if (matchingKey == null)
                {
                    if (log.isErrorEnabled()) log.error("No matching key found in JWKS for kid: {}", kid);
                    return false;
                }

                // Extract RSA public key components
                String n = matchingKey.getString("n"); // modulus
                String e = matchingKey.getString("e"); // exponent

                // Create RSA public key
                java.math.BigInteger modulus = new java.math.BigInteger(1, java.util.Base64.getUrlDecoder().decode(n));
                java.math.BigInteger exponent = new java.math.BigInteger(1, java.util.Base64.getUrlDecoder().decode(e));

                java.security.spec.RSAPublicKeySpec spec = new java.security.spec.RSAPublicKeySpec(modulus, exponent);
                java.security.KeyFactory factory = java.security.KeyFactory.getInstance("RSA");
                java.security.interfaces.RSAPublicKey publicKey = (java.security.interfaces.RSAPublicKey) factory.generatePublic(spec);

                // Verify issuer manually (auth0 JWT library doesn't support multiple issuers easily)
                if (!getIssuers().contains(jwt.getIssuer()))
                {
                    if (log.isErrorEnabled()) log.error("JWT issuer '{}' not in allowed list: {}", jwt.getIssuer(), getIssuers());
                    return false;
                }

                // Create algorithm and verifier
                com.auth0.jwt.algorithms.Algorithm algorithm = com.auth0.jwt.algorithms.Algorithm.RSA256(publicKey, null);
                com.auth0.jwt.JWTVerifier verifier = JWT.require(algorithm)
                    .withIssuer(jwt.getIssuer())
                    .withAudience(getClientID())
                    .build();

                // Verify the token (this will throw if verification fails)
                verifier.verify(jwt.getToken());

                if (log.isDebugEnabled()) log.debug("Successfully verified JWT for subject '{}'", jwt.getSubject());
                return true;
            }
        }
        catch (com.auth0.jwt.exceptions.JWTVerificationException ex)
        {
            if (log.isErrorEnabled()) log.error("JWT verification failed: {}", ex.getMessage());
            return false;
        }
        catch (IllegalArgumentException | NoSuchAlgorithmException | InvalidKeySpecException ex)
        {
            if (log.isErrorEnabled()) log.error("Error during JWT verification", ex);
            return false;
        }
    }
    
    /**
     * Creates new agent resource.
     * 
     * @param model RDF model
     * @param graphURI graph URI
     * @param container container resource
     * @param name name
     * @param givenName given name
     * @param familyName family name
     * @param email email address
     * @param imgUrl image URL
     * @return agent resource
     */
    public Resource createAgent(Model model, URI graphURI, Resource container, Optional<String> name, Optional<String> givenName, Optional<String> familyName, Optional<String> email, Optional<String> imgUrl)
    {
        Resource item =  model.createResource(graphURI.toString()).
            addProperty(RDF.type, DH.Item).
            addProperty(SIOC.HAS_CONTAINER, container).
            addLiteral(DH.slug, UUID.randomUUID().toString());
        
        Resource agent = model.createResource().
            addProperty(RDF.type, FOAF.Agent);

        if (name.isPresent()) agent.addLiteral(FOAF.name, name.get());
        if (givenName.isPresent()) agent.addLiteral(FOAF.givenName, givenName.get());
        if (familyName.isPresent()) agent.addLiteral(FOAF.familyName, familyName.get());
        if (email.isPresent()) agent.addProperty(FOAF.mbox, model.createResource("mailto:" + email.get()));
        if (imgUrl.isPresent()) agent.addProperty(FOAF.img, model.createResource(imgUrl.get()));
            
        item.addProperty(FOAF.primaryTopic, agent);
        
        return agent;
    }
    
    /**
     * Creates new user account resource.
     *
     * @param model RDF model
     * @param graphURI graph URI
     * @param container container resource
     * @param id user ID
     * @param issuer OIDC issuer
     * @param name optional username
     * @param email optional email address
     * @return user account resource
     */
    public Resource createUserAccount(Model model, URI graphURI, Resource container, String id, String issuer, Optional<String> name, Optional<String> email)
    {
        Resource item = model.createResource(graphURI.toString()).
            addProperty(RDF.type, DH.Item).
            addProperty(SIOC.HAS_CONTAINER, container).
            addLiteral(DH.slug, UUID.randomUUID().toString());

        Resource account = model.createResource().
            addLiteral(DCTerms.created, GregorianCalendar.getInstance()).
            addProperty(RDF.type, SIOC.USER_ACCOUNT).
            addLiteral(SIOC.ID, id).
            addLiteral(LACL.issuer, issuer);

        if (name.isPresent()) account.addLiteral(SIOC.NAME, name.get());
        if (email.isPresent()) account.addProperty(SIOC.EMAIL, model.createResource("mailto:" + email.get()));

        item.addProperty(FOAF.primaryTopic, account);

        return account;
    }

    /**
     * Creates new authorization resource.
     * 
     * @param model RDF model
     * @param graphURI graph URI
     * @param container container resource
     * @param agentGraphURI agent's graph URI
     * @param userAccountGraphURI user account's graph URI
     * @return authorization resource
     */
    public Resource createAuthorization(Model model, URI graphURI, Resource container, URI agentGraphURI, URI userAccountGraphURI)
    {
        Resource item = model.createResource(graphURI.toString()).
            addProperty(RDF.type, DH.Item).
            addProperty(SIOC.HAS_CONTAINER, container).
            addLiteral(DH.slug, UUID.randomUUID().toString());
        
        Resource auth = model.createResource().
            addProperty(RDF.type, ACL.Authorization).
            addLiteral(DH.slug, UUID.randomUUID().toString()). // TO-DO: get rid of slug properties!
            addProperty(ACL.accessTo, ResourceFactory.createResource(agentGraphURI.toString())).
            addProperty(ACL.mode, ACL.Read).
            addProperty(ACL.agentClass, FOAF.Agent).
            addProperty(ACL.agentClass, ACL.AuthenticatedAgent);
        
        item.addProperty(FOAF.primaryTopic, auth);
        
        return auth;
    }
    
    /**
     * Sends signup notification email message to agent.
     * 
     * @param agent agent resource
     * @throws MessagingException thrown if message sending failed
     * @throws UnsupportedEncodingException encoding error
     */
    public void sendEmail(Resource agent) throws MessagingException, UnsupportedEncodingException
    {
        final String fullName;
        if (agent.hasProperty(FOAF.givenName) && agent.hasProperty(FOAF.familyName))
        {
            String givenName = agent.getRequiredProperty(FOAF.givenName).getString();
            String familyName = agent.getRequiredProperty(FOAF.familyName).getString();
            fullName = givenName + " " + familyName;
        }
        else
            fullName = agent.getProperty(FOAF.name).getString();
                    
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

    /** 
     * Bans URL from the backend proxy cache.
     * 
     * @param proxy proxy server URL
     * @param url banned URL
     * @return proxy server response
     */
    public Response ban(Resource proxy, String url)
    {
        if (url == null) throw new IllegalArgumentException("Resource cannot be null");
        
        return getSystem().getClient().target(proxy.getURI()).request().
            header(CacheInvalidationFilter.HEADER_NAME, UriComponent.encode(url, UriComponent.Type.UNRESERVED)). // the value has to be URL-encoded in order to match request URLs in Varnish
            method("BAN", Response.class);
    }
    
    /**
     * Retrieves additional user information from the OAuth provider.
     * Some providers (like Google) include all user data in the ID token JWT claims.
     * Others (like ORCID) require a separate UserInfo endpoint call.
     *
     * @param jwt the decoded JWT ID token
     * @param accessToken the OAuth access token
     * @return map of user information claims (email, name, given_name, family_name, picture, etc.)
     */
    protected abstract Map<String, String> getUserInfo(DecodedJWT jwt, String accessToken);

    /**
     * Returns the JWKS (JSON Web Key Set) endpoint URL for retrieving public keys to verify JWT signatures.
     *
     * @return JWKS endpoint URI
     */
    protected abstract URI getJwksEndpoint();

    /**
     * Returns the list of valid JWT issuers for this OAuth provider.
     *
     * @return list of valid issuer URLs
     */
    protected abstract java.util.List<String> getIssuers();

    /**
     * Returns the OAuth token endpoint URL for this provider.
     *
     * @return token endpoint URI
     */
    public abstract URI getTokenEndpoint();

    /**
     * Returns the end-user application of the current dataspace.
     * 
     * @return end-user application resource
     */
    public EndUserApplication getEndUserApplication()
    {
        if (getApplication().canAs(EndUserApplication.class))
            return getApplication().as(EndUserApplication.class);
        else
            return getApplication().as(AdminApplication.class).getEndUserApplication();
    }
    
    /**
     * Returns the admin application of the current dataspace.
     * 
     * @return admin application resource
     */
    public AdminApplication getAdminApplication()
    {
        if (getApplication().canAs(AdminApplication.class))
            return getApplication().as(AdminApplication.class);
        else
            return getApplication().as(EndUserApplication.class).getAdminApplication();
    }
    
    public UriInfo getUriInfo()
    {
        return uriInfo;
    }
    
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }
    
    public Application getApplication()
    {
        return application;
    }
    
    /**
     * Returns HTTP headers of the current request.
     * 
     * @return header info
     */
    public HttpHeaders getHttpHeaders()
    {
        return httpHeaders;
    }
    
    /**
     * Returns the SPARQL service from which agent data is retrieved.
     * 
     * @return SPARQL service
     */
    public Service getAgentService()
    {
        return getApplication().as(EndUserApplication.class).getAdminApplication().getService();
    }
    
    /**
     * Returns login email subject.
     * 
     * @return email subject
     */
    public String getEmailSubject()
    {
        return emailSubject;
    }
    
    /**
     * Returns login email text.
     * 
     * @return email text
     */
    public String getEmailText()
    {
        return emailText;
    }

    /**
     * Returns SPARQL query used to load user account by ID.
     * 
     * @return SPARQL query
     */
    public Query getUserAccountQuery()
    {
        return getSystem().getUserAccountQuery();
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
    
    /**
     * Returns the configured Google client ID for this application.
     * 
     * @return client ID
     */
    protected String getClientID()
    {
        return clientID;
    }
    
    /**
     * Returns the configured Google client secret for this application.
     * 
     * @return client secret
     */
    protected String getClientSecret()
    {
        return clientSecret;
    }
    
}
