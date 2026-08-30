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

import com.atomgraph.linkeddatahub.cli.command.admin.acl.CreateAuthorization;
import com.atomgraph.linkeddatahub.cli.command.admin.acl.CreateGroup;
import com.atomgraph.linkeddatahub.cli.command.admin.ontologies.AddClass;
import com.atomgraph.linkeddatahub.cli.command.admin.ontologies.AddConstructor;
import com.atomgraph.linkeddatahub.cli.command.admin.ontologies.AddPropertyConstraint;
import com.atomgraph.linkeddatahub.cli.command.admin.ontologies.AddRestriction;
import com.atomgraph.linkeddatahub.cli.command.admin.ontologies.CreateOntology;
import com.atomgraph.linkeddatahub.cli.command.admin.ontologies.ImportOntology;
import com.atomgraph.linkeddatahub.cli.command.content.AddObjectBlock;
import com.atomgraph.linkeddatahub.cli.command.content.AddXHTMLBlock;
import com.atomgraph.linkeddatahub.cli.command.imports.AddCSVImport;
import com.atomgraph.linkeddatahub.cli.command.imports.AddRDFImport;
import com.atomgraph.linkeddatahub.cli.vocab.ACL;
import com.atomgraph.linkeddatahub.cli.vocab.SP;
import java.io.StringReader;
import java.net.URI;
import java.util.List;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFParser;
import org.apache.jena.vocabulary.RDF;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Compares command model builders against the Turtle bodies of the original shell scripts.
 */
public class ModelBuildersTest
{

    private static final URI TARGET = URI.create("https://localhost:4443/some/");
    private static final String PREFIXES = """
        @prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy#> .
        @prefix ldh:	<https://w3id.org/atomgraph/linkeddatahub#> .
        @prefix rdf:	<http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
        @prefix dct:	<http://purl.org/dc/terms/> .
        @prefix spin:	<http://spinrdf.org/spin#> .
        @prefix sp:	<http://spinrdf.org/sp#> .
        @prefix ac:	<https://w3id.org/atomgraph/client#> .
        @prefix a:	<https://w3id.org/atomgraph/core#> .
        @prefix acl:	<http://www.w3.org/ns/auth/acl#> .
        @prefix sd:	<http://www.w3.org/ns/sparql-service-description#> .
        @prefix owl:	<http://www.w3.org/2002/07/owl#> .
        @prefix rdfs:	<http://www.w3.org/2000/01/rdf-schema#> .
        @prefix foaf:	<http://xmlns.com/foaf/0.1/> .
        """;

    static Model parse(String turtle)
    {
        Model model = ModelFactory.createDefaultModel();
        RDFParser.create().source(new StringReader(PREFIXES + turtle)).lang(Lang.TURTLE).base(TARGET.toString()).parse(model);
        return model;
    }

    static void assertIsomorphic(Model expected, Model actual)
    {
        assertTrue(actual.isIsomorphicWith(expected),
            "Expected:\n" + expected.toString() + "\nActual:\n" + actual.toString());
    }

    @Test
    public void createItem()
    {
        URI doc = URI.create("https://localhost:4443/some/my-item/");

        assertIsomorphic(parse("""
            <my-item/> a dh:Item ;
                dct:title "My item" ;
                dct:description "Desc" .
            """),
            CreateItem.buildModel(doc, "My item", "Desc"));
    }

    @Test
    public void createContainerDefaultChildrenView()
    {
        assertIsomorphic(parse("""
            <> a dh:Container ;
                dct:title "Some" ;
                rdf:_1 [ a ldh:Object ; rdf:value ldh:ChildrenView ] .
            """),
            CreateContainer.buildModel(TARGET, "Some", null, null, null));
    }

