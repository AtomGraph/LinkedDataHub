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
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ClientStylesheetService
{

    private static final Logger log = LoggerFactory.getLogger(ClientStylesheetService.class);

    /** Path under which composed stylesheets are served, mapped to the SEF root by a Tomcat alias */
    public static final String PUBLIC_PATH = "static/xsl/sef/";

    /** Suffix of a compiled stylesheet file */
    public static final String SEF_SUFFIX = ".sef.json";

    private final Path sefRoot;
    private final URI compilerURI;
    private final Client client;
    private final String baseDigest;
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
     * @param stockSEF stream of the stylesheet built into the webapp, digested as the platform fingerprint
     * @throws IOException if the stock stylesheet cannot be read or the SEF root cannot be scanned
     */
    public ClientStylesheetService(Path sefRoot, URI compilerURI, Client client, InputStream stockSEF) throws IOException
    {
        this.sefRoot = sefRoot;
        this.compilerURI = compilerURI;
        this.client = client;
        this.baseDigest = digest(stockSEF);

        Files.createDirectories(sefRoot);
        try (var paths = Files.list(sefRoot))
        {
            paths.map(path -> path.getFileName().toString()).
                filter(name -> name.endsWith(SEF_SUFFIX)).
                map(name -> name.substring(0, name.length() - SEF_SUFFIX.length())).
                forEach(published::add);
        }

        if (log.isInfoEnabled()) log.info("Client stylesheet service ready, compiler <{}>, {} stylesheet(s) already compiled", compilerURI, published.size());
    }

    /**
     * Returns the key identifying the stylesheet composed from this platform build and these packages.
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
        JsonArrayBuilder imports = Json.createArrayBuilder();
        for (int i = 0; i < stylesheets.size(); i++)
            imports.add(Json.createObjectBuilder().
                add("name", "pkg-" + i + ".xsl").
                add("content", expandEntities(stylesheets.get(i))));

        JsonObject request = Json.createObjectBuilder().add("imports", imports).build();

        byte[] sef;
        try (Response cr = getClient().target(getCompilerURI()).request(MediaType.APPLICATION_JSON_TYPE).
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
                // newXMLReader() tolerates a benign internal DOCTYPE; newDocumentBuilderFactory() forbids it outright
                SAXSource source = new SAXSource(SecureXML.newXMLReader(), new InputSource(is));
                source.setSystemId(stylesheet.toString());

                ByteArrayOutputStream baos = new ByteArrayOutputStream();
                Transformer transformer = TransformerFactory.newInstance().newTransformer();
                transformer.transform(source, new StreamResult(baos));

                return baos.toString(StandardCharsets.UTF_8);
            }
        }
        catch (Exception ex)
        {
            throw new IllegalStateException("Could not expand entities of package stylesheet <" + stylesheet + ">", ex);
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
