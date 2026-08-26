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
import com.atomgraph.linkeddatahub.cli.mixin.CertAuthMixin;
import com.atomgraph.linkeddatahub.cli.mixin.ProxyMixin;
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.core.MediaType;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.util.concurrent.Callable;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFLanguages;
import org.apache.jena.riot.RDFParser;
import picocli.CommandLine.Mixin;
import picocli.CommandLine.Model.CommandSpec;
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
            client = new LDHClient(ClientFactory.createClient(getCertAuth().getCertFile(), getCertAuth().getCertPassword()),
                new MediaTypes(), getEffectiveProxy());
        }

        return client;
    }

    /**
     * Returns the proxy URI applied to requests. Commands that target the admin application
     * override this to convert the proxy to the admin subdomain.
     *
     * @return proxy URI or null
     */
    protected URI getEffectiveProxy()
    {
        return getProxyMixin().getProxy();
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
        HttpException.check(target, client.post(target, Entity.entity(model, TEXT_TURTLE_TYPE), ACCEPT_TURTLE)).close();
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
        HttpException.check(target, client.put(target, Entity.entity(model, TEXT_TURTLE_TYPE), ACCEPT_TURTLE)).close();
    }

    /**
     * Returns the subject resource for an appended description: the <code>--uri</code> value
     * resolved against the target document URI, or a fresh blank node when not given.
     *
     * @param model model to create the resource in
     * @param target target document URI
     * @param uri <code>--uri</code> option value (absolute or relative, can be null)
     * @return subject resource
     */
    protected static Resource createSubject(Model model, URI target, String uri)
    {
        return uri != null ? model.createResource(target.resolve(uri).toString()) : model.createResource();
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