    @Test
    public void createContainerWithMode()
    {
        assertIsomorphic(parse("""
            <> a dh:Container ;
                dct:title "Some" ;
                rdf:_1 [ a ldh:Object ; rdf:value [ a ldh:View ; spin:query ldh:SelectChildren ; ac:mode <https://w3id.org/atomgraph/client#GridMode> ] ] .
            """),
            CreateContainer.buildModel(TARGET, "Some", null, null, URI.create("https://w3id.org/atomgraph/client#GridMode")));
    }

    @Test
    public void createContainerWithBlock()
    {
        assertIsomorphic(parse("""
            <> a dh:Container ;
                dct:title "Some" ;
                rdf:_1 <https://localhost:4443/some/#block> .
            """),
            CreateContainer.buildModel(TARGET, "Some", null, URI.create("https://localhost:4443/some/#block"), null));
    }

    @Test
    public void addViewWithURIAndMode()
    {
        assertIsomorphic(parse("""
            <#view> a ldh:View ;
                spin:query <https://localhost:4443/queries/q/#this> ;
                dct:title "View" ;
                ac:mode <https://w3id.org/atomgraph/client#GridMode> .
            """),
            AddView.buildModel(TARGET, "#view", URI.create("https://localhost:4443/queries/q/#this"), "View", null,
                URI.create("https://w3id.org/atomgraph/client#GridMode")));
    }

    @Test
    public void addConstructQuery()
    {
        assertIsomorphic(parse("""
            _:q a sp:Construct ;
                dct:title "Query" ;
                sp:text \"""CONSTRUCT { ?s ?p ?o } WHERE { ?s ?p ?o }\""" ;
                ldh:service <https://localhost:4443/services/s/#this> .
            """),
            AddConstruct.buildModel(TARGET, null, SP.Construct, "Query", "CONSTRUCT { ?s ?p ?o } WHERE { ?s ?p ?o }",
                URI.create("https://localhost:4443/services/s/#this"), null));
    }

    @Test
    public void createOntology()
    {
        URI doc = URI.create("https://admin.localhost:4443/ontologies/my-ont/");

        assertIsomorphic(parse("""
            @base <https://admin.localhost:4443/ontologies/my-ont/> .
            _:ontology a owl:Ontology ;
                rdfs:label "My ontology" ;
                rdfs:comment "Comment" .
            <> a dh:Item ;
                foaf:primaryTopic _:ontology ;
                dct:title "My ontology" .
            """),
            CreateOntology.buildModel(doc, null, "My ontology", "Comment"));
    }

    @Test
    public void createGroup()
    {
        URI doc = URI.create("https://admin.localhost:4443/acl/groups/editors/");

        assertIsomorphic(parse("""
            @base <https://admin.localhost:4443/acl/groups/editors/> .
            _:group a foaf:Group ;
                foaf:name "Editors" ;
                foaf:member <https://localhost:4443/acl/agents/a/#this>, <https://localhost:4443/acl/agents/b/#this> .
            <> a dh:Item ;
                foaf:primaryTopic _:group ;
                dct:title "Editors" .
            """),
            CreateGroup.buildModel(doc, null, "Editors", null,
                List.of(URI.create("https://localhost:4443/acl/agents/a/#this"), URI.create("https://localhost:4443/acl/agents/b/#this"))));
    }

    @Test
    public void createAuthorization()
    {
        URI doc = URI.create("https://admin.localhost:4443/acl/authorizations/auth/");

        assertIsomorphic(parse("""
            @base <https://admin.localhost:4443/acl/authorizations/auth/> .
            _:auth a acl:Authorization ;
                rdfs:label "Auth" ;
                acl:agent <https://localhost:4443/acl/agents/a/#this> ;
                acl:accessTo <https://localhost:4443/some/> ;
                acl:mode acl:Read, acl:Write .
            <> a dh:Item ;
                foaf:primaryTopic _:auth ;
                dct:title "Auth" .
            """),
            CreateAuthorization.buildModel(doc, null, "Auth", null,
                List.of(URI.create("https://localhost:4443/acl/agents/a/#this")), List.of(), List.of(),
                List.of(URI.create("https://localhost:4443/some/")), List.of(),
                List.of(ACL.Read, ACL.Write)));
    }

