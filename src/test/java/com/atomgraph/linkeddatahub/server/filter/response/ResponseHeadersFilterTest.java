/**
 *  Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.server.filter.response;

import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.client.vocabulary.LDT;
import com.atomgraph.core.vocabulary.SD;
import com.atomgraph.linkeddatahub.model.auth.Agent;
import com.atomgraph.linkeddatahub.server.model.impl.DocumentHierarchyGraphStoreImpl;
import com.atomgraph.linkeddatahub.server.security.AuthorizationContext;
import com.atomgraph.linkeddatahub.server.util.GraphVersioningService;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.linkeddatahub.vocabulary.LAPP;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerResponseContext;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.MultivaluedHashMap;
import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.SecurityContext;
import jakarta.ws.rs.core.UriBuilder;
import jakarta.ws.rs.core.UriInfo;
import java.io.IOException;
import java.net.URI;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.Set;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.apache.jena.rdf.model.Resource;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Tests the hypermedia and language headers the filter attaches to a response.
 *
 * Two things here are load-bearing beyond the header values themselves. Local hypermedia is suppressed for proxy requests,
 * because a proxied response describes a remote application and its links are forwarded by {@code ProxyRequestFilter}
 * instead. And a snapshot request advertises at most {@code acl:Read}, which is what stops the UI offering edit affordances
 * on immutable historical content.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
public class ResponseHeadersFilterTest
{

    private static final URI BASE_URI = URI.create("https://localhost:4443/");
    private static final URI DOCUMENT_URI = URI.create("https://localhost:4443/people/");
    private static final String APP_URI = "urn:linkeddatahub:apps/end-user";
    private static final List<Locale> BUNDLE = List.of(Locale.forLanguageTag("en-US"), Locale.forLanguageTag("es-ES"));

    @Mock private ContainerRequestContext request;
    @Mock private ContainerResponseContext response;
    @Mock private UriInfo uriInfo;
    @Mock private SecurityContext securityContext;
    @Mock private com.atomgraph.linkeddatahub.Application system;
    @Mock private com.atomgraph.linkeddatahub.apps.model.Application application;
    @Mock private GraphVersioningService versioningService;
    @Mock private AuthorizationContext authorizationContext;

    private ResponseHeadersFilter filter;
    private MultivaluedMap<String, Object> headers;
    private MultivaluedMap<String, String> queryParameters;

    @BeforeEach
    public void setUp()
    {
        filter = new ResponseHeadersFilter();
        filter.system = system;
        filter.app = () -> Optional.of(application);
        filter.dataset = () -> Optional.empty();
        filter.authorizationContext = () -> Optional.<AuthorizationContext>empty();

        headers = new MultivaluedHashMap<>();
        queryParameters = new MultivaluedHashMap<>();

        // an ordinary HTML document response by an anonymous reader; individual tests vary one condition
        when(response.getStatusInfo()).thenReturn(Response.Status.OK);
        when(response.hasEntity()).thenReturn(true);
        when(response.getMediaType()).thenReturn(MediaType.TEXT_HTML_TYPE);
        when(response.getHeaders()).thenReturn(headers);
        when(request.getUriInfo()).thenReturn(uriInfo);
        when(request.getSecurityContext()).thenReturn(securityContext);
        when(request.getProperty(AC.uri.getURI())).thenReturn(null);
        when(request.getAcceptableLanguages()).thenReturn(List.of(Locale.forLanguageTag("en")));
        when(uriInfo.getQueryParameters()).thenReturn(queryParameters);
        when(uriInfo.getBaseUriBuilder()).thenReturn(UriBuilder.fromUri(BASE_URI));
        when(uriInfo.getAbsolutePath()).thenReturn(DOCUMENT_URI);
        when(uriInfo.getMatchedResources()).thenReturn(List.of());
        when(securityContext.getUserPrincipal()).thenReturn(null);
        when(system.getSupportedLanguages()).thenReturn(BUNDLE);
        when(application.getURI()).thenReturn(APP_URI);
        when(application.getOntology()).thenReturn(null);
        when(application.getStylesheet()).thenReturn(null);
        // the Memento block runs for any application-bearing response; no repository means no version hypermedia
        when(system.getGraphVersioningService()).thenReturn(versioningService);
        when(versioningService.getRepository(anyString())).thenReturn(Optional.empty());
    }

    /** The folded Link header, or the empty string when the response carries none. */
    private String link()
    {
        Object value = headers.getFirst(HttpHeaders.LINK);

        return value != null ? value.toString() : "";
    }

    private String contentLanguage()
    {
        Object value = headers.getFirst(HttpHeaders.CONTENT_LANGUAGE);

        return value != null ? value.toString() : null;
    }

    /** Puts the request on a versioned document, which is what the Memento block requires. */
    private void versioned()
    {
        when(versioningService.getRepository(APP_URI)).thenReturn(Optional.of(new GraphVersioningService.Repository(null, "graphs")));
        when(uriInfo.getMatchedResources()).thenReturn(List.of(mock(DocumentHierarchyGraphStoreImpl.class)));
    }

    private void authorized(Resource... modes)
    {
        Set<URI> modeURIs = Set.of(modes).stream().map(mode -> URI.create(mode.getURI())).collect(java.util.stream.Collectors.toSet());

        when(authorizationContext.getModeURIs()).thenReturn(modeURIs);
        filter.authorizationContext = () -> Optional.of(authorizationContext);
    }

    // LANGUAGE

    /** The reader's preference is not the answer: it is the first accepted language the UI bundle actually has. */
    @Test
    public void testLabelsHtmlWithTheNegotiatedLanguage() throws IOException
    {
        when(request.getAcceptableLanguages()).thenReturn(List.of(Locale.forLanguageTag("lt"), Locale.forLanguageTag("en")));

        filter.filter(request, response);

        // the bundle has no Lithuanian, so the page is composed in the next language it does have. The published
        // tag drops the bundle key's region, which distinguishes nothing while the bundle holds one English
        assertEquals("en", contentLanguage());
    }

    @Test
    public void testLabelsSpanishReaderWithSpanish() throws IOException
    {
        when(request.getAcceptableLanguages()).thenReturn(List.of(Locale.forLanguageTag("es")));

        filter.filter(request, response);

        assertEquals("es", contentLanguage());
    }

    /** A reader whose languages the bundle has none of still gets an honest label, not their own request echoed back. */
    @Test
    public void testFallsBackRatherThanEchoingTheRequest() throws IOException
    {
        when(request.getAcceptableLanguages()).thenReturn(List.of(Locale.forLanguageTag("de"), Locale.forLanguageTag("fr")));

        filter.filter(request, response);

        assertEquals("en", contentLanguage());
    }

    /** Both HTML flavours are language-significant, so whichever is negotiated carries the label. */
    @Test
    public void testLabelsXhtml() throws IOException
    {
        when(response.getMediaType()).thenReturn(MediaType.APPLICATION_XHTML_XML_TYPE);

        filter.filter(request, response);

        assertEquals("en", contentLanguage());
    }

    /**
     * An RDF representation is byte-identical for every reader - its literals carry their own tags and none is dropped - so
     * it is intended for all language audiences, which RFC 9110 spells as no Content-Language at all. Labelling it would also
     * contradict its Vary, which carries no Accept-Language dimension.
     */
    @Test
    public void testDoesNotLabelRDF() throws IOException
    {
        when(response.getMediaType()).thenReturn(MediaType.valueOf("application/rdf+xml"));

        filter.filter(request, response);

        assertFalse(headers.containsKey(HttpHeaders.CONTENT_LANGUAGE));
    }

    @Test
    public void testDoesNotLabelTurtle() throws IOException
    {
        when(response.getMediaType()).thenReturn(MediaType.valueOf("text/turtle"));

        filter.filter(request, response);

        assertFalse(headers.containsKey(HttpHeaders.CONTENT_LANGUAGE));
    }

    /** Nothing was rendered, so there is no representation to describe. */
    @Test
    public void testDoesNotLabelEntitylessResponse() throws IOException
    {
        when(response.hasEntity()).thenReturn(false);

        filter.filter(request, response);

        assertFalse(headers.containsKey(HttpHeaders.CONTENT_LANGUAGE));
    }

    /** Without an application there is no bundle to negotiate against. */
    @Test
    public void testDoesNotLabelWithoutApplication() throws IOException
    {
        filter.app = () -> Optional.empty();

        filter.filter(request, response);

        assertFalse(headers.containsKey(HttpHeaders.CONTENT_LANGUAGE));
    }

    /**
     * A browser asking a proxy request for HTML is served the local shell, which is rendered through the local translation
     * bundle - so it is composed in a language and says which, even though its hypermedia describes a remote application.
     */
    @Test
    public void testLabelsProxiedHTML() throws IOException
    {
        when(request.getProperty(AC.uri.getURI())).thenReturn("https://remote.example/resource");

        filter.filter(request, response);

        assertEquals("en", contentLanguage());
    }

    // CONTENT TYPE

    /** A 204 carries no representation, so the media type it would otherwise inherit has to be unset explicitly. */
    @Test
    public void testRemovesContentTypeFromNoContent() throws IOException
    {
        headers.putSingle(HttpHeaders.CONTENT_TYPE, MediaType.TEXT_HTML);
        when(response.getStatusInfo()).thenReturn(Response.Status.NO_CONTENT);
        when(response.hasEntity()).thenReturn(false);

        filter.filter(request, response);

        assertFalse(headers.containsKey(HttpHeaders.CONTENT_TYPE));
    }

    // AGENT

    @Test
    public void testAdvertisesAuthenticatedAgent() throws IOException
    {
        Agent agent = mock(Agent.class);
        when(agent.getURI()).thenReturn("https://admin.localhost:4443/acl/agents/1/#this");
        when(securityContext.getUserPrincipal()).thenReturn(agent);

        filter.filter(request, response);

        assertTrue(link().contains("<https://admin.localhost:4443/acl/agents/1/#this>; rel=" + ACL.agent.getURI()));
    }

    @Test
    public void testDoesNotAdvertiseAgentWhenAnonymous() throws IOException
    {
        filter.filter(request, response);

        assertFalse(link().contains(ACL.agent.getURI()));
    }

    // ACCESS MODES

    @Test
    public void testAdvertisesEveryAuthorizedMode() throws IOException
    {
        authorized(ACL.Read, ACL.Write);

        filter.filter(request, response);

        assertTrue(link().contains("<" + ACL.Read.getURI() + ">; rel=" + ACL.mode.getURI()));
        assertTrue(link().contains("<" + ACL.Write.getURI() + ">; rel=" + ACL.mode.getURI()));
    }

    /**
     * A historical version is immutable, so the response must advertise at most acl:Read however much access the agent has
     * on the document today. This is what disables the edit affordances on a snapshot.
     */
    @Test
    public void testSnapshotAdvertisesReadOnly() throws IOException
    {
        authorized(ACL.Read, ACL.Write);
        queryParameters.putSingle(DocumentHierarchyGraphStoreImpl.VERSION_PARAM_NAME, "abc123");

        filter.filter(request, response);

        assertTrue(link().contains("<" + ACL.Read.getURI() + ">; rel=" + ACL.mode.getURI()));
        assertFalse(link().contains(ACL.Write.getURI()));
    }

    @Test
    public void testTimeMapAdvertisesReadOnly() throws IOException
    {
        authorized(ACL.Read, ACL.Write);
        queryParameters.putSingle(DocumentHierarchyGraphStoreImpl.TIMEMAP_PARAM_NAME, "");

        filter.filter(request, response);

        assertFalse(link().contains(ACL.Write.getURI()));
    }

    // LOCAL HYPERMEDIA

    @Test
    public void testAdvertisesEndpointAndApplication() throws IOException
    {
        filter.filter(request, response);

        assertTrue(link().contains("<" + BASE_URI + "sparql>; rel=" + SD.endpoint.getURI()));
        assertTrue(link().contains("<" + APP_URI + ">; rel=" + LAPP.application.getURI()));
    }

    @Test
    public void testAdvertisesOntologyAndStylesheetWhenDeclared() throws IOException
    {
        Resource ontology = mock(Resource.class);
        Resource stylesheet = mock(Resource.class);
        when(ontology.getURI()).thenReturn("https://localhost:4443/ns#");
        when(stylesheet.getURI()).thenReturn("https://localhost:4443/static/xsl/layout.xsl");
        when(application.getOntology()).thenReturn(ontology);
        when(application.getStylesheet()).thenReturn(stylesheet);

        filter.filter(request, response);

        assertTrue(link().contains("<https://localhost:4443/ns#>; rel=" + LDT.ontology.getURI()));
        assertTrue(link().contains("<https://localhost:4443/static/xsl/layout.xsl>; rel=" + AC.stylesheet.getURI()));
    }

    @Test
    public void testOmitsOntologyAndStylesheetWhenUndeclared() throws IOException
    {
        filter.filter(request, response);

        assertFalse(link().contains(LDT.ontology.getURI()));
        assertFalse(link().contains(AC.stylesheet.getURI()));
    }

    /**
     * A proxy response describes a remote application, and ProxyRequestFilter forwards that application's own Link headers.
     * Emitting the local ones as well would attribute this instance's endpoint, ontology and stylesheet to someone else's
     * resource.
     */
    @Test
    public void testProxyRequestSuppressesLocalHypermedia() throws IOException
    {
        when(request.getProperty(AC.uri.getURI())).thenReturn("https://remote.example/resource");

        filter.filter(request, response);

        assertFalse(link().contains(SD.endpoint.getURI()));
        assertFalse(link().contains(LAPP.application.getURI()));
        assertFalse(link().contains(LDT.ontology.getURI()));
        assertFalse(link().contains(AC.stylesheet.getURI()));
    }

    /** The agent is a property of the request, not of the application, so it survives a proxy request. */
    @Test
    public void testProxyRequestStillAdvertisesAgent() throws IOException
    {
        Agent agent = mock(Agent.class);
        when(agent.getURI()).thenReturn("https://admin.localhost:4443/acl/agents/1/#this");
        when(securityContext.getUserPrincipal()).thenReturn(agent);
        when(request.getProperty(AC.uri.getURI())).thenReturn("https://remote.example/resource");

        filter.filter(request, response);

        assertTrue(link().contains(ACL.agent.getURI()));
    }

    // MEMENTO (RFC 7089)

    /** An unversioned application has no TimeMap to point at. */
    @Test
    public void testUnversionedDocumentHasNoMementoLinks() throws IOException
    {
        filter.filter(request, response);

        assertFalse(link().contains("rel=timemap"));
        assertFalse(link().contains("rel=timegate"));
        assertFalse(link().contains("rel=original"));
    }

    /**
     * The Original Resource points at its TimeMap and names a preferred TimeGate. It must not carry rel=original: that
     * relation identifies the original from something that is not it.
     */
    @Test
    public void testOriginalResourceLinksToTimeMapAndTimeGate() throws IOException
    {
        versioned();

        filter.filter(request, response);

        assertTrue(link().contains("<" + DOCUMENT_URI + "?timemap>; rel=timemap; type=\"application/link-format\""));
        assertTrue(link().contains("<" + DOCUMENT_URI + "?timegate>; rel=timegate"));
        assertFalse(link().contains("rel=original"));
        assertFalse(link().contains("rel=self"));
    }

    /** The TimeMap is the one resource that identifies itself, so it uses rel=self where everything else uses rel=timemap. */
    @Test
    public void testTimeMapIdentifiesItselfWithSelf() throws IOException
    {
        versioned();
        queryParameters.putSingle(DocumentHierarchyGraphStoreImpl.TIMEMAP_PARAM_NAME, "");

        filter.filter(request, response);

        assertTrue(link().contains("<" + DOCUMENT_URI + "?timemap>; rel=self; type=\"application/link-format\""));
        assertFalse(link().contains("rel=timemap"));
        assertTrue(link().contains("<" + DOCUMENT_URI + ">; rel=original"));
    }

    /** A TimeGate links to the TimeMap and to the Original Resource, but never to itself. */
    @Test
    public void testTimeGateDoesNotLinkToItself() throws IOException
    {
        versioned();
        queryParameters.putSingle(DocumentHierarchyGraphStoreImpl.TIMEGATE_PARAM_NAME, "");

        filter.filter(request, response);

        assertTrue(link().contains("rel=timemap"));
        assertFalse(link().contains("rel=timegate"));
        assertTrue(link().contains("<" + DOCUMENT_URI + ">; rel=original"));
    }

    /** A Memento is not the original, so it says which resource it is a version of. */
    @Test
    public void testMementoLinksToOriginalResource() throws IOException
    {
        versioned();
        queryParameters.putSingle(DocumentHierarchyGraphStoreImpl.VERSION_PARAM_NAME, "abc123");

        filter.filter(request, response);

        assertTrue(link().contains("<" + DOCUMENT_URI + ">; rel=original"));
        assertTrue(link().contains("rel=timemap"));
        assertTrue(link().contains("rel=timegate"));
    }

    // SERIALIZATION

    /**
     * Saxon-JS 2.x cannot read repeated header names (saxonica#5199), so the values are folded into one comma-separated
     * header. Nothing downstream in Java reports this going wrong, and the fold is string surgery over List.toString().
     */
    @Test
    public void testFoldsLinksIntoASingleHeader() throws IOException
    {
        authorized(ACL.Read);

        filter.filter(request, response);

        assertEquals(1, headers.get(HttpHeaders.LINK).size());
        // the brackets List.toString() puts around the values must not survive into the header
        assertFalse(link().startsWith("["));
        assertFalse(link().endsWith("]"));
        // and what is left between the values is the comma RFC 8288 separates them with
        assertTrue(link().contains(", <"));
    }

}
