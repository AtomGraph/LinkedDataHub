/**
 *  Copyright 2020 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.imports;

import com.atomgraph.client.util.DataManager;
import com.atomgraph.linkeddatahub.imports.csv.stream.CSVStreamRDFOutput;
import com.atomgraph.linkeddatahub.imports.csv.stream.CSVStreamRDFOutputWriter;
import com.atomgraph.linkeddatahub.imports.csv.stream.ClientResponseSupplier;
import com.atomgraph.linkeddatahub.imports.stream.StreamRDFOutputWriter;
import static com.atomgraph.linkeddatahub.listener.ImportListener.CSV_MEDIA_TYPES;
import static com.atomgraph.linkeddatahub.listener.ImportListener.RDF_MEDIA_TYPES;
import com.atomgraph.linkeddatahub.model.CSVImport;
import com.atomgraph.linkeddatahub.model.Import;
import com.atomgraph.linkeddatahub.model.RDFImport;
import com.atomgraph.linkeddatahub.server.exception.ImportException;
import com.atomgraph.linkeddatahub.vocabulary.PROV;
import com.atomgraph.linkeddatahub.vocabulary.VoID;
import com.atomgraph.server.vocabulary.HTTP;
import com.atomgraph.spinrdf.vocabulary.SPIN;
import com.univocity.parsers.common.TextParsingException;
import java.util.Calendar;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionException;
import java.util.function.Consumer;
import java.util.function.Function;
import java.util.function.Supplier;
import javax.ws.rs.core.Response;
import org.apache.jena.query.DatasetAccessor;
import org.apache.jena.query.ParameterizedSparqlString;
import org.apache.jena.query.QuerySolutionMap;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Property;
import org.apache.jena.rdf.model.RDFNode;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.util.ResourceUtils;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author Martynas Jusevičius <martynas@atomgraph.com>
 */
public class ImportRunner implements Runnable
{

    private static final Logger log = LoggerFactory.getLogger(ImportRunner.class);

    private final BlockingQueue<ImportMetadata> queue;
    
    public ImportRunner(BlockingQueue<ImportMetadata> queue)
    {
        this.queue = queue;
    }
    
    @Override
    public void run()
    {
        try
        {
            while (true)
            {
                ImportMetadata importMeta = getQueue().take();
                
                Resource provImport = ModelFactory.createDefaultModel().createResource(importMeta.getImport().getURI()).
                        addProperty(PROV.startedAtTime, importMeta.getImport().getModel().createTypedLiteral(Calendar.getInstance()));

                try
                {
                    if (importMeta.getImport().canAs(CSVImport.class))
                        execute(importMeta.getImport().as(CSVImport.class), provImport, importMeta.getProvenanceGraph(), importMeta.getDatasetAccessor(),
                                importMeta.getBaseURI(), importMeta.getDataManager()).join();

                    if (importMeta.getImport().canAs(RDFImport.class))
                        execute(importMeta.getImport().as(RDFImport.class), provImport, importMeta.getProvenanceGraph(), importMeta.getDatasetAccessor(),
                                importMeta.getBaseURI(), importMeta.getDataManager()).join();
                    
                    if (log.isWarnEnabled()) log.warn("Import type not supported: <{}>", importMeta.getImport());
                }
                catch (CompletionException ex)
                {
                    failure(ex, importMeta.getImport(), provImport, importMeta.getProvenanceGraph(), importMeta.getDatasetAccessor());
                }
                catch (Exception ex)
                {
                    if (log.isErrorEnabled()) log.error("Exception during Import processing: {}", ex);
                }
            }
        }
        catch (InterruptedException e)
        {
            Thread.currentThread().interrupt();
        }
    }
    
    public CompletableFuture<Void> execute(CSVImport csvImport, Resource provImport, Resource provGraph, DatasetAccessor accessor, String baseURI, DataManager dataManager)
    {
        if (csvImport == null) throw new IllegalArgumentException("CSVImport cannot be null");
        if (log.isDebugEnabled()) log.debug("Submitting new import to thread pool: {}", csvImport.toString());
        
        QueryLoader queryLoader = new QueryLoader(csvImport.getQuery().getURI(), baseURI, dataManager);
        QuerySolutionMap qsm = new QuerySolutionMap();
        qsm.add(SPIN.THIS_VAR_NAME, csvImport.getContainer()); // target container becomes ?this
        ParameterizedSparqlString pss = new ParameterizedSparqlString(queryLoader.get().toString(), qsm, baseURI);
        
        Supplier<Response> fileSupplier = new ClientResponseSupplier(csvImport.getFile().getURI(), CSV_MEDIA_TYPES, dataManager);
        // skip validation because it will be done during final POST anyway
        Function<Response, CSVStreamRDFOutput> rdfOutputWriter = new CSVStreamRDFOutputWriter(csvImport.getContainer().getURI(),
                dataManager, baseURI, pss.asQuery(), csvImport.getDelimiter());
        
        return CompletableFuture.supplyAsync(fileSupplier).thenApplyAsync(rdfOutputWriter).
            thenAcceptAsync(success(csvImport, provImport, provGraph, accessor));
            //exceptionally(failure(csvImport, provImport, provGraph, accessor));
    }