    @Test
    public void addCSVImport()
    {
        assertIsomorphic(parse("""
            _:import a ldh:CSVImport ;
                dct:title "Cities" ;
                spin:query <https://localhost:4443/some/#query> ;
                ldh:file <https://localhost:4443/uploads/abc> ;
                ldh:delimiter "," .
            """),
            AddCSVImport.buildModel(TARGET, null, "Cities", URI.create("https://localhost:4443/some/#query"),
                URI.create("https://localhost:4443/uploads/abc"), ",", null));
    }

    @Test
    public void addRDFImportWithGraph()
    {
        assertIsomorphic(parse("""
            <#import> a ldh:RDFImport ;
                dct:title "Data" ;
                ldh:file <https://localhost:4443/uploads/abc> ;
                sd:name <https://localhost:4443/graphs/g/> .
            """),
            AddRDFImport.buildModel(TARGET, "#import", "Data", URI.create("https://localhost:4443/uploads/abc"),
                null, URI.create("https://localhost:4443/graphs/g/"), null));
    }

    @Test
    public void addXHTMLBlock()
    {
        assertIsomorphic(parse("""
            <> rdf:_4 _:block .
            _:block a ldh:XHTML ;
                rdf:value "<p>Hello</p>"^^rdf:XMLLiteral .
            """),
            AddXHTMLBlock.buildModel(TARGET, RDF.li(4), null, "<p>Hello</p>", null, null));
    }

    @Test
    public void addGenericServiceWithGraphStoreAndAuth()
    {
        assertIsomorphic(parse("""
            <#service> a sd:Service ;
                dct:title "Remote" ;
                sd:endpoint <https://remote.example/sparql> ;
                sd:supportedLanguage sd:SPARQL11Query, sd:SPARQL11Update ;
                a:graphStore <https://remote.example/service> ;
                a:authUser "user" ;
                a:authPwd "pwd" .
            """),
            AddGenericService.buildModel(TARGET, "#service", "Remote", URI.create("https://remote.example/sparql"),
                URI.create("https://remote.example/service"), "user", "pwd", null));
    }

    @Test
    public void addGenericServiceMinimal()
    {
        assertIsomorphic(parse("""
            <#service> a sd:Service ;
                dct:title "Remote" ;
                sd:endpoint <https://remote.example/sparql> ;
                sd:supportedLanguage sd:SPARQL11Query, sd:SPARQL11Update .
            """),
            AddGenericService.buildModel(TARGET, "#service", "Remote", URI.create("https://remote.example/sparql"),
                null, null, null, null));
    }

    @Test
    public void addResultSetChart()
    {
        assertIsomorphic(parse("""
            <#chart> a ldh:ResultSetChart ;
                dct:title "Chart" ;
                dct:description "Desc" ;
                spin:query <https://localhost:4443/queries/select/#this> ;
                ldh:chartType <https://w3id.org/atomgraph/client#BarChart> ;
                ldh:categoryVarName "category" ;
                ldh:seriesVarName "series" .
            """),
            AddResultSetChart.buildModel(TARGET, "#chart", "Chart", URI.create("https://localhost:4443/queries/select/#this"),
                URI.create("https://w3id.org/atomgraph/client#BarChart"), "category", "series", "Desc"));
    }

    @Test
    public void addClassWithSuperClasses()
    {
        assertIsomorphic(parse("""
            <#Concept> a owl:Class ;
                rdfs:label "Concept" ;
                rdfs:comment "A concept" ;
                spin:constructor <https://localhost:4443/queries/construct/#this> ;
                spin:constraint <https://localhost:4443/constraints/#this> ;
                rdfs:subClassOf <https://localhost:4443/ns#Thing>, <https://localhost:4443/ns#Other> .
            """),
            AddClass.buildModel(TARGET, "#Concept", "Concept", "A concept",
                URI.create("https://localhost:4443/queries/construct/#this"),
                URI.create("https://localhost:4443/constraints/#this"),
                List.of(URI.create("https://localhost:4443/ns#Thing"), URI.create("https://localhost:4443/ns#Other"))));
    }

