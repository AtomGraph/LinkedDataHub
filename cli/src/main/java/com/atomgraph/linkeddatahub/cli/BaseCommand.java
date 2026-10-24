/*
 * Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.atomgraph.linkeddatahub.cli;

import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.cli.http.ClientFactory;
import com.atomgraph.linkeddatahub.cli.http.HttpException;
import com.atomgraph.linkeddatahub.cli.http.LDHClient;
import com.atomgraph.linkeddatahub.cli.http.Links;
import com.atomgraph.linkeddatahub.cli.mixin.CertAuthMixin;
import com.atomgraph.linkeddatahub.cli.mixin.ProxyMixin;
import com.atomgraph.linkeddatahub.rdf.vocabulary.LDS;
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.concurrent.Callable;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFLanguages;
import org.apache.jena.riot.RDFParser;
import picocli.CommandLine.Mixin;
import picocli.CommandLine.Model.CommandSpec;
import picocli.CommandLine.Option;
import picocli.CommandLine.ParameterException;
import picocli.CommandLine.Spec;

/**
 * Base class for all commands: WebID certificate authentication, proxy handling
 * and shared RDF/HTTP helpers.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public abstract class BaseCommand implements Callable<Integer>
{

    /** Accepted response media type used by the scripts (<code>Accept: text/turtle</code>) */
    protected static final MediaType[] ACCEPT_TURTLE = { com.atomgraph.core.MediaType.TEXT_TURTLE_TYPE };
    /** Accepted response media type for content block sequence scanning */
    protected static final MediaType[] ACCEPT_NTRIPLES = { com.atomgraph.core.MediaType.APPLICATION_NTRIPLES_TYPE };
    /** Turtle request body media type */
    protected static final MediaType TEXT_TURTLE_TYPE = com.atomgraph.core.MediaType.TEXT_TURTLE_TYPE;

    @Option(names = { "-h", "--help" }, usageHelp = true, description = "Show this help message and exit.")
    private boolean help;

    @Spec
    private CommandSpec spec;

    @Mixin
    private CertAuthMixin certAuth;

    @Mixin
    private ProxyMixin proxyMixin;

    private LDHClient client;

    /**
     * Returns the lazily-built authenticated client.
     *
     * @return client instance
     */
    protected LDHClient getClient()
    {
        if (client == null)
        {
            getCertAuth().validate(getSpec());
            client = new LDHClient(ClientFactory.createClient(getCertAuth().getCertFile(), getCertAuth().getCertPassword(), getProxyMixin().getProxy()),
                new MediaTypes());
        }

        return client;
    }

    /**
     * Returns the targets of a resource's <code>Link</code> response headers with the given relation, read with HEAD.
     *
     * @param uri resource URI
     * @param rel relation URI
     * @return link targets, possibly empty
     */
    protected List<URI> getLinkTargets(URI uri, String rel)
    {
        try (Response response = HttpException.check(uri, getClient().head(uri, ACCEPT_TURTLE)))
        {
            return Links.targets(response, rel);
        }
    }

    /**
     * Returns the base URI of the administration application of a dataspace.
     * Both applications advertise it as <code>lds:admin</code>, the administration one pointing at itself, so callers
     * may pass either base. A base without that link is served by a platform that predates it, and is refused rather
     * than guessed at: an admin write sent to the end-user application would fail as unauthorized.
     *
     * @param base end-user or admin base URI
     * @return admin base URI
     * @throws IllegalStateException if the base advertises no <code>lds:admin</code> link
     */
    protected URI getAdminBase(URI base)
    {
        List<URI> admin = getLinkTargets(base, LDS.admin.getURI());
        if (admin.isEmpty()) throw new IllegalStateException("<" + base + "> advertises no lds:admin link: LinkedDataHub serves it on end-user bases since 6.2.0 and on admin bases since 6.2.1");

        return admin.get(0);
    }

    /**
     * POSTs a model to a document, failing on error status.
     *
     * @param client client instance
     * @param target document URI
     * @param model appended model
     */
    protected static void post(LDHClient client, URI target, Model model)
    {
        HttpException.checkWrite(target, client.post(target, Entity.entity(model, TEXT_TURTLE_TYPE), ACCEPT_TURTLE)).close();
    }

    /**
     * PUTs a model as a document, failing on error status.
     *
     * @param client client instance
     * @param target document URI
     * @param model document model
     */
    protected static void put(LDHClient client, URI target, Model model)
    {
        HttpException.checkWrite(target, client.put(target, Entity.entity(model, TEXT_TURTLE_TYPE), ACCEPT_TURTLE)).close();
    }

    /**
     * Parses an RDF stream into a model, resolving relative URIs against the base URI
     * (the equivalent of the scripts' <code>turtle --base</code> piping).
     *
     * @param contentType RDF media type
     * @param base base URI
     * @param in RDF input stream
     * @return parsed model
     */
    protected Model readModel(String contentType, URI base, InputStream in)
    {
        Lang lang = RDFLanguages.contentTypeToLang(contentType);
        if (lang == null) throw new ParameterException(getSpec().commandLine(), "Unsupported RDF media type: '" + contentType + "'");

        Model model = ModelFactory.createDefaultModel();
        RDFParser.create().source(in).lang(lang).base(base.toString()).parse(model);
        return model;
    }

    /**
     * Reads a model from a file, resolving relative URIs against the given base URI.
     *
     * @param contentType RDF media type
     * @param base base URI
     * @param file RDF file
     * @return parsed model
     * @throws IOException read error
     */
    protected Model readModel(String contentType, URI base, Path file) throws IOException
    {
        if (!Files.isReadable(file)) throw new ParameterException(getSpec().commandLine(), "Cannot read RDF file: '" + file + "'");

        try (InputStream in = Files.newInputStream(file))
        {
            return readModel(contentType, base, in);
        }
    }

    /**
     * Resolves the RDF media type of the input: the explicit option when given, otherwise the type
     * the file extension implies. Reading standard input leaves no extension to go by, so there the
     * option is required.
     *
     * @param contentType explicit media type (optional)
     * @param file input file (optional)
     * @return media type
     */
    protected String resolveContentType(String contentType, Path file)
    {
        if (contentType != null) return contentType;
        if (file == null) throw new ParameterException(getSpec().commandLine(), "Missing required option: '--content-type=MEDIA_TYPE' (required when reading from stdin)");

        Lang lang = RDFLanguages.filenameToLang(file.getFileName().toString());
        if (lang == null) throw new ParameterException(getSpec().commandLine(), "Cannot tell the RDF syntax from the file name '" + file.getFileName() + "': pass -t/--content-type");

        return lang.getContentType().getContentTypeStr();
    }

    /**
     * Streams a response body to standard output unmodified.
     *
     * @param response response with the body to stream
     * @throws IOException stream error
     */
    protected static void printBody(jakarta.ws.rs.core.Response response) throws IOException
    {
        try (response; InputStream is = response.readEntity(InputStream.class))
        {
            is.transferTo(System.out);
            System.out.flush();
        }
    }

    /**
     * Prints a line to standard output. Command results (created document URLs) go through here.
     *
     * @param value printed value
     */
    protected void print(Object value)
    {
        getSpec().commandLine().getOut().println(value);
    }

    /**
     * Prints a line to standard error. Diagnostics and progress go through here.
     *
     * @param value printed value
     */
    protected void printErr(Object value)
    {
        getSpec().commandLine().getErr().println(value);
    }

    /**
     * Returns the command spec.
     *
     * @return command spec
     */
    protected CommandSpec getSpec()
    {
        return spec;
    }

    /**
     * Returns the certificate options.
     *
     * @return certificate mixin
     */
    protected CertAuthMixin getCertAuth()
    {
        return certAuth;
    }

    /**
     * Returns the proxy options.
     *
     * @return proxy mixin
     */
    protected ProxyMixin getProxyMixin()
    {
        return proxyMixin;
    }

}
