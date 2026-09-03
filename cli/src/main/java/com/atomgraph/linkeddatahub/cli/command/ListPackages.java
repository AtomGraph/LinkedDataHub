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

package com.atomgraph.linkeddatahub.cli.command;

import com.atomgraph.linkeddatahub.cli.BaseCommand;
import com.atomgraph.linkeddatahub.cli.http.HttpException;
import com.atomgraph.linkeddatahub.cli.mixin.BaseMixin;
import com.atomgraph.linkeddatahub.cli.vocab.LDH;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.net.URI;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Comparator;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.RDFNode;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDFS;
import picocli.CommandLine.Command;
import picocli.CommandLine.Mixin;
import picocli.CommandLine.Option;

/**
 * Lists the packages the registry offers, marking the ones the application imports. Registry URIs
 * are not the application's own, so the catalog is read through the Linked Data proxy - the same
 * way the application settings modal reads it.
 *
 * Each package is one tab-separated line of state, URI and title, so the listing greps and cuts:
 * <code>ldh list-packages | grep ^available | cut -f2</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Command(name = "list-packages", description = "Lists the packages available in the registry, marking the ones the application imports.")
public class ListPackages extends BaseCommand
{

    /** Accepted response media type of the proxied catalog */
    private static final MediaType[] ACCEPT_RDF_XML = { com.atomgraph.core.MediaType.APPLICATION_RDF_XML_TYPE };

    @Mixin
    private BaseMixin baseMixin;

    @Option(names = "--registry", defaultValue = "https://packages.linkeddatahub.com/", paramLabel = "REGISTRY_URI",
        description = "URI of the package registry (default: ${DEFAULT-VALUE})")
    private URI registry;

    @Override
    public Integer call() throws Exception
    {
        URI base = baseMixin.require(getSpec());
        Set<String> imported = getImportedPackages(URI.create(base + "settings"));

        for (Resource pkg : getPackages(getCatalog(base)))
            print((imported.contains(pkg.getURI()) ? "installed" : "available") + "\t" + pkg.getURI() + "\t" + getTitle(pkg));

        return 0;
    }

    /**
     * Returns the URIs of the packages the application imports, read from its settings document.
     *
     * @param settings settings document URI
     * @return imported package URIs
     */
    protected Set<String> getImportedPackages(URI settings)
    {
        try (Response response = HttpException.check(settings, getClient().get(settings, ACCEPT_TURTLE)))
        {
            return response.readEntity(Model.class).
                listObjectsOfProperty(LDH.importPackage).
                toList().stream().
                filter(RDFNode::isURIResource).
                map(node -> node.asResource().getURI()).
                collect(Collectors.toSet());
        }
    }

    /**
     * Fetches the registry catalog through the Linked Data proxy.
     *
     * @param base application base URI
     * @return catalog model
     */
    protected Model getCatalog(URI base)
    {
        URI target = URI.create(base + "?uri=" + URLEncoder.encode(registry.toString(), StandardCharsets.UTF_8));

        try (Response response = HttpException.check(target, getClient().get(target, ACCEPT_RDF_XML)))
        {
            return response.readEntity(Model.class);
        }
    }

    /**
     * Returns the packages the catalog lists, ordered by URI so the listing is stable.
     *
     * @param catalog catalog model
     * @return package resources
     */
    protected static List<Resource> getPackages(Model catalog)
    {
        return catalog.listObjectsOfProperty(RDFS.member).
            toList().stream().
            filter(RDFNode::isURIResource).
            map(RDFNode::asResource).
            distinct().
            sorted(Comparator.comparing(Resource::getURI)).
            toList();
    }

    /**
     * Returns the title of a package, falling back to its label and then to the empty string:
     * the catalog describes its members loosely enough that neither is guaranteed.
     *
     * @param pkg package resource
     * @return title
     */
    protected static String getTitle(Resource pkg)
    {
        if (pkg.hasProperty(DCTerms.title)) return pkg.getProperty(DCTerms.title).getString();
        if (pkg.hasProperty(RDFS.label)) return pkg.getProperty(RDFS.label).getString();

        return "";
    }

}