    @Test
    public void addClassMinimal()
    {
        assertIsomorphic(parse("""
            <#Concept> a owl:Class ;
                rdfs:label "Concept" .
            """),
            AddClass.buildModel(TARGET, "#Concept", "Concept", null, null, null, List.of()));
    }

    @Test
    public void addConstructor()
    {
        assertIsomorphic(parse("""
            <#constructor> a sp:Construct ;
                rdfs:label "Constructor" ;
                rdfs:comment "Builds a Concept" ;
                sp:text "CONSTRUCT { ?s ?p ?o } WHERE { ?s ?p ?o }" ;
                ldh:service <https://localhost:4443/services/remote/#this> .
            """),
            AddConstructor.buildModel(TARGET, "#constructor", SP.Construct, "Constructor",
                "CONSTRUCT { ?s ?p ?o } WHERE { ?s ?p ?o }",
                URI.create("https://localhost:4443/services/remote/#this"), "Builds a Concept"));
    }

    @Test
    public void addPropertyConstraint()
    {
        assertIsomorphic(parse("""
            <#constraint> a ldh:MissingPropertyValue ;
                rdfs:label "Title required" ;
                sp:arg1 dct:title .
            """),
            AddPropertyConstraint.buildModel(TARGET, "#constraint", "Title required",
                URI.create("http://purl.org/dc/terms/title"), null));
    }

    @Test
    public void addRestriction()
    {
        assertIsomorphic(parse("""
            <#restriction> a owl:Restriction ;
                rdfs:label "Has title" ;
                rdfs:comment "Every instance carries a title" ;
                owl:onProperty dct:title ;
                owl:allValuesFrom rdfs:Literal ;
                owl:hasValue <https://localhost:4443/values/default/> .
            """),
            AddRestriction.buildModel(TARGET, "#restriction", "Has title", "Every instance carries a title",
                URI.create("http://purl.org/dc/terms/title"),
                URI.create("http://www.w3.org/2000/01/rdf-schema#Literal"),
                URI.create("https://localhost:4443/values/default/")));
    }

    @Test
    public void addObjectBlock()
    {
        assertIsomorphic(parse("""
            <> rdf:_2 _:block .
            _:block a ldh:Object ;
                rdf:value <https://localhost:4443/other/> ;
                dct:title "Block" ;
                dct:description "Desc" ;
                ac:mode <https://w3id.org/atomgraph/client#ReadMode> .
            """),
            AddObjectBlock.buildModel(TARGET, RDF.li(2), null, URI.create("https://localhost:4443/other/"),
                "Block", "Desc", URI.create("https://w3id.org/atomgraph/client#ReadMode")));
    }

    @Test
    public void importOntologyScratch()
    {
        URI scratch = URI.create("https://admin.localhost:4443/9a1e4b7c-0d2f-4a63-8b51-6c7d8e9f0a1b/");

        assertIsomorphic(parse("""
            <https://admin.localhost:4443/9a1e4b7c-0d2f-4a63-8b51-6c7d8e9f0a1b/> a dh:Item ;
                dct:title "Import ontology scratch" .
            """),
            ImportOntology.buildScratchModel(scratch));
    }

    @Test
    public void importOntologyAnnotation()
    {
        assertIsomorphic(parse("""
            <> a owl:Ontology ;
                owl:imports <http://www.w3.org/2004/02/skos/core#> .
            """),
            ImportOntology.buildAnnotationModel(TARGET, URI.create("http://www.w3.org/2004/02/skos/core#")));
    }

}
