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

import com.atomgraph.linkeddatahub.vocabulary.SIOC;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.InputStream;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.HashMap;
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

    // writeFile(File, InputStream)

    @Test
    public void testWriteFileNullFile()
    {
        assertThrows(IllegalArgumentException.class, () -> gs.writeFile((File)null, new ByteArrayInputStream(new byte[0])));
    }

    @Test
    public void testWriteFileNullInputStream(@TempDir Path tempDir)
    {
        File file = tempDir.resolve("out.bin").toFile();
        assertThrows(IllegalArgumentException.class, () -> gs.writeFile(file, (InputStream)null));
    }

    @Test
    public void testWriteFileWritesContent(@TempDir Path tempDir) throws Exception
    {
        File file = tempDir.resolve("out.bin").toFile();
        byte[] data = "hello world".getBytes(StandardCharsets.UTF_8);

        gs.writeFile(file, new ByteArrayInputStream(data));

        assertTrue(file.exists());
        assertArrayEquals(data, Files.readAllBytes(file.toPath()));
    }

    // writeFile(URI, URI, URI, InputStream)

    @Test
    public void testWriteFileByURINullURI(@TempDir Path tempDir)
    {
        assertThrows(IllegalArgumentException.class, () -> gs.writeFile(null, URI.create("http://localhost/"), tempDir.toUri(), new ByteArrayInputStream(new byte[0])));
    }

    @Test
    public void testWriteFileByURIRelativeURIRejected(@TempDir Path tempDir)
    {
        assertThrows(IllegalArgumentException.class, () -> gs.writeFile(URI.create("relative/path"), URI.create("http://localhost/"), tempDir.toUri(), new ByteArrayInputStream(new byte[0])));
    }

    @Test
    public void testWriteFileByURINullBase(@TempDir Path tempDir)
    {
        assertThrows(IllegalArgumentException.class, () -> gs.writeFile(URI.create("http://localhost/myfile"), null, tempDir.toUri(), new ByteArrayInputStream(new byte[0])));
    }

    @Test
    public void testWriteFileByURINullUploadRoot()
    {
        assertThrows(IllegalArgumentException.class, () -> gs.writeFile(URI.create("http://localhost/myfile"), URI.create("http://localhost/"), null, new ByteArrayInputStream(new byte[0])));
    }

    @Test
    public void testWriteFileByURIResolvesRelativePath(@TempDir Path tempDir) throws Exception
    {
        URI base = URI.create("http://localhost/");
        URI uri = URI.create("http://localhost/myfile");
        URI uploadRoot = tempDir.toUri(); // ends with '/'
        byte[] data = "content-addressed".getBytes(StandardCharsets.UTF_8);

        File written = gs.writeFile(uri, base, uploadRoot, new ByteArrayInputStream(data));

        assertEquals(new File(uploadRoot.resolve("myfile")), written);
        assertArrayEquals(data, Files.readAllBytes(written.toPath()));
    }

    // writeFiles(Model, Map)

    @Test
    public void testWriteFilesNullModel()
    {
        assertThrows(IllegalArgumentException.class, () -> gs.writeFiles(null, new HashMap<>()));
    }

    @Test
    public void testWriteFilesNullMap()
    {
        assertThrows(IllegalArgumentException.class, () -> gs.writeFiles(ModelFactory.createDefaultModel(), null));
    }

    @Test
    public void testWriteFilesNoFileResourcesWritesNothing()
    {
        Model model = ModelFactory.createDefaultModel();
        model.createResource("http://localhost/doc").addProperty(DCTerms.creator, model.createResource("http://localhost/agent"));

        assertEquals(0, gs.writeFiles(model, new HashMap<>()));
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
