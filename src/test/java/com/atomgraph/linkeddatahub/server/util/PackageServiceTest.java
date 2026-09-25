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

import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.linkeddatahub.dataspaces.model.impl.PackageImpl;
import jakarta.ws.rs.core.UriBuilder;
import java.net.URI;
import java.util.HashSet;
import java.util.List;
import org.apache.jena.enhanced.EnhGraph;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.RDF;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.when;

/**
 * Tests the traversal from an application's <code>ldh:import</code> set to the artifacts its packages
 * deliver. Package descriptions are stubbed: resolving one is I/O, and what these cover is the traversal
 * around it - ordering, and what happens to a package that does not resolve or ships only one artifact.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
public class PackageServiceTest
{

    private static final URI A_XSL_URI = URI.create("https://packages.example.org/a/a.xsl");
    private static final URI A_NS_URI = URI.create("https://packages.example.org/a/ns.ttl#");

    @Mock private com.atomgraph.linkeddatahub.dataspaces.model.Dataspace application;
    @Mock private com.atomgraph.linkeddatahub.dataspaces.model.EndUserDataspace endUserApp;
    @Mock private com.atomgraph.linkeddatahub.dataspaces.model.AdminDataspace adminApp;

    private Model model;
    private PackageService service;

    @BeforeEach
    public void setUp()
    {
        model = ModelFactory.createDefaultModel();
        service = new PackageService(null); // no system: every test stubs the resolution step
    }

    @Test
    public void testGetPackageURIsOrderedByURI()
    {
        Resource pkgB = model.createResource("https://packages.example.org/b#this");
        Resource pkgA = model.createResource("https://packages.example.org/a#this");
        when(application.getImportedPackages()).thenReturn(new HashSet<>(List.of(pkgB, pkgA)));

        assertEquals(List.of(URI.create(pkgA.getURI()), URI.create(pkgB.getURI())), service.getPackageURIs(application));
    }

    @Test
    public void testGetStylesheetsSkipsUnresolvedAndOntologyOnlyPackages()
    {
        URI pkgA = URI.create("https://packages.example.org/a#this");
        URI pkgB = URI.create("https://packages.example.org/b#this");
        URI pkgC = URI.create("https://packages.example.org/c#this");
        model.createResource(pkgA.toString()).addProperty(AC.stylesheet, model.createResource(A_XSL_URI.toString()));
        model.createResource(pkgC.toString()); // ontology-only: no ac:stylesheet
        when(application.getImportedPackages()).thenReturn(new HashSet<>(List.of(
            model.createResource(pkgA.toString()), model.createResource(pkgB.toString()), model.createResource(pkgC.toString()))));

        PackageService spied = spy(service);
        doReturn(asPackage(pkgA)).when(spied).getPackage(pkgA.toString());
        doReturn(null).when(spied).getPackage(pkgB.toString()); // description could not be resolved
        doReturn(asPackage(pkgC)).when(spied).getPackage(pkgC.toString());

        assertEquals(List.of(A_XSL_URI), spied.getStylesheets(application));
    }

    @Test
    public void testGetOntologiesSkipsUnresolvedAndStylesheetOnlyPackages()
    {
        URI pkgA = URI.create("https://packages.example.org/a#this");
        URI pkgB = URI.create("https://packages.example.org/b#this");
        model.createResource(pkgA.toString()).addProperty(com.atomgraph.linkeddatahub.vocabulary.LDS.ontology, model.createResource(A_NS_URI.toString()));
        model.createResource(pkgB.toString()); // stylesheet-only: no lds:ontology
        when(application.getImportedPackages()).thenReturn(new HashSet<>(List.of(
            model.createResource(pkgA.toString()), model.createResource(pkgB.toString()))));

        PackageService spied = spy(service);
        doReturn(asPackage(pkgA)).when(spied).getPackage(pkgA.toString());
        doReturn(asPackage(pkgB)).when(spied).getPackage(pkgB.toString());

        assertEquals(List.of(A_NS_URI), spied.getOntologies(application));
    }

    /**
     * The document URI is derived from the package URI's path, so a materialized copy is recognizable in
     * the ontologies container rather than being named by a digest.
     */
    @Test
    public void testDocumentURIDerivedFromPackagePath()
    {
        when(endUserApp.getAdminDataspace()).thenReturn(adminApp);
        when(adminApp.getUriBuilder()).thenReturn(UriBuilder.fromUri("https://admin.example.org/"));

        URI docURI = service.getDocumentURI(endUserApp, asPackage(URI.create("https://packages.example.org/editor/taxonomy/#this")));

        assertEquals(URI.create("https://admin.example.org/ontologies/editor-taxonomy/"), docURI);
    }

    @Test
    public void testDocumentURINullWithoutAdminApplication()
    {
        when(endUserApp.getAdminDataspace()).thenReturn(null);

        assertNull(service.getDocumentURI(endUserApp, asPackage(URI.create("https://packages.example.org/a#this"))));
    }

    /**
     * A package URI with no usable path still yields a stable document URI, so two packages cannot collide
     * on an empty slug.
     */
    @Test
    public void testDocumentURIFallsBackToUUIDSlug()
    {
        when(endUserApp.getAdminDataspace()).thenReturn(adminApp);
        when(adminApp.getUriBuilder()).thenReturn(UriBuilder.fromUri("https://admin.example.org/"));

        URI docURI = service.getDocumentURI(endUserApp, asPackage(URI.create("https://packages.example.org/#this")));

        assertTrue(docURI.toString().startsWith("https://admin.example.org/ontologies/"), docURI.toString());
        assertTrue(docURI.toString().endsWith("/"), docURI.toString());
    }

    private com.atomgraph.linkeddatahub.dataspaces.model.Package asPackage(URI uri)
    {
        return new PackageImpl(model.createResource(uri.toString()).asNode(), (EnhGraph)model);
    }

}
