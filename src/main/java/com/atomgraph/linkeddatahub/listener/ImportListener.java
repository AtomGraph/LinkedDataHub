/**
 *  Copyright 2019 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.listener;

import com.atomgraph.linkeddatahub.exception.ImportException;
import com.atomgraph.linkeddatahub.imports.QueryLoader;
import com.atomgraph.linkeddatahub.imports.csv.stream.CSVStreamRDFOutput;
import com.atomgraph.linkeddatahub.imports.csv.stream.CSVStreamRDFOutputWriter;
import com.atomgraph.linkeddatahub.imports.csv.stream.ClientResponseSupplier;
import com.atomgraph.linkeddatahub.model.CSVImport;
import com.atomgraph.linkeddatahub.vocabulary.PROV;
import com.atomgraph.linkeddatahub.vocabulary.VoID;
import com.atomgraph.server.vocabulary.HTTP;
import com.sun.jersey.api.client.ClientResponse;
import com.univocity.parsers.common.TextParsingException;
import java.util.Calendar;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.function.Consumer;
import java.util.function.Function;
import java.util.function.Supplier;
import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.ws.rs.core.MediaType;
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
import org.spinrdf.vocabulary.SPIN;

/**
 * Data import listener.
 * Used to import data asynchronously.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ImportListener implements ServletContextListener
{

    private static final Logger log = LoggerFactory.getLogger(ImportListener.class);
    
    private static final int MAX_THREADS = 10; // TO-DO: move to config?
    private static final ExecutorService THREAD_POOL = Executors.newFixedThreadPool(MAX_THREADS);
    public static final javax.ws.rs.core.MediaType TEXT_CSV_TYPE = MediaType.valueOf("text/csv");
    public static final javax.ws.rs.core.MediaType VNDMS_EXCEL_TYPE = MediaType.valueOf("application/vnd.ms-excel; q=0.4");
    public static final javax.ws.rs.core.MediaType OCTET_STREAM_TYPE = MediaType.valueOf("application/octet-stream; q=0.1");
    public static final javax.ws.rs.core.MediaType[] CSV_MEDIA_TYPES = { TEXT_CSV_TYPE, VNDMS_EXCEL_TYPE, OCTET_STREAM_TYPE };
    
    @Override
    public void contextInitialized(ServletContextEvent sce)
    {
        if (log.isDebugEnabled()) log.debug("{} initialized with a pool of {} threads", getClass().getName(), MAX_THREADS);
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce)
    {
        if (log.isDebugEnabled()) log.debug("Shutting down {} thread pool", getClass().getName());
        THREAD_POOL.shutdown();
    }

    public static void submit(CSVImport csvImport, com.atomgraph.linkeddatahub.server.model.Resource importRes, Resource provGraph, DatasetAccessor accessor)
    {
        if (csvImport == null) throw new IllegalArgumentException("CSVImport cannot be null");
        if (log.isDebugEnabled()) log.debug("Submitting new import to thread pool: {}", csvImport.toString());
        
        Resource provImport = ModelFactory.createDefaultModel().createResource(csvImport.getURI()).
                addProperty(PROV.startedAtTime, csvImport.getModel().createTypedLiteral(Calendar.getInstance()));
        
        QueryLoader queryLoader = new QueryLoader(csvImport.getQuery().getURI(), csvImport.getBaseUri().getURI(), csvImport.getDataManager());
        QuerySolutionMap qsm = new QuerySolutionMap();
        qsm.add(SPIN.THIS_VAR_NAME, csvImport.getContainer()); // target container becomes ?this
        ParameterizedSparqlString pss = new ParameterizedSparqlString(queryLoader.get().toString(), qsm, csvImport.getBaseUri().getURI());
        
        Supplier<ClientResponse> csvSupplier = new ClientResponseSupplier(csvImport.getFile().getURI(), CSV_MEDIA_TYPES, csvImport.getDataManager());
        // skip validation because it will be done during final POST anyway
        Function<ClientResponse, CSVStreamRDFOutput> rdfOutputWriter = new CSVStreamRDFOutputWriter(csvImport.getContainer().getURI(),
                csvImport.getDataManager(), csvImport.getBaseUri().getURI(), pss.asQuery(), csvImport.getDelimiter());
        
        CompletableFuture.supplyAsync(csvSupplier).thenApplyAsync(rdfOutputWriter).
            thenAcceptAsync(success(csvImport, importRes, provImport, provGraph, accessor)).
            exceptionally(failure(csvImport, importRes, provImport, provGraph, accessor));
    }

    public static Consumer<CSVStreamRDFOutput> success(final CSVImport csvImport, final com.atomgraph.linkeddatahub.server.model.Resource importRes, final Resource provImport, final Resource provGraph, final DatasetAccessor accessor)
    {
        return new Consumer<CSVStreamRDFOutput>()
        {

            @Override
            public void accept(CSVStreamRDFOutput output)
            {
                Resource dataset = provImport.getModel().createResource().
                    addProperty(RDF.type, VoID.Dataset).
                    addLiteral(VoID.distinctSubjects, output.getCSVStreamRDFProcessor().getSubjectCount()).
                    addLiteral(VoID.triples, output.getCSVStreamRDFProcessor().getTripleCount()).
                    addProperty(PROV.wasGeneratedBy, provImport); // connect Response to dataset
                provImport.addProperty(PROV.endedAtTime, provImport.getModel().createTypedLiteral(Calendar.getInstance()));
                
                appendProvGraph(provImport, provGraph, accessor);
            }
        };
    }
    
    public static Function<Throwable, Void> failure(final CSVImport csvImport, final com.atomgraph.linkeddatahub.server.model.Resource importRes, final Resource provImport, final Resource provGraph, final DatasetAccessor accessor)
    {
        return new Function<Throwable, Void>()
        {

            @Override
            public Void apply(Throwable t)
            {
                if (log.isErrorEnabled()) log.error("Could not write CSVImport: {}", csvImport, t);
                
                if (t instanceof CompletionException)
                {
                    if (t.getCause() instanceof TextParsingException) // could not parse CSV
                    {
                        TextParsingException tpe = (TextParsingException)t.getCause();
                        Resource exception = provImport.getModel().createResource().
                            addProperty(RDF.type, PROV.Entity).
                            addLiteral(DCTerms.description, tpe.getMessage()).
                            addProperty(PROV.wasGeneratedBy, provImport); // connect Response to exception
                        provImport.addProperty(PROV.endedAtTime, csvImport.getModel().createTypedLiteral(Calendar.getInstance()));
                        appendProvGraph(provImport, provGraph, accessor);
                    }
                    
                    if (t.getCause() instanceof ImportException) // could not save RDF
                    {
                        ImportException ie = (ImportException)t.getCause();
                        Model excModel = ie.getModel();
                        Resource response = getResource(excModel, RDF.type, HTTP.Response); // find Response
                        provImport.getModel().add(ResourceUtils.reachableClosure(response));
                        response = getResource(provImport.getModel(), RDF.type, HTTP.Response); // find again in prov Model
                        response.addProperty(PROV.wasGeneratedBy, provImport); // connect Response to Import
                        provImport.addProperty(PROV.endedAtTime, csvImport.getModel().createTypedLiteral(Calendar.getInstance()));
                        appendProvGraph(provImport, provGraph, accessor);
                    }
                }
                
                return null;
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
            
        };
    }
    
    public static void appendProvGraph(Resource provImport, Resource provGraph, DatasetAccessor accessor)
    {
        if (log.isDebugEnabled()) log.debug("Appending import metadata to provenance graph: {}", provGraph);
        accessor.add(provGraph.getURI(), provImport.getModel());
    }
    
}
