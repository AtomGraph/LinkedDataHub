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

import com.atomgraph.client.MediaTypes;
import com.atomgraph.client.util.DataManager;
import com.atomgraph.core.client.GraphStoreClient;
import com.atomgraph.core.model.DatasetAccessor;
import com.atomgraph.linkeddatahub.imports.stream.RDFGraphStoreOutput;
import com.atomgraph.linkeddatahub.imports.stream.csv.CSVGraphStoreOutput;
import com.atomgraph.linkeddatahub.imports.stream.csv.CSVGraphStoreOutputWriter;
import com.atomgraph.linkeddatahub.imports.stream.csv.ClientResponseSupplier;
import com.atomgraph.linkeddatahub.imports.stream.StreamRDFOutputWriter;
import com.atomgraph.linkeddatahub.model.CSVImport;
import com.atomgraph.linkeddatahub.model.Import;
import com.atomgraph.linkeddatahub.model.RDFImport;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.exception.ImportException;
import com.atomgraph.linkeddatahub.server.filter.response.BackendInvalidationFilter;
import com.atomgraph.linkeddatahub.server.model.impl.GraphStoreImpl;
import com.atomgraph.linkeddatahub.vocabulary.PROV;
import com.atomgraph.linkeddatahub.vocabulary.VoID;
import com.atomgraph.server.vocabulary.HTTP;
import com.atomgraph.spinrdf.vocabulary.SPIN;
import com.univocity.parsers.common.TextParsingException;
import java.net.URI;
import java.util.Calendar;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionException;
import java.util.concurrent.ExecutorService;
import java.util.function.Consumer;
import java.util.function.Function;
import java.util.function.Supplier;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.UriBuilder;
import org.apache.jena.query.Dataset;
import org.apache.jena.query.ParameterizedSparqlString;
import org.apache.jena.query.Query;
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
import org.glassfish.jersey.uri.UriComponent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class Executor
{

    private static final Logger log = LoggerFactory.getLogger(Executor.class);

    /** CSV media type */
    public static final javax.ws.rs.core.MediaType TEXT_CSV_TYPE = MediaType.valueOf("text/csv");
    /** MS Excel media type */
    public static final javax.ws.rs.core.MediaType VNDMS_EXCEL_TYPE = MediaType.valueOf("application/vnd.ms-excel; q=0.4");
    /** Fallback media type */
    public static final javax.ws.rs.core.MediaType OCTET_STREAM_TYPE = MediaType.valueOf("application/octet-stream; q=0.1");
    /** An array of supported CSV media types */
    public static final javax.ws.rs.core.MediaType[] CSV_MEDIA_TYPES = { TEXT_CSV_TYPE, VNDMS_EXCEL_TYPE, OCTET_STREAM_TYPE };
    /** An array of supported RDF media types */
    public static final javax.ws.rs.core.MediaType[] RDF_MEDIA_TYPES = Stream.concat(MediaTypes.READABLE.get(Model.class).stream(), MediaTypes.READABLE.get(Dataset.class).stream()).
        collect(Collectors.toList()).
        toArray(new javax.ws.rs.core.MediaType[0]);

    private final ExecutorService execService;

    /**
     * Construct executor from thread pool.
     * 
     * @param execService thread pool service
     */
    public Executor(ExecutorService execService)
    {
        this.execService = execService;
    }
    
    /**
     * Executes CSV import.
     * 
     * @param csvImport CSV import resource
     * @param service application's SPARQL service
     * @param adminService admin application's SPARQL service
     * @param baseURI application's base URI
     * @param dataManager RDF data manager
     * @param graphStoreClient GSP client
     */
    public void start(CSVImport csvImport, Service service, Service adminService, String baseURI, DataManager dataManager, GraphStoreClient graphStoreClient)
    {
        if (csvImport == null) throw new IllegalArgumentException("CSVImport cannot be null");
        if (log.isDebugEnabled()) log.debug("Submitting new import to thread pool: {}", csvImport.toString());
        
        Resource provImport = ModelFactory.createDefaultModel().createResource(csvImport.getURI()).
                addProperty(PROV.startedAtTime, csvImport.getModel().createTypedLiteral(Calendar.getInstance()));
        
        QueryLoader queryLoader = new QueryLoader(csvImport.getQuery().getURI(), baseURI, dataManager);
        QuerySolutionMap qsm = new QuerySolutionMap();
        qsm.add(SPIN.THIS_VAR_NAME, csvImport.getContainer()); // target container becomes ?this
        ParameterizedSparqlString pss = new ParameterizedSparqlString(queryLoader.get().toString(), qsm, baseURI);
        final Query query = pss.asQuery();
        
        Supplier<Response> fileSupplier = new ClientResponseSupplier(csvImport.getFile().getURI(), CSV_MEDIA_TYPES, dataManager);
        // skip validation because it will be done during final POST anyway
        CompletableFuture.supplyAsync(fileSupplier, getExecutorService()).thenApplyAsync(getStreamRDFOutputWriter(csvImport,
                graphStoreClient, baseURI, query), getExecutorService()).
            thenAcceptAsync(success(csvImport, provImport, service, adminService, dataManager), getExecutorService()).
            exceptionally(failure(csvImport, provImport, service));
    }

    /**
     * Executes RDF import.
     * 
     * @param rdfImport RDF import resource
     * @param service application's SPARQL service
     * @param adminService admin application's SPARQL service
     * @param baseURI application's base URI
     * @param dataManager RDF data manager
     * @param graphStoreClient GSP client
     */

    public void start(RDFImport rdfImport, Service service, Service adminService, String baseURI, DataManager dataManager, GraphStoreClient graphStoreClient)
    {
        if (rdfImport == null) throw new IllegalArgumentException("RDFImport cannot be null");
        if (log.isDebugEnabled()) log.debug("Submitting new import to thread pool: {}", rdfImport.toString());
        
        Resource provImport = ModelFactory.createDefaultModel().createResource(rdfImport.getURI()).
                addProperty(PROV.startedAtTime, rdfImport.getModel().createTypedLiteral(Calendar.getInstance()));
        
        final Query query;
        if (rdfImport.getQuery() != null) // query is optional on RDFImport
        {
            QueryLoader queryLoader = new QueryLoader(rdfImport.getQuery().getURI(), baseURI, dataManager);
            QuerySolutionMap qsm = new QuerySolutionMap();
            qsm.add(SPIN.THIS_VAR_NAME, rdfImport.getContainer()); // target container becomes ?this
            ParameterizedSparqlString pss = new ParameterizedSparqlString(queryLoader.get().toString(), qsm, baseURI);
            query = pss.asQuery();
        }
        else
            query = null;
        
        Supplier<Response> fileSupplier = new ClientResponseSupplier(rdfImport.getFile().getURI(), RDF_MEDIA_TYPES, dataManager);
        // skip validation because it will be done during final POST anyway
        CompletableFuture.supplyAsync(fileSupplier, getExecutorService()).thenApplyAsync(getStreamRDFOutputWriter(rdfImport,
                graphStoreClient, baseURI, query), getExecutorService()).
            thenAcceptAsync(success(rdfImport, provImport, service, adminService, dataManager), getExecutorService()).
            exceptionally(failure(rdfImport, provImport, service));
    }
    
    /**
     * Invoked when CSV import completes successfully.
     * 
     * @param csvImport import resource
     * @param provImport provenance resource
     * @param service application's SPARQL service
     * @param adminService admin application's SPARQL service
     * @param dataManager RDF data manager
     * @return consumer of the RDF output
     */
    protected Consumer<CSVGraphStoreOutput> success(final CSVImport csvImport, final Resource provImport, final Service service, final Service adminService, final DataManager dataManager)
    {
        return (CSVGraphStoreOutput output) ->
        {
            Resource dataset = provImport.getModel().createResource().
                addProperty(RDF.type, VoID.Dataset).
                addLiteral(VoID.distinctSubjects, output.getCSVGraphStoreRowProcessor().getSubjectCount()).
                addLiteral(VoID.triples, output.getCSVGraphStoreRowProcessor().getTripleCount()).
                addProperty(PROV.wasGeneratedBy, provImport); // connect Response to dataset
            provImport.addProperty(PROV.endedAtTime, provImport.getModel().createTypedLiteral(Calendar.getInstance()));
            
            appendProvGraph(provImport, service.getDatasetAccessor());
            
            // purge cache entries that include the target container URL
            if (service.getProxy() != null) ban(dataManager, service.getProxy(), csvImport.getContainer().getURI());
            if (adminService != null && adminService.getProxy() != null) ban(dataManager, adminService.getProxy(), csvImport.getContainer().getURI());
        };
    }
    
    /**
     * Invoked when RDF import completes successfully.
     * 
     * @param rdfImport import resource
     * @param provImport provenance resource
     * @param service application's SPARQL service
     * @param adminService admin application's SPARQL service
     * @param dataManager RDF data manager
     * @return consumer of the RDF output
     */
    protected Consumer<RDFGraphStoreOutput> success(final RDFImport rdfImport, final Resource provImport, final Service service, final Service adminService, final DataManager dataManager)
    {
        return (RDFGraphStoreOutput output) ->
        {
            Resource dataset = provImport.getModel().createResource().
                addProperty(RDF.type, VoID.Dataset).
//                    addLiteral(VoID.distinctSubjects, output.getCSVStreamRDFProcessor().getSubjectCount()).
//                    addLiteral(VoID.triples, output.getCSVStreamRDFProcessor().getTripleCount()).
                addProperty(PROV.wasGeneratedBy, provImport); // connect Response to dataset
            provImport.addProperty(PROV.endedAtTime, provImport.getModel().createTypedLiteral(Calendar.getInstance()));
            
            appendProvGraph(provImport, service.getDatasetAccessor());
            
            // purge cache entries that include the target container URL
            if (service.getProxy() != null)
            {
                if (rdfImport.getContainer() != null) ban(dataManager, service.getProxy(), rdfImport.getContainer().getURI());
                if (rdfImport.getGraphName() != null) ban(dataManager, service.getProxy(), rdfImport.getGraphName().getURI());
            }
            if (adminService != null && adminService.getProxy() != null)
            {
                if (rdfImport.getContainer() != null) ban(dataManager, adminService.getProxy(), rdfImport.getContainer().getURI());
                if (rdfImport.getGraphName() != null) ban(dataManager, adminService.getProxy(), rdfImport.getGraphName().getURI());
            }
        };
    }

    /**
     * Invoked when RDF import failes to complete.
     * 
     * @param importInst import resource
     * @param provImport provenance resource
     * @param service application's SPARQL service
     * @return void function
     */
    protected Function<Throwable, Void> failure(final Import importInst, final Resource provImport, final Service service)
    {
        return new Function<Throwable, Void>()
        {

            @Override
            public Void apply(Throwable t)
            {
                if (log.isErrorEnabled()) log.error("Could not write Import: {}", importInst, t);
                
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
                        
                        appendProvGraph(provImport, service.getDatasetAccessor());
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
                        
                        appendProvGraph(provImport, service.getDatasetAccessor());
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

    /**
     * Appends provenance metadata to the graph of the import.
     * 
     * @param provImport import resource
     * @param accessor GSP graph accessor
     */
    protected void appendProvGraph(Resource provImport, DatasetAccessor accessor)
    {
        URI graphURI = UriBuilder.fromUri(provImport.getURI()).fragment(null).build(); // skip fragment from the Import URI to get its graph URI
        if (log.isDebugEnabled()) log.debug("Appending import metadata to graph: {}", graphURI);
        
        GraphStoreImpl.skolemize(provImport.getModel(), graphURI); // make sure we don't store blank nodes
        accessor.add(graphURI.toString(), provImport.getModel());
    }

    /**
     * Returns output writer for CSV imports.
     * 
     * @param imp import resource
     * @param graphStoreClient GSP client
     * @param baseURI base URI
     * @param query transformation query
     * @return function
     */
    protected Function<Response, CSVGraphStoreOutput> getStreamRDFOutputWriter(CSVImport imp, GraphStoreClient graphStoreClient, String baseURI, Query query)
    {
        return new CSVGraphStoreOutputWriter(graphStoreClient, baseURI, query, imp.getDelimiter());
    }

    /**
     * Returns output writer for RDF imports.
     * 
     * @param imp import resource
     * @param graphStoreClient GSP client
     * @param baseURI base URI
     * @param query transformation query
     * @return function
     */
    protected Function<Response, RDFGraphStoreOutput> getStreamRDFOutputWriter(RDFImport imp, GraphStoreClient graphStoreClient, String baseURI, Query query)
    {
        return new StreamRDFOutputWriter(graphStoreClient, baseURI, query, imp.getGraphName() != null ? imp.getGraphName().getURI() : null);
    }

    /**
     * Bans URL from Varnish proxy cache.
     * 
     * @param dataManager RDF data manager
     * @param proxy URI resource of the proxy cache
     * @param url URL to be banned
     * @return response from Varnish
     */
    public Response ban(DataManager dataManager, Resource proxy, String url)
    {
        if (url == null) throw new IllegalArgumentException("Resource cannot be null");
        
        // create new Client instance, otherwise ApacheHttpClient reuses connection and Varnish ignores BAN request
        return dataManager.getClient().target(proxy.getURI()).request().
            header(BackendInvalidationFilter.HEADER_NAME, UriComponent.encode(url, UriComponent.Type.UNRESERVED)).
            method("BAN", Response.class);
    }
    
    /**
     * Returns executor service that contains a thread pool.
     * 
     * @return service
     */
    protected ExecutorService getExecutorService()
    {
        return execService;
    }
    
}
