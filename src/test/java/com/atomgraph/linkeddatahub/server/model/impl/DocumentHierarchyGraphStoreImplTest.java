/**
 *  Copyright 2025 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.server.model.impl;

import com.atomgraph.linkeddatahub.model.CSVImport;
import com.atomgraph.linkeddatahub.model.RDFImport;
import com.atomgraph.linkeddatahub.model.impl.CSVImportImpl;
import com.atomgraph.linkeddatahub.model.impl.RDFImportImpl;
import com.atomgraph.linkeddatahub.vocabulary.LDH;
import com.atomgraph.linkeddatahub.vocabulary.PROV;
import com.atomgraph.linkeddatahub.vocabulary.SIOC;
import com.atomgraph.spinrdf.vocabulary.SPIN;
import org.apache.jena.enhanced.BuiltinPersonalities;
import org.apache.jena.vocabulary.RDF;
import java.io.File;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.HashMap;
import java.util.List;
import java.util.Set;
import org.apache.jena.datatypes.xsd.XSDDateTime;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.DCTerms;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.CALLS_REAL_METHODS;
import static org.mockito.Mockito.mock;

/**
 * Unit tests for the stateless logic of {@link DocumentHierarchyGraphStoreImpl}.
 * <p>
 * The class has a single heavyweight {@code @Inject} constructor that wires the JAX-RS request
 * context and an HTTP-backed {@code GraphStoreClient}, so it cannot be instantiated directly in a
 * unit test. The methods exercised here ({@code getChangedResources}, {@code getLastModified}, and
 * the {@code writeFile}/{@code writeFiles} guards and file I/O) read no instance state, so we obtain
 * an instance via Mockito's {@code CALLS_REAL_METHODS} (which skips the constructor) and invoke the
 * real method bodies.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class DocumentHierarchyGraphStoreImplTest
{

    static
    {
        org.apache.jena.sys.JenaSystem.init(); // before BuiltinPersonalities, whose static initializer otherwise starts Jena out of order
        BuiltinPersonalities.model.add(CSVImport.class, CSVImportImpl.factory);
        BuiltinPersonalities.model.add(RDFImport.class, RDFImportImpl.factory);
    }

    private final DocumentHierarchyGraphStoreImpl gs = mock(DocumentHierarchyGraphStoreImpl.class, CALLS_REAL_METHODS);

    // getChangedResources()

    @Test
    public void testChangedResourcesNullBefore()
    {
        assertThrows(IllegalArgumentException.class, () -> gs.getChangedResources(null, ModelFactory.createDefaultModel()));
    }

    @Test
    public void testChangedResourcesNullAfter()
    {
        assertThrows(IllegalArgumentException.class, () -> gs.getChangedResources(ModelFactory.createDefaultModel(), null));
    }

    @Test
    public void testChangedResourcesDetectsAddedSubject()
    {
        Model before = ModelFactory.createDefaultModel();
        Model after = ModelFactory.createDefaultModel();
        Resource added = after.createResource("http://localhost/added");
        added.addProperty(SIOC.HAS_PARENT, after.createResource("http://localhost/"));

        Set<Resource> changed = gs.getChangedResources(before, after);
        assertTrue(changed.contains(added));
    }

    @Test
    public void testChangedResourcesDetectsRemovedSubject()
    {
        Model before = ModelFactory.createDefaultModel();
        Resource removed = before.createResource("http://localhost/removed");
        removed.addProperty(SIOC.HAS_PARENT, before.createResource("http://localhost/"));
        Model after = ModelFactory.createDefaultModel();

        Set<Resource> changed = gs.getChangedResources(before, after);
        assertTrue(changed.contains(removed));
    }

    @Test
    public void testChangedResourcesIdenticalModelsAreEmpty()
    {
        Model before = ModelFactory.createDefaultModel();
        before.createResource("http://localhost/doc").addProperty(DCTerms.creator, before.createResource("http://localhost/agent"));
        Model after = ModelFactory.createDefaultModel().add(before);

        assertTrue(gs.getChangedResources(before, after).isEmpty());
    }

    // getLastModified(Resource)

    @Test
    public void testLastModifiedNullResource()
    {
        assertThrows(IllegalArgumentException.class, () -> gs.getLastModified((Resource)null));
    }

    @Test
    public void testLastModifiedReturnsNullWhenNoDates()
    {
        Model model = ModelFactory.createDefaultModel();
        Resource resource = model.createResource("http://localhost/doc");
        assertNull(gs.getLastModified(resource));
    }

    @Test
    public void testLastModifiedReturnsMaxOfCreatedAndModified()
    {
        Model model = ModelFactory.createDefaultModel();
        Calendar createdCal = new GregorianCalendar(2020, Calendar.JANUARY, 1, 0, 0, 0);
        Calendar modifiedCal = new GregorianCalendar(2021, Calendar.JANUARY, 1, 0, 0, 0);
        Resource resource = model.createResource("http://localhost/doc").
            addProperty(DCTerms.created, model.createTypedLiteral(createdCal)).
            addProperty(DCTerms.modified, model.createTypedLiteral(modifiedCal));

        // expected value is the later (modified) date, round-tripped through the same XSDDateTime path the method uses
        Date expected = ((XSDDateTime)model.createTypedLiteral(modifiedCal).getValue()).asCalendar().getTime();
        assertEquals(expected, gs.getLastModified(resource));
    }

    @Test
    public void testLastModifiedIgnoresNonDateTimeLiterals()
    {
        Model model = ModelFactory.createDefaultModel();
        Resource resource = model.createResource("http://localhost/doc").
            addProperty(DCTerms.modified, "not a date"); // plain string literal, not xsd:dateTime
        assertNull(gs.getLastModified(resource));
    }

    @Test
    public void testLastModifiedNeverLaterThanNow()
    {
        Model model = ModelFactory.createDefaultModel();
        Calendar future = new GregorianCalendar(2099, Calendar.JANUARY, 1, 0, 0, 0);
        Resource resource = model.createResource("http://localhost/doc").
            addProperty(DCTerms.modified, model.createTypedLiteral(future));

        Date before = new Date();
        Date lastModified = gs.getLastModified(resource);
        Date after = new Date();

        assertFalse(lastModified.before(before), "a future date is clamped to the time of the response");
        assertFalse(lastModified.after(after), "Last-Modified must not be later than now (RFC 9110 8.8.2.1)");
    }

    // stampModified(URI, Model, Model)

    private static final URI DOC = URI.create("http://localhost/doc/");

    private static Model dated(Calendar created, Calendar modified)
    {
        Model model = ModelFactory.createDefaultModel();
        Resource doc = model.createResource(DOC.toString()).addProperty(DCTerms.title, "Doc");
        if (created != null) doc.addProperty(DCTerms.created, model.createTypedLiteral(created));
        if (modified != null) doc.addProperty(DCTerms.modified, model.createTypedLiteral(modified));
        return model;
    }

    @Test
    public void testStampModifiedStampsAChange()
    {
        Calendar created = new GregorianCalendar(2020, Calendar.JANUARY, 1, 0, 0, 0);
        Model before = dated(created, null);
        Model after = ModelFactory.createDefaultModel().add(before);
        after.createResource(DOC.toString()).addProperty(DCTerms.description, "changed");

        Date start = new Date(System.currentTimeMillis() - 1000);
        DocumentHierarchyGraphStoreImpl.stampModified(DOC, before, after);

        Resource doc = after.createResource(DOC.toString());
        assertEquals(1, doc.listProperties(DCTerms.modified).toList().size());
        Date modified = ((XSDDateTime)doc.getProperty(DCTerms.modified).getLiteral().getValue()).asCalendar().getTime();
        assertFalse(modified.before(start), "the change is stamped with the current time");
        assertTrue(doc.hasProperty(DCTerms.created, after.createTypedLiteral(created)), "the creation date is kept");
    }

    @Test
    public void testStampModifiedRestoresServerManagedDates()
    {
        Calendar created = new GregorianCalendar(2020, Calendar.JANUARY, 1, 0, 0, 0);
        Calendar future = new GregorianCalendar(2099, Calendar.JANUARY, 1, 0, 0, 0);
        Model before = dated(created, null);
        // what INSERT { <doc> dct:created ?future ; dct:modified ?future } leaves behind
        Model after = dated(future, future);

        DocumentHierarchyGraphStoreImpl.stampModified(DOC, before, after);

        Resource doc = after.createResource(DOC.toString());
        assertEquals(1, doc.listProperties(DCTerms.created).toList().size());
        assertTrue(doc.hasProperty(DCTerms.created, after.createTypedLiteral(created)), "the inserted creation date is replaced by the stored one");
        assertFalse(doc.hasProperty(DCTerms.modified, after.createTypedLiteral(future)), "the inserted modification date is not kept");
    }

    @Test
    public void testStampModifiedLeavesANoOpUnchanged()
    {
        Calendar created = new GregorianCalendar(2020, Calendar.JANUARY, 1, 0, 0, 0);
        Calendar modified = new GregorianCalendar(2021, Calendar.JANUARY, 1, 0, 0, 0);
        Model before = dated(created, modified);
        Model after = ModelFactory.createDefaultModel().add(before);

        DocumentHierarchyGraphStoreImpl.stampModified(DOC, before, after);

        assertTrue(after.isIsomorphicWith(before), "an update that changed nothing is not a modification");
    }

    @Test
    public void testStampModifiedIgnoresADateOnlyChange()
    {
        Calendar created = new GregorianCalendar(2020, Calendar.JANUARY, 1, 0, 0, 0);
        Calendar modified = new GregorianCalendar(2021, Calendar.JANUARY, 1, 0, 0, 0);
        Model before = dated(created, modified);
        Model after = dated(created, new GregorianCalendar(2099, Calendar.JANUARY, 1, 0, 0, 0));

        DocumentHierarchyGraphStoreImpl.stampModified(DOC, before, after);

        assertTrue(after.isIsomorphicWith(before), "changing only the server-managed dates changes nothing");
    }

    // getChangedImports(Model, Model)

    private static final String IMPORT = "http://localhost/imports/csv/#import";

    private static Model csvImport(String title, String file)
    {
        Model model = ModelFactory.createDefaultModel();
        model.createResource(IMPORT).
            addProperty(RDF.type, LDH.CSVImport).
            addProperty(DCTerms.title, title).
            addProperty(SPIN.query, model.createResource("http://localhost/queries/csv/#this")).
            addProperty(LDH.file, model.createResource(file)).
            addProperty(LDH.delimiter, ",");
        return model;
    }

    @Test
    public void testChangedImportsOnCreate()
    {
        Model model = csvImport("Import", "http://localhost/uploads/a");
        assertEquals(List.of(model.createResource(IMPORT)), DocumentHierarchyGraphStoreImpl.getChangedImports(model, null), "a new document's imports all run");
    }

    @Test
    public void testChangedImportsSkipsARetitle()
    {
        Model existing = csvImport("Import", "http://localhost/uploads/a");
        // what the import appended to its document when it ran
        existing.createResource(IMPORT).addProperty(PROV.startedAtTime, existing.createTypedLiteral(new GregorianCalendar()));
        Model model = csvImport("Retitled", "http://localhost/uploads/a");

        assertTrue(DocumentHierarchyGraphStoreImpl.getChangedImports(model, existing).isEmpty(), "a title and the import's own provenance do not define it");
    }

    @Test
    public void testChangedImportsSkipsAnUnchangedImport()
    {
        assertTrue(DocumentHierarchyGraphStoreImpl.getChangedImports(csvImport("Import", "http://localhost/uploads/a"), csvImport("Import", "http://localhost/uploads/a")).isEmpty());
    }

    @Test
    public void testChangedImportsRunsARedefinedImport()
    {
        Model model = csvImport("Import", "http://localhost/uploads/b");
        assertEquals(List.of(model.createResource(IMPORT)), DocumentHierarchyGraphStoreImpl.getChangedImports(model, csvImport("Import", "http://localhost/uploads/a")), "another source is another import");
    }

    @Test
    public void testChangedImportsRunsAnImportNewToTheDocument()
    {
        Model existing = ModelFactory.createDefaultModel();
        existing.createResource("http://localhost/imports/csv/").addProperty(DCTerms.title, "Imports");
        Model model = csvImport("Import", "http://localhost/uploads/a");
        assertEquals(1, DocumentHierarchyGraphStoreImpl.getChangedImports(model, existing).size());
    }

    @Test
    public void testChangedImportsJudgesAnAppendByTheResult()
    {
        // a POST that only retitles the import: the payload alone lacks its definition, the document it results in does not
        Model existing = csvImport("Import", "http://localhost/uploads/a");
        Model payload = ModelFactory.createDefaultModel();
        payload.createResource(IMPORT).addProperty(RDF.type, LDH.CSVImport).addProperty(DCTerms.description, "appended");

        assertTrue(DocumentHierarchyGraphStoreImpl.getChangedImports(ModelFactory.createUnion(existing, payload), existing).isEmpty());
    }

    @Test
    public void testChangedImportsIgnoresNonImports()
    {
        Model model = ModelFactory.createDefaultModel();
        model.createResource("http://localhost/doc/").addProperty(DCTerms.title, "Doc");
        assertTrue(DocumentHierarchyGraphStoreImpl.getChangedImports(model, null).isEmpty());
    }

    // getLastModified(Model, URI)

    @Test
    public void testLastModifiedByGraphURIReturnsNullForNullURI()
    {
        assertNull(gs.getLastModified(ModelFactory.createDefaultModel(), null));
    }

    @Test
    public void testLastModifiedByGraphURI()
    {
        Model model = ModelFactory.createDefaultModel();
        Calendar cal = new GregorianCalendar(2022, Calendar.MARCH, 15, 12, 0, 0);
        URI graphURI = URI.create("http://localhost/doc");
        model.createResource(graphURI.toString()).addProperty(DCTerms.modified, model.createTypedLiteral(cal));

        Date expected = ((XSDDateTime)model.createTypedLiteral(cal).getValue()).asCalendar().getTime();
        assertEquals(expected, gs.getLastModified(model, graphURI));
    }

    // getFile(URI, URI, URI)

    @Test
    public void testGetFileNullURI(@TempDir Path tempDir)
    {
        assertThrows(IllegalArgumentException.class, () -> gs.getFile(null, URI.create("http://localhost/"), tempDir.toUri()));
    }

    @Test
    public void testGetFileRelativeURIRejected(@TempDir Path tempDir)
    {
        assertThrows(IllegalArgumentException.class, () -> gs.getFile(URI.create("relative/path"), URI.create("http://localhost/"), tempDir.toUri()));
    }

    @Test
    public void testGetFileNullBase(@TempDir Path tempDir)
    {
        assertThrows(IllegalArgumentException.class, () -> gs.getFile(URI.create("http://localhost/myfile"), null, tempDir.toUri()));
    }

    @Test
    public void testGetFileNullUploadRoot()
    {
        assertThrows(IllegalArgumentException.class, () -> gs.getFile(URI.create("http://localhost/myfile"), URI.create("http://localhost/"), null));
    }

    @Test
    public void testGetFileResolvesRelativePath(@TempDir Path tempDir)
    {
        URI uploadRoot = tempDir.toUri(); // ends with '/'

        assertEquals(new File(uploadRoot.resolve("myfile")), gs.getFile(URI.create("http://localhost/myfile"), URI.create("http://localhost/"), uploadRoot));
    }

    // stageFiles(Model, Map)

    @Test
    public void testStageFilesNullModel()
    {
        assertThrows(IllegalArgumentException.class, () -> gs.stageFiles(null, new HashMap<>()));
    }

    @Test
    public void testStageFilesNullMap()
    {
        assertThrows(IllegalArgumentException.class, () -> gs.stageFiles(ModelFactory.createDefaultModel(), null));
    }

    @Test
    public void testStageFilesNoFileResourcesStagesNothing()
    {
        Model model = ModelFactory.createDefaultModel();
        model.createResource("http://localhost/doc").addProperty(DCTerms.creator, model.createResource("http://localhost/agent"));

        assertTrue(gs.stageFiles(model, new HashMap<>()).isEmpty());
    }

    // commitFiles(List), discardFiles(List)

    @Test
    public void testCommitFilesMovesTheStagedFile(@TempDir Path tempDir) throws Exception
    {
        byte[] data = "content-addressed".getBytes(StandardCharsets.UTF_8);
        Path temp = Files.write(tempDir.resolve(".upload-1.tmp"), data);
        Path target = tempDir.resolve("sha1");

        gs.commitFiles(List.of(new DocumentHierarchyGraphStoreImpl.StagedFile(temp, target)));

        assertFalse(Files.exists(temp));
        assertArrayEquals(data, Files.readAllBytes(target));
    }

    @Test
    public void testCommitFilesKeepsAnExistingTarget(@TempDir Path tempDir) throws Exception
    {
        byte[] data = "content-addressed".getBytes(StandardCharsets.UTF_8);
        Path temp = Files.write(tempDir.resolve(".upload-1.tmp"), data);
        Path target = Files.write(tempDir.resolve("sha1"), data);
        long modified = Files.getLastModifiedTime(target).toMillis();

        gs.commitFiles(List.of(new DocumentHierarchyGraphStoreImpl.StagedFile(temp, target)));

        assertFalse(Files.exists(temp));
        assertEquals(modified, Files.getLastModifiedTime(target).toMillis(), "an existing content-addressed file is not rewritten");
    }

    @Test
    public void testDiscardFilesLeavesNothingBehind(@TempDir Path tempDir) throws Exception
    {
        Path temp = Files.write(tempDir.resolve(".upload-1.tmp"), new byte[] { 1 });
        Path target = tempDir.resolve("sha1");

        gs.discardFiles(List.of(new DocumentHierarchyGraphStoreImpl.StagedFile(temp, target)));

        assertFalse(Files.exists(temp));
        assertFalse(Files.exists(target));
    }

    @Test
    public void testDiscardFilesAfterCommitIsHarmless(@TempDir Path tempDir) throws Exception
    {
        Path temp = Files.write(tempDir.resolve(".upload-1.tmp"), new byte[] { 1 });
        Path target = tempDir.resolve("sha1");
        List<DocumentHierarchyGraphStoreImpl.StagedFile> staged = List.of(new DocumentHierarchyGraphStoreImpl.StagedFile(temp, target));

        gs.commitFiles(staged);
        gs.discardFiles(staged);

        assertTrue(Files.exists(target), "discarding after a commit must not delete the committed file");
    }

    @Test
    public void testChangedResourcesUnchangedDoesNotContainSubject()
    {
        Model before = ModelFactory.createDefaultModel();
        Resource subject = before.createResource("http://localhost/doc");
        subject.addProperty(DCTerms.creator, before.createResource("http://localhost/agent"));
        Model after = ModelFactory.createDefaultModel().add(before);

        assertFalse(gs.getChangedResources(before, after).contains(subject));
    }

}
