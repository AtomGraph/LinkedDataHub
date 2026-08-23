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
import com.atomgraph.linkeddatahub.server.util.SecureXML;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.List;
import java.util.Map;
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
import javax.xml.transform.dom.DOMSource;
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
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.SAXException;

/**
 * Response filter that loads and compiles the XSLT stylesheet of the application.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
@Priority(Priorities.USER + 200)
public class XsltExecutableFilter implements ContainerResponseFilter
{

    private static final Logger log = LoggerFactory.getLogger(XsltExecutableFilter.class);

    private static final String XSL_NS = "http://www.w3.org/1999/XSL/Transform";

    @Inject com.atomgraph.linkeddatahub.Application system;
    @Inject jakarta.inject.Provider<Optional<com.atomgraph.linkeddatahub.apps.model.Application>> application;

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
            if (getApplication().isPresent() && getApplication().get().getStylesheet() != null)
                stylesheet = URI.create(getApplication().get().getStylesheet().getURI());

            if (stylesheet != null)
            {
                List<URI> packages = getPackages(getApplication().get());

                if (packages.isEmpty()) req.setProperty(AC.stylesheet.getURI(), getXsltExecutable(stylesheet));
                else req.setProperty(AC.stylesheet.getURI(), getXsltExecutable(getApplication().get(), stylesheet, packages));
            }
            else req.setProperty(AC.stylesheet.getURI(), getSystem().getXsltExecutable());

        }
    }

    /**
     * Returns URIs of the packages imported by the application, ordered by URI.
     *
     * @param app application resource
     * @return list of package URIs
     */
    public List<URI> getPackages(com.atomgraph.linkeddatahub.apps.model.Application app)
    {
        return app.getImportedPackages().stream().
            filter(Resource::isURIResource).
            map(pkg -> URI.create(pkg.getURI())).
            sorted().
            collect(Collectors.toList());
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
    public XsltExecutable getXsltExecutable(com.atomgraph.linkeddatahub.apps.model.Application app, URI stylesheet, List<URI> packages)
    {
        try
        {
            URI key = getCacheKey(stylesheet, packages);
            Map<URI, XsltExecutable> xsltExecCache = getXsltExecutableCache();

            if (isCacheStylesheet())
            {
                // create cache entry if it does not exist
                if (!xsltExecCache.containsKey(key))
                    xsltExecCache.put(key, getXsltExecutable(getComposedSource(app, stylesheet, packages)));

                return xsltExecCache.get(key);
            }

            return getXsltExecutable(getComposedSource(app, stylesheet, packages));
        }
        catch (SaxonApiException | IOException | ParserConfigurationException | SAXException ex)
        {
            if (log.isErrorEnabled()) log.error("Could not compile stylesheet '{}' composed with packages {}, falling back to the stylesheet alone", stylesheet, packages, ex);
            return getXsltExecutable(stylesheet);
        }
    }

    /**
     * Composes the application stylesheet document with the stylesheets of the imported packages.
     * The stylesheet URLs are read from the package descriptions, which are resolved from the package
     * URIs. The <code>xsl:import</code> elements are inserted after the last existing import, so package
     * imports rank below the stylesheet's own declarations in import precedence.
     * The source's system ID is the stylesheet's public URL, so its relative imports resolve on the
     * application's origin.
     *
     * @param app application resource
     * @param stylesheet stylesheet URI
     * @param packages imported package URIs
     * @return composed stylesheet source
     * @throws IOException I/O error
     * @throws ParserConfigurationException parser configuration error
     * @throws SAXException XML parsing error
     */
    public Source getComposedSource(com.atomgraph.linkeddatahub.apps.model.Application app, URI stylesheet, List<URI> packages) throws IOException, ParserConfigurationException, SAXException
    {
        Source source = getSource(stylesheet.toString());
        if (!(source instanceof StreamSource)) throw new IOException("XSLT stylesheet could not be loaded from URI: " + stylesheet);

        Document doc = SecureXML.newDocumentBuilderFactory().newDocumentBuilder().parse(((StreamSource)source).getInputStream());
        appendImports(doc, getStylesheets(packages));

        return new DOMSource(doc, getPublicURI(app, stylesheet).toString());
    }

    /**
     * Resolves the package descriptions and returns their stylesheet URLs, in package order.
     * Packages whose description cannot be resolved, or without a stylesheet (ontology-only),
     * are skipped.
     *
     * @param packages package URIs
     * @return list of stylesheet URLs
     */
    public List<URI> getStylesheets(List<URI> packages)
    {
        return packages.stream().
            map(pkg -> getPackage(pkg.toString())).
            filter(Objects::nonNull).
            map(com.atomgraph.linkeddatahub.apps.model.Package::getStylesheet).
            filter(Objects::nonNull).
            map(stylesheet -> URI.create(stylesheet.getURI())).
            collect(Collectors.toList());
    }

    /**
     * Loads the package description from its URI.
     * Mapped locations (e.g. bundled package descriptions) and cached graphs are read from the graph
     * repository; other URIs are dereferenced over HTTP.
     *
     * @param packageURI package URI
     * @return package resource, or null if the description could not be resolved
     */
    public com.atomgraph.linkeddatahub.apps.model.Package getPackage(String packageURI)
    {
        return getSystem().getPackage(packageURI);
    }

    /**
     * Appends <code>xsl:import</code> elements for the given stylesheet URLs to the stylesheet document,
     * after the last existing import.
     *
     * @param doc stylesheet document
     * @param imports stylesheet URLs to import
     */
    public void appendImports(Document doc, List<URI> imports)
    {
        Element stylesheetElem = doc.getDocumentElement();

        Node lastImport = null;
        NodeList children = stylesheetElem.getChildNodes();
        for (int i = 0; i < children.getLength(); i++)
        {
            Node child = children.item(i);
            if (child.getNodeType() == Node.ELEMENT_NODE &&
                    XSL_NS.equals(child.getNamespaceURI()) &&
                    "import".equals(child.getLocalName()))
                lastImport = child;
        }

        for (URI importURI : imports)
        {
            Element newImport = doc.createElementNS(XSL_NS, "xsl:import");
            newImport.setAttribute("href", importURI.toString());

            Node anchor = (lastImport != null) ? lastImport.getNextSibling() : stylesheetElem.getFirstChild();
            stylesheetElem.insertBefore(newImport, anchor);
            lastImport = newImport;
        }
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
    public URI getPublicURI(com.atomgraph.linkeddatahub.apps.model.Application app, URI stylesheet) throws MalformedURLException
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
            // create cache entry if it does not exist
            if (!xsltExecCache.containsKey(stylesheet))
                xsltExecCache.put(stylesheet, getXsltExecutable(getSource(stylesheet.toString())));
            
            return xsltExecCache.get(stylesheet);
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
    public Optional<com.atomgraph.linkeddatahub.apps.model.Application> getApplication()
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
