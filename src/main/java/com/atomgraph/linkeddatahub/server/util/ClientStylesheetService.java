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
package com.atomgraph.linkeddatahub.server.util;

import com.atomgraph.linkeddatahub.server.filter.request.ContentLengthLimitFilter;
import jakarta.json.Json;
import jakarta.json.JsonArrayBuilder;
import jakarta.json.JsonObject;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.security.DigestInputStream;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.stream.Collectors;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.sax.SAXSource;
import javax.xml.transform.stream.StreamResult;
import org.apache.commons.codec.binary.Hex;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.xml.sax.InputSource;
import java.net.URISyntaxException;
import java.net.URL;
import java.util.ArrayList;
import javax.xml.transform.dom.DOMResult;
import javax.xml.transform.dom.DOMSource;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

/**
 * Composes and compiles the client stylesheet of applications that import packages.
 *
 * The client SEF shipped in the webapp is compiled at build time from <code>client.xsl</code> alone,
 * so package rules reach server-rendered output only and vanish as soon as the client re-renders a
 * pane. Saxon-JS cannot compile in the browser, and independently compiled per-package SEFs cannot
 * be composed, because <code>xsl:import</code> precedence is resolved at compile time. This service
 * therefore composes and compiles one SEF per distinct import set, out-of-process.
 *
 * Keyed on the <em>inputs</em> rather than the output: a SEF is not byte-deterministic (its header
 * carries a build timestamp), so content-addressing the result would mint a new URI on every compile
 * and a different one on every node. The key combines the digest of the stock SEF - which fingerprints
 * every client module and changes on every platform build - with the sorted package URIs, so a
 * platform upgrade invalidates it and nodes agree on one URI for one import set.
 *
 * Compilation is best-effort: a failure leaves the key unpublished, which keeps both renderers on the
 * stock stylesheet rather than letting the server compose while the client cannot.
 *
 * The entry composed is the client stylesheet the page bootstraps, which is the stock
 * <code>client.xsl</code> unless a deployment names its own. A deployment's entry imports the stock
 * stylesheet and carries no marker of its own, so its packages are composed into the stock module,
 * which travels to the compiler as a named module of its own beside the stock file - where its
 * relative hrefs still resolve - with the entry's import repointed at it. The compiler holds nothing but
 * the stock static tree, so an entry's other modules travel the same way. The entry's own bytes then
 * enter the key, so an edit to it mints a new stylesheet as a platform upgrade does.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ClientStylesheetService
{

    private static final Logger log = LoggerFactory.getLogger(ClientStylesheetService.class);

    /** Path under which composed stylesheets are served, mapped to the SEF root by a Tomcat alias */
    public static final String PUBLIC_PATH = "static/xsl/sef/";

    /** Suffix of a compiled stylesheet file */
    public static final String SEF_SUFFIX = ".sef.json";

    /** Module name the composed stock stylesheet is sent under when the entry is a deployment's own */
    public static final String COMPOSED_STOCK_MODULE = "ldh-composed-client.xsl";

    /** Prefix of the module names package stylesheets are sent under */
    public static final String PACKAGE_MODULE_PREFIX = "pkg-";

    /** Prefix of the module names a deployment entry's own modules are sent under */
    public static final String ENTRY_MODULE_PREFIX = "site-";

    private final Path sefRoot;
    private final URI compilerURI;
    private final Client client;
    private final URL clientStylesheet;
    private final URL stockStylesheet;
    private final String baseDigest;
    private final String entryDigest;
    private final Set<String> published = ConcurrentHashMap.newKeySet();
    private final Map<String, CompletableFuture<Void>> builds = new ConcurrentHashMap<>();
    // one at a time: the compile peaks around 1.5 GB, and the compiler refuses concurrent jobs anyway
    private final ExecutorService executor = Executors.newFixedThreadPool(1);

    /**
     * Constructs the service and adopts any stylesheets a previous run left in the SEF root.
     *
     * @param sefRoot directory holding compiled stylesheets
     * @param compilerURI URI of the compiler service's compile endpoint
     * @param client HTTP client
     * @param clientStylesheet the client stylesheet the page bootstraps, composed with the packages on every build - the stock one unless the deployment names its own
     * @param stockStylesheet the client stylesheet source built into the webapp, the module that carries the package marker
     * @param stockSEF stream of the stylesheet built into the webapp, digested as the platform fingerprint
     * @throws IOException if a stylesheet cannot be read or the SEF root cannot be scanned
     */
    public ClientStylesheetService(Path sefRoot, URI compilerURI, Client client, URL clientStylesheet, URL stockStylesheet, InputStream stockSEF) throws IOException
    {
        this.sefRoot = sefRoot;
        this.compilerURI = compilerURI;
        this.client = client;
        this.clientStylesheet = clientStylesheet;
        this.stockStylesheet = stockStylesheet;
        this.baseDigest = digest(stockSEF);

        // the stock entry is already fingerprinted by the SEF built from it; a deployment's own is not
        if (isStockEntry()) this.entryDigest = null;
        else
            try (InputStream is = clientStylesheet.openStream())
            {
                this.entryDigest = digest(is);
            }

        Files.createDirectories(sefRoot);
        try (var paths = Files.list(sefRoot))
        {
            paths.map(path -> path.getFileName().toString()).
                filter(name -> name.endsWith(SEF_SUFFIX)).
                map(name -> name.substring(0, name.length() - SEF_SUFFIX.length())).
                forEach(published::add);
        }

        if (log.isInfoEnabled()) log.info("Client stylesheet service ready, entry <{}>, compiler <{}>, {} stylesheet(s) already compiled", clientStylesheet, compilerURI, published.size());
    }

    /**
     * Returns true if the entry composed is the stock client stylesheet itself.
     *
     * @return true if stock
     */
    public boolean isStockEntry()
    {
        return toURI(getClientStylesheet()).equals(toURI(getStockStylesheet()));
    }

    /**
     * Returns the key identifying the stylesheet composed from this platform build, this entry and these packages.
     *
     * @param packages imported package URIs
     * @return key
     */
    public String getKey(List<URI> packages)
    {
        try
        {
            MessageDigest md = MessageDigest.getInstance("SHA-1"); // a fresh instance: Application's is shared and not thread-safe
            md.update(baseDigest.getBytes(StandardCharsets.UTF_8));
            if (entryDigest != null)
            {
                md.update((byte)'\n');
                md.update(entryDigest.getBytes(StandardCharsets.UTF_8));
            }
            for (URI pkg : packages.stream().sorted().collect(Collectors.toList()))
            {
                md.update((byte)'\n');
                md.update(pkg.toString().getBytes(StandardCharsets.UTF_8));
            }

            return Hex.encodeHexString(md.digest());
        }
        catch (NoSuchAlgorithmException ex)
        {
            throw new IllegalStateException(ex);
        }
    }

    /**
     * Returns true if a stylesheet for this key has been compiled and is readable.
     *
     * @param key stylesheet key
     * @return true if published
     */
    public boolean isPublished(String key)
    {
        return published.contains(key);
    }

    /**
     * Returns the path of a compiled stylesheet, relative to the application's base URI.
     *
     * @param key stylesheet key
     * @return relative path
     */
    public String getPublicPath(String key)
    {
        return PUBLIC_PATH + key + SEF_SUFFIX;
    }

    /**
     * Compiles the stylesheet for this key unless it is already compiled or being compiled.
     * Returns immediately; the result is observed through {@link #isPublished(String)}.
     *
     * @param key stylesheet key
     * @param stylesheets package stylesheet URLs, in import order
     */
    public void buildAsync(String key, List<URI> stylesheets)
    {
        if (isPublished(key)) return;

        CompletableFuture<Void> build = builds.computeIfAbsent(key, k ->
            CompletableFuture.runAsync(() -> build(k, stylesheets), executor).
                exceptionally(ex ->
                {
                    if (log.isErrorEnabled()) log.error("Could not compile client stylesheet '{}': {}", k, ex.getMessage());
                    return null;
                }));

        // registered after computeIfAbsent returns: whenComplete runs on the calling thread when the future
        // is already done, and ConcurrentHashMap forbids re-entrant updates from inside the mapping function -
        // registered inside, a fast completion would remove the entry before it is installed and leak it
        build.whenComplete((result, ex) -> builds.remove(key, build));
    }

    private void build(String key, List<URI> stylesheets)
    {
        JsonObject request = compose(stylesheets);

        byte[] sef;
        try (Response cr = getClient().target(getCompilerURI()).request(MediaType.APPLICATION_JSON_TYPE).
                property(ContentLengthLimitFilter.UNLIMITED, true). // the composed SEF is ~18 MiB, far past the guard that bounds proxied content
                post(Entity.entity(request, MediaType.APPLICATION_JSON_TYPE)))
        {
            if (!cr.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
                // the compiler returns the diagnostics verbatim; a package author needs those, not "compilation failed"
                throw new IllegalStateException("Compiler returned " + cr.getStatus() + ": " + cr.readEntity(String.class));

            try (InputStream is = cr.readEntity(InputStream.class))
            {
                sef = is.readAllBytes();
            }
            catch (IOException ex)
            {
                throw new IllegalStateException("Could not read compiled stylesheet", ex);
            }
        }

        try
        {
            // temp file plus atomic move, so a reader never sees a partially written stylesheet
            Path temp = Files.createTempFile(getSEFRoot(), key, ".tmp");
            Files.write(temp, sef);
            Files.move(temp, getSEFRoot().resolve(key + SEF_SUFFIX), StandardCopyOption.ATOMIC_MOVE, StandardCopyOption.REPLACE_EXISTING);
        }
        catch (IOException ex)
        {
            throw new IllegalStateException("Could not store compiled stylesheet '" + key + "'", ex);
        }

        published.add(key);
        if (log.isInfoEnabled()) log.info("Compiled client stylesheet '{}' from {} package stylesheet(s), {} bytes", key, stylesheets.size(), sef.length);
    }

    /**
     * Composes the compiler request for the given package stylesheets: the entry with the package imports
     * inserted at the marker, and the modules the compiler has to write beside the stock
     * <code>client.xsl</code> before compiling it - each package, and whatever the entry needs that is not
     * in the stock tree.
     *
     * @param stylesheets package stylesheet URLs, in import order
     * @return request with <code>entry</code> and <code>imports</code>
     */
    public JsonObject compose(List<URI> stylesheets)
    {
        List<String> names = new ArrayList<>();
        JsonArrayBuilder imports = Json.createArrayBuilder();
        for (int i = 0; i < stylesheets.size(); i++)
            names.add(PACKAGE_MODULE_PREFIX + i + ".xsl");

        // the entry is client.xsl with the package imports inserted at its marker, the same composition
        // the server applies to its own stylesheet: the packages outrank the open modes' fallbacks and
        // nothing else. Sent composed rather than wrapped, because a wrapper importing client.xsl and then
        // the packages would put them above the whole client tree
        String entry = isStockEntry() ? composeEntry(names) : composeDeploymentEntry(names, imports);

        for (int i = 0; i < stylesheets.size(); i++)
            imports.add(Json.createObjectBuilder().
                add("name", names.get(i)).
                add("content", expandEntities(stylesheets.get(i))));

        return Json.createObjectBuilder().
            add("entry", entry).
            add("imports", imports).
            build();
    }

    /**
     * Composes the stock client stylesheet with the given package modules: parses it, inserts an
     * <code>xsl:import</code> per module at the marker (see {@link StylesheetComposer}) and serialises
     * the result with its entities expanded, ready to be written beside the stock <code>client.xsl</code>
     * so that every relative href in it still resolves.
     *
     * @param names package module file names, as the compiler will write them
     * @return composed stylesheet
     */
    public String composeEntry(List<String> names)
    {
        try
        {
            Document stock = parse(getStockStylesheet());
            if (!StylesheetComposer.insertImports(stock, names))
                if (log.isWarnEnabled()) log.warn("Client stylesheet <{}> declares no '{}' import to mark where package imports go: {} are imported after its last import and outrank all of it", getStockStylesheet(), StylesheetComposer.MARKER_SUFFIX, names);

            return serialize(stock);
        }
        catch (Exception ex)
        {
            throw new IllegalStateException("Could not compose client stylesheet <" + getStockStylesheet() + ">", ex);
        }
    }

    /**
     * Composes a deployment's own entry with the given package modules. The entry carries no marker: it
     * imports the stock client stylesheet, so the packages are composed into that module, which is sent
     * as {@value #COMPOSED_STOCK_MODULE} and the entry's import repointed at it. Every other module the
     * entry imports or includes is rewritten to where the compiler will find it: relative to the stock
     * directory when it is in the stock tree, and as a {@value #ENTRY_MODULE_PREFIX} module sent along
     * otherwise. Only the entry's own declarations are followed - a sent module's relative references
     * resolve against the stock directory it is written to.
     *
     * @param names package module file names, as the compiler will write them
     * @param imports request modules, appended to
     * @return composed entry
     */
    public String composeDeploymentEntry(List<String> names, JsonArrayBuilder imports)
    {
        try
        {
            Document entry = parse(getClientStylesheet());
            URI entryURI = toURI(getClientStylesheet());
            URI stockURI = toURI(getStockStylesheet());
            URI stockDir = stockURI.resolve(".");

            boolean composed = false;
            int sent = 0;
            for (Element module : getModules(entry))
            {
                String href = module.getAttribute("href");
                URI resolved = entryURI.resolve(href).normalize();

                if (resolved.equals(stockURI))
                {
                    imports.add(Json.createObjectBuilder().
                        add("name", COMPOSED_STOCK_MODULE).
                        add("content", composeEntry(names)));
                    module.setAttribute("href", COMPOSED_STOCK_MODULE);
                    composed = true;
                }
                else if (resolved.toString().startsWith(stockDir.toString()))
                    module.setAttribute("href", stockDir.relativize(resolved).toString());
                else
                {
                    String name = ENTRY_MODULE_PREFIX + sent++ + ".xsl";
                    try (InputStream is = resolved.toURL().openStream())
                    {
                        imports.add(Json.createObjectBuilder().
                            add("name", name).
                            add("content", expandEntities(is, resolved)));
                    }
                    module.setAttribute("href", name);
                    if (log.isWarnEnabled()) log.warn("Module <{}> of client stylesheet <{}> is sent to the compiler as '{}': its own relative references resolve against the stock stylesheet directory", resolved, getClientStylesheet(), name);
                }
            }

            if (!composed)
            {
                if (log.isWarnEnabled()) log.warn("Client stylesheet <{}> does not import the stock client stylesheet <{}> directly: {} are imported after its last import and outrank all of it", getClientStylesheet(), getStockStylesheet(), names);
                StylesheetComposer.insertImports(entry, names);
            }

            return serialize(entry);
        }
        catch (Exception ex)
        {
            throw new IllegalStateException("Could not compose client stylesheet <" + getClientStylesheet() + ">", ex);
        }
    }

    /**
     * Returns the top-level <code>xsl:import</code> and <code>xsl:include</code> elements of a stylesheet,
     * in document order.
     *
     * @param doc stylesheet document
     * @return module elements
     */
    public static List<Element> getModules(Document doc)
    {
        List<Element> modules = new ArrayList<>();
        NodeList children = doc.getDocumentElement().getChildNodes();
        for (int i = 0; i < children.getLength(); i++)
        {
            Node child = children.item(i);
            if (child.getNodeType() == Node.ELEMENT_NODE &&
                    StylesheetComposer.XSL_NS.equals(child.getNamespaceURI()) &&
                    ("import".equals(child.getLocalName()) || "include".equals(child.getLocalName())))
                modules.add((Element)child);
        }
        return modules;
    }

    /**
     * Parses a stylesheet with the DOCTYPE-tolerant reader, so one declaring entities - as a deployment's
     * own does - loads, and its entities are expanded in the DOM.
     *
     * @param stylesheet stylesheet URL
     * @return stylesheet document
     * @throws Exception if the stylesheet cannot be read or parsed
     */
    private Document parse(URL stylesheet) throws Exception
    {
        try (InputStream is = stylesheet.openStream())
        {
            SAXSource source = new SAXSource(SecureXML.newXMLReader(), new InputSource(is));
            source.setSystemId(stylesheet.toString());
            DOMResult result = new DOMResult();
            TransformerFactory.newInstance().newTransformer().transform(source, result);
            return (Document)result.getNode();
        }
    }

    private String serialize(Document doc) throws Exception
    {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        TransformerFactory.newInstance().newTransformer().transform(new DOMSource(doc), new StreamResult(baos));
        return baos.toString(StandardCharsets.UTF_8);
    }

    private static URI toURI(URL url)
    {
        try
        {
            return url.toURI().normalize();
        }
        catch (URISyntaxException ex)
        {
            throw new IllegalArgumentException(ex);
        }
    }

    /**
     * Returns the client stylesheet the page bootstraps - the entry composed with the packages.
     *
     * @return stylesheet URL
     */
    public URL getClientStylesheet()
    {
        return clientStylesheet;
    }

    /**
     * Returns the client stylesheet source built into the webapp - the module carrying the package marker.
     *
     * @return stylesheet URL
     */
    public URL getStockStylesheet()
    {
        return stockStylesheet;
    }

    /**
     * Reads a package stylesheet and serialises it with its internal entities expanded.
     * The compiler's parser has no DTD internal subset, so a stylesheet declaring entities - as the
     * bundled ones do - must be expanded first, the same step the build applies to the webapp's own
     * stylesheets before compiling them.
     *
     * @param stylesheet stylesheet URL
     * @return expanded stylesheet
     */
    public String expandEntities(URI stylesheet)
    {
        try (Response cr = getClient().target(stylesheet).request(com.atomgraph.linkeddatahub.MediaType.TEXT_XSL_TYPE).get())
        {
            if (!cr.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
                throw new IllegalStateException("Package stylesheet <" + stylesheet + "> could not be loaded: " + cr.getStatus());

            try (InputStream is = cr.readEntity(InputStream.class))
            {
                return expandEntities(is, stylesheet);
            }
        }
        catch (IOException ex)
        {
            throw new IllegalStateException("Could not read package stylesheet <" + stylesheet + ">", ex);
        }
    }

    /**
     * Parses an already-opened stylesheet with the DOCTYPE-tolerant reader and serialises it with its
     * entities expanded. The overload taking a URI decides where the bytes come from and delegates here.
     *
     * @param is stylesheet stream
     * @param systemId system id to resolve relative references against
     * @return expanded stylesheet
     */
    public String expandEntities(InputStream is, URI systemId)
    {
        try
        {
            // newXMLReader() tolerates a benign internal DOCTYPE; newDocumentBuilderFactory() forbids it outright
            SAXSource source = new SAXSource(SecureXML.newXMLReader(), new InputSource(is));
            source.setSystemId(systemId.toString());

            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            Transformer transformer = TransformerFactory.newInstance().newTransformer();
            transformer.transform(source, new StreamResult(baos));

            return baos.toString(StandardCharsets.UTF_8);
        }
        catch (Exception ex)
        {
            throw new IllegalStateException("Could not expand entities of package stylesheet <" + systemId + ">", ex);
        }
    }

    private String digest(InputStream is) throws IOException
    {
        try (DigestInputStream dis = new DigestInputStream(is, MessageDigest.getInstance("SHA-1")))
        {
            dis.transferTo(OutputStream.nullOutputStream());
            return Hex.encodeHexString(dis.getMessageDigest().digest());
        }
        catch (NoSuchAlgorithmException ex)
        {
            throw new IllegalStateException(ex);
        }
    }

    /**
     * Returns the directory holding compiled stylesheets.
     *
     * @return directory
     */
    public Path getSEFRoot()
    {
        return sefRoot;
    }

    /**
     * Returns the URI of the compiler service.
     *
     * @return compiler URI
     */
    public URI getCompilerURI()
    {
        return compilerURI;
    }

    /**
     * Returns the HTTP client.
     *
     * @return client
     */
    public Client getClient()
    {
        return client;
    }

    /**
     * Shuts down the compilation thread pool.
     */
    public void shutdown()
    {
        executor.shutdown();
    }

}
