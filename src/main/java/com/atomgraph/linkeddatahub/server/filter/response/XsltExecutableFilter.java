/**
 *  Copyright 2021 Martynas Jusevičius <martynas@atomgraph.com>
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
import com.atomgraph.linkeddatahub.MediaType;
import com.atomgraph.linkeddatahub.server.util.ClientStylesheetService;
import com.atomgraph.linkeddatahub.server.util.SecureXML;
import com.atomgraph.linkeddatahub.server.util.StylesheetComposer;
import com.atomgraph.linkeddatahub.vocabulary.LDH;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletionException;
import jakarta.annotation.Priority;
import jakarta.inject.Inject;
import jakarta.servlet.ServletContext;
import jakarta.ws.rs.InternalServerErrorException;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.client.Invocation;
import jakarta.ws.rs.client.WebTarget;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerResponseContext;
import jakarta.ws.rs.container.ContainerResponseFilter;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Collectors;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.Source;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.URIResolver;
import javax.xml.transform.dom.DOMResult;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.sax.SAXSource;
import javax.xml.transform.stream.StreamSource;
import net.sf.saxon.s9api.SaxonApiException;
import net.sf.saxon.s9api.XsltCompiler;
import net.sf.saxon.s9api.XsltExecutable;
import org.apache.commons.codec.binary.Hex;
import org.apache.commons.io.IOUtils;
import org.apache.jena.rdf.model.Resource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

/**
 * Response filter that loads and compiles the XSLT stylesheet of the application.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
@Priority(Priorities.USER + 350)
public class XsltExecutableFilter implements ContainerResponseFilter
{

    private static final Logger log = LoggerFactory.getLogger(XsltExecutableFilter.class);

    @Inject com.atomgraph.linkeddatahub.Application system;
    @Inject jakarta.inject.Provider<Optional<com.atomgraph.linkeddatahub.dataspaces.model.Dataspace>> application;

    @Context UriInfo uriInfo;
    @Context ServletContext servletContext;

    @Override
    public void filter(ContainerRequestContext req, ContainerResponseContext resp) throws IOException
    {
        // we only need the XSLT stylesheet if the response has (X)HTML media type
        if (resp.getMediaType() != null &&
            (resp.getMediaType().isCompatible(MediaType.TEXT_HTML_TYPE) || resp.getMediaType().isCompatible(MediaType.APPLICATION_XHTML_XML_TYPE)))
        {
            URI stylesheet = null;
            if (getDataspace().isPresent() && getDataspace().get().getStylesheet() != null)
                stylesheet = URI.create(getDataspace().get().getStylesheet().getURI());

            if (stylesheet != null)
            {
                List<URI> packages = getSystem().getPackageService().getPackageURIs(getDataspace().get());
                ClientStylesheetService stylesheetService = getSystem().getClientStylesheetService();

                if (packages.isEmpty()) req.setProperty(AC.stylesheet.getURI(), getXsltExecutable(stylesheet));
                else
                {
                    // server-side composition is never withheld: a declarative import takes effect on the
                    // next request, and it is the only rendering an instance whose compiler is unreachable
                    // will ever get
                    req.setProperty(AC.stylesheet.getURI(), getXsltExecutable(getDataspace().get(), stylesheet, packages));

                    if (stylesheetService != null)
                    {
                        String key = stylesheetService.getKey(packages);

                        // until the composed stylesheet exists the client renders without the package, as it
                        // always has; compiling one closes that window rather than opening it
                        if (stylesheetService.isPublished(key)) req.setProperty(LDH.clientStylesheet.getURI(), stylesheetService.getPublicPath(key));
                        else stylesheetService.buildAsync(key, getSystem().getPackageService().getStylesheets(getDataspace().get()));
                    }
                }
            }
            else req.setProperty(AC.stylesheet.getURI(), getSystem().getXsltExecutable());

        }
    }

    /**
     * Returns XSLT executable of the application stylesheet composed with the stylesheets of the
     * imported packages. Falls back to the executable of the stylesheet alone if the composed
     * stylesheet fails to compile (e.g. a package stylesheet URL cannot be loaded).
     *
     * @param app application resource
     * @param stylesheet stylesheet URI
     * @param packages imported package URIs
     * @return XSLT executable
     */
    public XsltExecutable getXsltExecutable(com.atomgraph.linkeddatahub.dataspaces.model.Dataspace app, URI stylesheet, List<URI> packages)
    {
        try
        {
            URI key = getCacheKey(stylesheet, packages);
            Map<URI, XsltExecutable> xsltExecCache = getXsltExecutableCache();

            if (isCacheStylesheet())
                // computeIfAbsent: a cold-start herd compiles the stylesheet once instead of once per thread
                return xsltExecCache.computeIfAbsent(key, k ->
                {
                    try
                    {
                        return getXsltExecutable(getComposition(app, stylesheet, packages));
                    }
                    catch (SaxonApiException | IOException | ParserConfigurationException | SAXException | TransformerException ex)
                    {
                        throw new CompletionException(ex);
                    }
                });

            return getXsltExecutable(getComposition(app, stylesheet, packages));
        }
        catch (SaxonApiException | IOException | ParserConfigurationException | SAXException | TransformerException | CompletionException ex)
        {
            if (log.isErrorEnabled()) log.error("Could not compile stylesheet '{}' composed with packages {}, falling back to the stylesheet alone", stylesheet, packages, ex);
            return getXsltExecutable(stylesheet);
        }
    }

    /**
     * A stylesheet composed with package imports: the entry source to compile and, when the marker lives
     * in a module the entry imports rather than in the entry itself, that module's composed document,
     * which is served to the compiler in place of the original.
     *
     * @param entry entry stylesheet source
     * @param moduleURI public URI of the composed module, or null when the entry itself was composed
     * @param module composed module document, or null when the entry itself was composed
     */
    public record Composition(Source entry, URI moduleURI, Document module) { }

    /**
     * A stylesheet module loaded while looking for the marker.
     *
     * @param uri public URI the module was resolved to
     * @param doc module document
     */
    public record StylesheetModule(URI uri, Document doc) { }

    /**
     * Composes the application stylesheet with the stylesheets of the imported packages.
     * The package imports are inserted at the marker (see {@link StylesheetComposer}): in the entry
     * stylesheet if it declares one, otherwise in the first module found by following the entry's
     * imports that does - the entry named by <code>ac:stylesheet</code> is a thin wrapper around the
     * platform's layout stylesheet, and the marker lives in the latter. Without a marker anywhere the
     * imports go after the entry's last import, where packages outrank the whole platform; that is the
     * behaviour before the marker existed and it is logged.
     * The entry source's system ID is the stylesheet's public URL, so its relative imports resolve on the
     * application's origin; a composed module is served under the public URL its import resolves to.
     *
     * @param app application resource
     * @param stylesheet stylesheet URI
     * @param packages imported package URIs
     * @return composition
     * @throws IOException I/O error
     * @throws ParserConfigurationException parser configuration error
     * @throws SAXException XML parsing error
     * @throws TransformerException XML parsing or serialization error
     */
    public Composition getComposition(com.atomgraph.linkeddatahub.dataspaces.model.Dataspace app, URI stylesheet, List<URI> packages) throws IOException, ParserConfigurationException, SAXException, TransformerException
    {
        List<String> hrefs = getSystem().getPackageService().getStylesheets(app).stream().map(URI::toString).collect(Collectors.toList());
        URI entryURI = getPublicURI(app, stylesheet);

        Source source = getSource(stylesheet.toString());
        if (!(source instanceof StreamSource)) throw new IOException("XSLT stylesheet could not be loaded from URI: " + stylesheet);
        Document entry = getDocument(((StreamSource)source).getInputStream(), stylesheet);

        if (StylesheetComposer.hasMarker(entry))
        {
            StylesheetComposer.insertImports(entry, hrefs);
            return new Composition(new DOMSource(entry, entryURI.toString()), null, null);
        }

        StylesheetModule module = findMarkerModule(entry, entryURI, 3);
        if (module != null)
        {
            StylesheetComposer.insertImports(module.doc(), hrefs);
            return new Composition(new DOMSource(entry, entryURI.toString()), module.uri(), module.doc());
        }

        if (log.isWarnEnabled()) log.warn("Stylesheet '{}' declares no '{}' import to mark where package imports go: {} are imported after its last import and outrank all of it", stylesheet, StylesheetComposer.MARKER_SUFFIX, hrefs);
        StylesheetComposer.insertImports(entry, hrefs);
        return new Composition(new DOMSource(entry, entryURI.toString()), null, null);
    }

    /**
     * Follows a stylesheet's imports, breadth-first and to the given depth, for the first module that
     * declares the marker import. Modules are loaded through the compiler's URI resolver, which serves
     * the application's own stylesheets locally, so a search costs no HTTP round trip.
     *
     * @param doc stylesheet document
     * @param docURI public URI the document's imports resolve against
     * @param depth how many import levels to follow
     * @return the module and its URI, or null if none declares the marker
     * @throws IOException I/O error
     * @throws ParserConfigurationException parser configuration error
     * @throws SAXException XML parsing error
     * @throws TransformerException resolution or parsing error
     */
    public StylesheetModule findMarkerModule(Document doc, URI docURI, int depth) throws IOException, ParserConfigurationException, SAXException, TransformerException
    {
        if (depth <= 0) return null;

        List<StylesheetModule> children = new ArrayList<>();
        for (Element imp : StylesheetComposer.getImports(doc))
        {
            String href = imp.getAttribute("href");
            URI childURI = docURI.resolve(href);
            Document child = getDocument(childURI, href, docURI);
            if (child == null) continue;

            if (StylesheetComposer.hasMarker(child)) return new StylesheetModule(childURI, child);
            children.add(new StylesheetModule(childURI, child));
        }

        for (StylesheetModule child : children)
        {
            StylesheetModule found = findMarkerModule(child.doc(), child.uri(), depth - 1);
            if (found != null) return found;
        }

        return null;
    }

    /**
     * Loads an imported stylesheet module as a document, through the compiler's URI resolver when there
     * is one and directly otherwise.
     *
     * @param uri resolved module URI
     * @param href import href as written
     * @param base URI the href was written against
     * @return module document, or null if it could not be loaded
     * @throws IOException I/O error
     * @throws ParserConfigurationException parser configuration error
     * @throws SAXException XML parsing error
     * @throws TransformerException resolution or parsing error
     */
    public Document getDocument(URI uri, String href, URI base) throws IOException, ParserConfigurationException, SAXException, TransformerException
    {
        URIResolver resolver = getXsltCompiler().getURIResolver();
        Source source = resolver != null ? resolver.resolve(href, base.toString()) : getSource(uri.toString());
        if (source == null) source = getSource(uri.toString());
        if (!(source instanceof StreamSource stream)) return null;

        InputStream is = stream.getInputStream();
        if (is == null && stream.getSystemId() != null)
        {
            Source direct = getSource(stream.getSystemId());
            if (!(direct instanceof StreamSource directStream)) return null;
            is = directStream.getInputStream();
        }
        if (is == null) return null;

        return getDocument(is, uri);
    }

    /**
     * Compiles a composition. A module composed behind the entry is served to a dedicated compiler in
     * place of the original, through a resolver that answers that one URI and delegates the rest: the
     * shared compiler's resolver is shared state and stays as it is.
     *
     * @param composition composed stylesheet
     * @return XSLT executable
     * @throws SaxonApiException Saxon error
     */
    public XsltExecutable getXsltExecutable(Composition composition) throws SaxonApiException
    {
        if (composition.module() == null) return getXsltExecutable(composition.entry());

        URIResolver resolver = getXsltCompiler().getURIResolver();
        XsltCompiler compiler = getXsltCompiler().getProcessor().newXsltCompiler();
        compiler.setURIResolver((href, base) ->
        {
            URI resolved = href.isEmpty() ? URI.create(base) : URI.create(base).resolve(href);
            if (resolved.equals(composition.moduleURI())) return new DOMSource(composition.module(), composition.moduleURI().toString());

            return resolver != null ? resolver.resolve(href, base) : null;
        });

        return compiler.compile(composition.entry());
    }

    /**
     * Parses a stylesheet into a DOM document with its entities expanded.
     * The DOCTYPE-tolerant reader rather than {@link SecureXML#newDocumentBuilderFactory()}, which forbids
     * a DOCTYPE outright: an application's stylesheet is authored, not built, and declaring namespaces as
     * internal entities is the idiom every stylesheet in this repository is written in. Refusing them made
     * a declarative import silently do nothing - the composition threw, the filter logged and fell back to
     * the stylesheet alone, and the application rendered with none of the package's rules. The client-side
     * composition reached the same conclusion in {@code ClientStylesheetService.expandEntities()}, so the
     * two paths now accept the same stylesheets.
     *
     * @param is stylesheet stream
     * @param systemId system id to resolve relative references against
     * @return stylesheet document
     * @throws ParserConfigurationException parser configuration error
     * @throws SAXException XML parsing error
     * @throws TransformerException XML parsing or serialization error
     */
    public Document getDocument(InputStream is, URI systemId) throws ParserConfigurationException, SAXException, TransformerException
    {
        SAXSource source = new SAXSource(SecureXML.newXMLReader(), new InputSource(is));
        source.setSystemId(systemId.toString());

        DOMResult result = new DOMResult();
        TransformerFactory.newInstance().newTransformer().transform(source, result);

        return (Document)result.getNode();
    }

    /**
     * Inserts <code>xsl:import</code> elements for the given stylesheet URLs into the stylesheet document
     * at the marker, or after the last existing import when there is none.
     *
     * @param doc stylesheet document
     * @param imports stylesheet URLs to import
     * @return true if inserted at a marker
     * @see StylesheetComposer#insertImports(Document, List)
     */
    public boolean appendImports(Document doc, List<URI> imports)
    {
        return StylesheetComposer.insertImports(doc, imports.stream().map(URI::toString).collect(Collectors.toList()));
    }

    /**
     * Maps the stylesheet URI to its public URL on the application's origin.
     * The inverse of the absolutization of relative stylesheet URIs against the webapp root at context
     * dataset parse time. URIs that are already HTTP(S), or fall outside the webapp root, are returned as-is.
     *
     * @param app application resource
     * @param stylesheet stylesheet URI
     * @return public stylesheet URL
     * @throws MalformedURLException URL error
     */
    public URI getPublicURI(com.atomgraph.linkeddatahub.dataspaces.model.Dataspace app, URI stylesheet) throws MalformedURLException
    {
        if ("http".equals(stylesheet.getScheme()) || "https".equals(stylesheet.getScheme())) return stylesheet;

        URI root = URI.create(getServletContext().getResource("/").toString());
        URI relative = root.relativize(stylesheet);
        if (relative.isAbsolute()) return stylesheet;

        return app.getBaseURI().resolve(relative);
    }

    /**
     * Returns the cache key for a stylesheet composed with package imports.
     * The key is derived from the stylesheet URI and the sorted package URIs, so a changed import set
     * yields a new key and a fresh compilation on the next lookup.
     *
     * @param stylesheet stylesheet URI
     * @param packages imported package URIs
     * @return cache key
     */
    public URI getCacheKey(URI stylesheet, List<URI> packages)
    {
        if (packages.isEmpty()) return stylesheet;

        try
        {
            MessageDigest md = MessageDigest.getInstance("SHA-1");
            md.update(stylesheet.toString().getBytes(StandardCharsets.UTF_8));
            for (URI packageURI : packages.stream().sorted().collect(Collectors.toList()))
            {
                md.update((byte)'\n');
                md.update(packageURI.toString().getBytes(StandardCharsets.UTF_8));
            }

            return URI.create("urn:sha1:" + Hex.encodeHexString(md.digest()));
        }
        catch (NoSuchAlgorithmException ex)
        {
            throw new InternalServerErrorException(ex);
        }
    }

    /**
     * Returns XSLT executable for the given stylesheet URI.
     * 
     * @param stylesheet stylesheet URI
     * @return XSLT executable
     */
    public XsltExecutable getXsltExecutable(URI stylesheet)
    {
        try
        {
            return getXsltExecutable(stylesheet, getXsltExecutableCache());
        }
        catch (SaxonApiException ex)
        {
            if (log.isErrorEnabled()) log.error("XSLT transformer not configured property", ex);
            throw new InternalServerErrorException(ex); // TO-DO: throw new XSLTException(ex);
        }
        catch (IOException ex)
        {
            if (log.isErrorEnabled()) log.error("XSLT stylesheet not found or error reading it", ex);
            throw new InternalServerErrorException(ex); // TO-DO: throw new XSLTException(ex);
        }
    }
    
    /**
     * Returns compiled XSLT stylesheet. First looks in the cache, if it's enabled; otherwise read from URL.
     * 
     * @param stylesheet stylesheet URI
     * @param xsltExecCache executable cache
     * @return XsltExecutable XSLT executable
     * @throws java.io.IOException I/O error
     * @throws SaxonApiException Saxon error
     */
    public XsltExecutable getXsltExecutable(URI stylesheet, Map<URI, XsltExecutable> xsltExecCache) throws IOException, SaxonApiException
    {
        if (isCacheStylesheet())
        {
            try
            {
                // computeIfAbsent: a cold-start herd compiles the stylesheet once instead of once per thread
                return xsltExecCache.computeIfAbsent(stylesheet, key ->
                {
                    try
                    {
                        return getXsltExecutable(getSource(key.toString()));
                    }
                    catch (IOException | SaxonApiException ex)
                    {
                        throw new CompletionException(ex);
                    }
                });
            }
            catch (CompletionException ex)
            {
                // unwrap so callers keep seeing the declared checked exceptions
                if (ex.getCause() instanceof IOException ioEx) throw ioEx;
                if (ex.getCause() instanceof SaxonApiException saxonEx) throw saxonEx;
                throw ex;
            }
        }

        return getXsltExecutable(getSource(stylesheet.toString()));
    }
    
    /**
     * Compiles XSLT document source into an XSLT executable.
     * 
     * @param source XSLT document source
     * @return XSLT executable
     * @throws SaxonApiException Saxon error
     */
    public XsltExecutable getXsltExecutable(Source source) throws SaxonApiException
    {
        return getXsltCompiler().compile(source);
    }
    
    /**
     * Loads XML document source from URL.
     * Supports JNDI and HTTP(S) schemes.
     * 
     * @param url document URL
     * @return document source
     * @throws IOException I/O error
     */
    public Source getSource(String url) throws IOException
    {
        if (url == null) throw new IllegalArgumentException("URI name cannot be null");
        
        URI uri = getUriInfo().getBaseUri().resolve(url);
        if (log.isDebugEnabled()) log.debug("Loading Source using '{}' scheme from URL '{}'", uri.getScheme(), uri);
        
        if (uri.getScheme().equals("file") || uri.getScheme().equals("jndi"))
            try (InputStream is = uri.toURL().openStream())
            {
                byte[] bytes = IOUtils.toByteArray(is);
                return new StreamSource(new ByteArrayInputStream(bytes), url);
            }
        
        if (uri.getScheme().equals("http") || uri.getScheme().equals("https"))
        {
            WebTarget webResource = getClient().target(uri);
            Invocation.Builder builder = webResource.request();

            try (Response cr = builder.accept(MediaType.TEXT_XSL_TYPE).get())
            {
                if (!cr.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
                    throw new IOException("XSLT stylesheet could not be successfully loaded over HTTP. URL: " + uri);

                // buffer the stylesheet stream so we can close Response
                try (InputStream is = cr.readEntity(InputStream.class))
                {
                    byte[] bytes = IOUtils.toByteArray(is);
                    return new StreamSource(new ByteArrayInputStream(bytes), uri.toString());
                }
            }
        }
        
        return null;
    }

    /**
     * Returns HTTP client.
     * 
     * @return HTTP client
     */
    public Client getClient()
    {
        return getSystem().getClient();
    }

    /**
     * Returns XSLT compiler.
     * 
     * @return XSLT compiler
     */
    public XsltCompiler getXsltCompiler()
    {
        return getSystem().getXsltCompiler();
    }

    /**
     * Returns true if XSLT stylesheets are cached.
     * 
     * @return true if cached
     */
    public boolean isCacheStylesheet()
    {
        return getSystem().isCacheStylesheet();
    }
    
    /**
     * Returns the cache map for XSLT executables.
     * 
     * @return stylesheet URI to executable map
     */
    public Map<URI, XsltExecutable> getXsltExecutableCache()
    {
        return getSystem().getXsltExecutableCache();
    }
    
    /**
     * Returns system application.
     * 
     * @return JAX-RS application
     */
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }
    
    /**
     * Returns current application.
     *
     * @return optional application resource
     */
    public Optional<com.atomgraph.linkeddatahub.dataspaces.model.Dataspace> getDataspace()
    {
        return application.get();
    }

    /**
     * Returns URI info of the current request.
     *
     * @return URI info
     */
    public UriInfo getUriInfo()
    {
        return uriInfo;
    }

    /**
     * Returns servlet context.
     *
     * @return servlet context
     */
    public ServletContext getServletContext()
    {
        return servletContext;
    }

}