    public CompletableFuture<Void> execute(RDFImport rdfImport, Resource provImport, Resource provGraph, DatasetAccessor accessor, String baseURI, DataManager dataManager)
    {
        if (rdfImport == null) throw new IllegalArgumentException("RDFImport cannot be null");
        if (log.isDebugEnabled()) log.debug("Submitting new import to thread pool: {}", rdfImport.toString());
        
        QueryLoader queryLoader = new QueryLoader(rdfImport.getQuery().getURI(), baseURI, dataManager);
        QuerySolutionMap qsm = new QuerySolutionMap();
        qsm.add(SPIN.THIS_VAR_NAME, rdfImport.getContainer()); // target container becomes ?this
        ParameterizedSparqlString pss = new ParameterizedSparqlString(queryLoader.get().toString(), qsm, baseURI);
        
        Supplier<Response> fileSupplier = new ClientResponseSupplier(rdfImport.getFile().getURI(), RDF_MEDIA_TYPES, dataManager);
        // skip validation because it will be done during final POST anyway
        Function<Response, StreamRDFOutput> rdfOutputWriter = new StreamRDFOutputWriter(rdfImport.getContainer().getURI(),
                dataManager, baseURI, pss.asQuery());
        
        return CompletableFuture.supplyAsync(fileSupplier).thenApplyAsync(rdfOutputWriter).
            thenAcceptAsync(success(rdfImport, provImport, provGraph, accessor));
//            exceptionally(failure(rdfImport, provImport, provGraph, accessor));
    }

    public Consumer<CSVStreamRDFOutput> success(final CSVImport csvImport, final Resource provImport, final Resource provGraph, final DatasetAccessor accessor)
    {
        return (CSVStreamRDFOutput output) ->
        {
            Resource dataset = provImport.getModel().createResource().
                    addProperty(RDF.type, VoID.Dataset).
                    addLiteral(VoID.distinctSubjects, output.getCSVStreamRDFProcessor().getSubjectCount()).
                    addLiteral(VoID.triples, output.getCSVStreamRDFProcessor().getTripleCount()).
                    addProperty(PROV.wasGeneratedBy, provImport); // connect Response to dataset
            provImport.addProperty(PROV.endedAtTime, provImport.getModel().createTypedLiteral(Calendar.getInstance()));
            
            appendProvGraph(provImport, provGraph, accessor);
        };
    }
    
    public Consumer<StreamRDFOutput> success(final RDFImport rdfImport, final Resource provImport, final Resource provGraph, final DatasetAccessor accessor)
    {
        return (StreamRDFOutput output) ->
        {
            Resource dataset = provImport.getModel().createResource().
                    addProperty(RDF.type, VoID.Dataset).
//                    addLiteral(VoID.distinctSubjects, output.getCSVStreamRDFProcessor().getSubjectCount()).
//                    addLiteral(VoID.triples, output.getCSVStreamRDFProcessor().getTripleCount()).
                    addProperty(PROV.wasGeneratedBy, provImport); // connect Response to dataset
            provImport.addProperty(PROV.endedAtTime, provImport.getModel().createTypedLiteral(Calendar.getInstance()));
            
            appendProvGraph(provImport, provGraph, accessor);
        };
    }

    public void failure(Throwable t, final Import importInst, final Resource provImport, final Resource provGraph, final DatasetAccessor accessor)
    {
        if (log.isErrorEnabled()) log.error("Could not write Import <{}>: {}", importInst, t);

        if (t instanceof CompletionException)
        {
            if (t.getCause() instanceof TextParsingException) // could not parse CSV
            {
                TextParsingException tpe = (TextParsingException)t.getCause();
                Resource exception = provImport.getModel().createResource().
                    addProperty(RDF.type, PROV.Entity).
                    addLiteral(DCTerms.description, tpe.getMessage()).
                    addProperty(PROV.wasGeneratedBy, provImport); // connect Response to exception
                provImport.addProperty(PROV.endedAtTime, importInst.getModel().createTypedLiteral(Calendar.getInstance()));
                appendProvGraph(provImport, provGraph, accessor);
            }

            if (t.getCause() instanceof ImportException) // could not save RDF
            {
                ImportException ie = (ImportException)t.getCause();
                Model excModel = ie.getModel();
                if (excModel != null)
                {
                    Resource response = getResource(excModel, RDF.type, HTTP.Response); // find Response
                    provImport.getModel().add(ResourceUtils.reachableClosure(response));
                    response = getResource(provImport.getModel(), RDF.type, HTTP.Response); // find again in prov Model
                    response.addProperty(PROV.wasGeneratedBy, provImport); // connect Response to Import
                }
                provImport.addProperty(PROV.endedAtTime, importInst.getModel().createTypedLiteral(Calendar.getInstance()));
                appendProvGraph(provImport, provGraph, accessor);
            }
        }
    }

    public Resource getResource(Model model, Property property, RDFNode object)
    {
        ResIterator it = model.listSubjectsWithProperty(RDF.type, HTTP.Response);
        try
        {
            if (it.hasNext()) return it.next();
        }
        finally
        {
            it.close();
        }

        return null;
    }
            
    public void appendProvGraph(Resource provImport, Resource provGraph, DatasetAccessor accessor)
    {
        if (log.isDebugEnabled()) log.debug("Appending import metadata to provenance graph: {}", provGraph);
        accessor.add(provGraph.getURI(), provImport.getModel());
    }
    
    private BlockingQueue<ImportMetadata> getQueue()
    {
        return queue;
    }
    
}
