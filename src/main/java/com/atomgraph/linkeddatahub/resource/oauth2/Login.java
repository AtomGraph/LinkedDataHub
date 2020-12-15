package com.atomgraph.linkeddatahub.resource.oauth2;

import com.atomgraph.client.util.DataManager;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.apps.model.AdminApplication;
import com.atomgraph.linkeddatahub.model.Agent;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.model.UserAccount;
import com.atomgraph.linkeddatahub.server.filter.request.auth.JWTFilter;
import com.atomgraph.linkeddatahub.server.filter.request.auth.UserAccountContext;
import com.atomgraph.linkeddatahub.server.model.ClientUriInfo;
import com.atomgraph.linkeddatahub.server.model.impl.ClientUriInfoImpl;
import com.atomgraph.linkeddatahub.server.model.impl.ResourceBase;
import com.atomgraph.linkeddatahub.vocabulary.APLT;
import com.atomgraph.linkeddatahub.vocabulary.FOAF;
import com.atomgraph.linkeddatahub.vocabulary.LACL;
import com.atomgraph.processor.model.TemplateCall;
import com.atomgraph.processor.util.Skolemizer;
import com.atomgraph.processor.vocabulary.DH;
import com.atomgraph.processor.vocabulary.SIOC;
import com.auth0.jwt.JWT;
import com.auth0.jwt.interfaces.DecodedJWT;
import java.net.URI;
import java.util.GregorianCalendar;
import java.util.Optional;
import java.util.UUID;
import javax.inject.Inject;
import javax.json.JsonObject;
import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.GET;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.client.Entity;
import javax.ws.rs.container.ResourceContext;
import javax.ws.rs.core.Context;
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
    
    @Inject
    public Login(@Context UriInfo uriInfo, ClientUriInfo clientUriInfo, @Context Request request, MediaTypes mediaTypes,
            Service service, com.atomgraph.linkeddatahub.apps.model.Application application,
            Ontology ontology, Optional<TemplateCall> templateCall,
            @Context HttpHeaders httpHeaders, @Context ResourceContext resourceContext,
            @Context HttpServletRequest httpServletRequest, @Context SecurityContext securityContext,
            DataManager dataManager, @Context Providers providers,
            com.atomgraph.linkeddatahub.Application system)
    {
        super(uriInfo, clientUriInfo, request, mediaTypes,
            uriInfo.getAbsolutePath(),
            service, application,
            ontology, templateCall,
            httpHeaders, resourceContext,
            httpServletRequest, securityContext,
            dataManager, providers,
            system);
    }
    
    @GET
    @Override
    public Response get()
    {
        String error = getUriInfo().getQueryParameters().getFirst("error");
        
        if (error != null)
        {
            if (log.isErrorEnabled()) log.error("OAuth callback error: {}", error);
            throw new WebApplicationException(error);
        }

        String code = getUriInfo().getQueryParameters().getFirst("code");
        String state = getUriInfo().getQueryParameters().getFirst("state");

        Form form = new Form().
            param("grant_type", "authorization_code").
            param("client_id", "94623832214-l46itt9or8ov4oejndd15b2gv266aqml.apps.googleusercontent.com").
            param("redirect_uri", getUriInfo().getAbsolutePath().toString()).
            param("client_secret", "ht4oxEyihCcSrcZCtseJ4dQ8").
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
            String userId = jwt.getSubject();

            ParameterizedSparqlString askQuery = new ParameterizedSparqlString("ASK { GRAPH ?g { ?account <http://rdfs.org/sioc/ns#id> ?id } }");
            askQuery.setLiteral(SIOC.ID.getLocalName(), userId);
            boolean accountExists = getApplication().getService().getSPARQLClient().ask(askQuery.asQuery());

            if (!accountExists) // UserAccount with this ID does not exist yet
            {
                Model model = ModelFactory.createDefaultModel();
                InfModel infModel = ModelFactory.createRDFSModel(getOntology().getOntModel(), model);
                String email = jwt.getClaim("email").asString();
                Resource agent = createAgent(model, getOntology().getURI(), model.createResource(getUriInfo().getBaseUri().resolve("acl/agents/").toString()), jwt.getClaim("given_name").asString(), jwt.getClaim("family_name").asString(), email);
                Resource userAccount = createUserAccount(model, getOntology().getURI(), model.createResource(getUriInfo().getBaseUri().resolve("acl/users/").toString()), userId, jwt.getClaim("name").asString(), email);
                userAccount.addProperty(SIOC.ACCOUNT_OF, agent);
                agent.addProperty(FOAF.account, userAccount);
                
                // skolemize here because this Model will not go through SkolemizingModelProvider
                new Skolemizer(getOntology(), getUriInfo().getBaseUriBuilder(), getUriInfo().getBaseUriBuilder().path("acl/users/")).build(model);

//                Resource forClass = getTemplateCall().get().getArgumentProperty(APLT.forClass).getResource();
                ResIterator it = model.listResourcesWithProperty(RDF.type, model.createResource(getOntology().getURI() + LACL.Agent.getLocalName()));
                try
                {
                    // we need to retrieve resources again because they've changed from bnodes to URIs
                    agent = it.next();
                    userAccount = agent.getPropertyResourceValue(FOAF.account);
                    
                    SecurityContext securityContext = new UserAccountContext("JWT", agent.inModel(infModel).as(Agent.class), userAccount.inModel(infModel).as(UserAccount.class));
                    Dataset dataset = DatasetFactory.create(model);
                    Response resp = createContainer(getUriInfo().getBaseUri().resolve("acl/users/"), LACL.UserAccount, securityContext).
                        post(dataset);

                    if (resp.getStatus() != Status.OK.getStatusCode())
                    {
                        if (log.isErrorEnabled()) log.error("Could not create UserAccount for user ID: {}", userId);
                        throw new WebApplicationException();
                    }

                    if (log.isDebugEnabled()) log.debug("Created UserAccount for user ID: {}", userId);
                }
                finally
                {
                    it.close();
                }
            }
            
            NewCookie jwtCookie = new NewCookie(JWTFilter.COOKIE_NAME, idToken,
                getUriInfo().getBaseUri().getPath(), null, // getUriInfo().getBase().getHost()
                NewCookie.DEFAULT_VERSION, null, NewCookie.DEFAULT_MAX_AGE, false);
            
            return Response.seeOther(getApplication().as(AdminApplication.class).getEndUserApplication().getBaseURI()). // redirect to end-user root
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
    
    public Resource createAgent(Model model, String namespace, Resource container, String givenName, String familyName, String email)
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
            addLiteral(model.createProperty(FOAF.NS + "givenName"), givenName).
            addLiteral(model.createProperty(FOAF.NS + "familyName"), familyName).
            addProperty(FOAF.mbox, model.createResource("mailto:" + email)).
            addProperty(FOAF.isPrimaryTopicOf, agentDoc);
        agentDoc.addProperty(FOAF.primaryTopic, agent);
        
        return agent;
    }
    
    public Resource createUserAccount(Model model, String namespace, Resource container, String id, String name, String email)
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
            addLiteral(SIOC.NAME, name).
            addProperty(SIOC.EMAIL, model.createResource("mailto:" + email)).
            addProperty(FOAF.isPrimaryTopicOf, accountDoc);
        accountDoc.addProperty(FOAF.primaryTopic, account);

        return account;
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
            getService(), getApplication(), getOntology(), getTemplateCall(), getHttpHeaders(), getResourceContext(),
            getHttpServletRequest(), securityContext, getDataManager(), getProviders(),
            getSystem());
    }
    
    public Query getAuthQuery()
    {
        return null;
    }

}
