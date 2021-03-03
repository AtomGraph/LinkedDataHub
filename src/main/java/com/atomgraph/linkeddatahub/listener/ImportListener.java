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

import com.atomgraph.client.MediaTypes;
import com.atomgraph.client.util.DataManager;
import com.atomgraph.linkeddatahub.imports.ImportRunner;
import com.atomgraph.linkeddatahub.imports.ImportMetadata;
import com.atomgraph.linkeddatahub.model.Import;
import java.net.URI;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingDeque;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.ws.rs.core.MediaType;
import org.apache.jena.query.Dataset;
import org.apache.jena.query.DatasetAccessor;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Resource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Data import listener.
 * Used to import data asynchronously.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ImportListener implements ServletContextListener
{

    private static final Logger log = LoggerFactory.getLogger(ImportListener.class);
    
//    private static final int MAX_THREADS = 1; // Graph Store Protocol cannot accept concurrent write requests TO-DO: make configurable
//    private static final ExecutorService THREAD_POOL = Executors.newFixedThreadPool(MAX_THREADS);
    private static final BlockingQueue<ImportMetadata> importQueue = new LinkedBlockingDeque<>(10);
    public static final javax.ws.rs.core.MediaType TEXT_CSV_TYPE = MediaType.valueOf("text/csv");
    public static final javax.ws.rs.core.MediaType VNDMS_EXCEL_TYPE = MediaType.valueOf("application/vnd.ms-excel; q=0.4");
    public static final javax.ws.rs.core.MediaType OCTET_STREAM_TYPE = MediaType.valueOf("application/octet-stream; q=0.1");
    public static final javax.ws.rs.core.MediaType[] CSV_MEDIA_TYPES = { TEXT_CSV_TYPE, VNDMS_EXCEL_TYPE, OCTET_STREAM_TYPE };
    public static final javax.ws.rs.core.MediaType[] RDF_MEDIA_TYPES = Stream.concat(MediaTypes.READABLE.get(Model.class).stream(), MediaTypes.READABLE.get(Dataset.class).stream()).
        collect(Collectors.toList()).
        toArray(new javax.ws.rs.core.MediaType[0]);
    
    @Override
    public void contextInitialized(ServletContextEvent sce)
    {
//        if (log.isDebugEnabled()) log.debug("{} initialized with a pool of {} threads", getClass().getName());
        new Thread(new ImportRunner(importQueue)).start();
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce)
    {
        if (log.isDebugEnabled()) log.debug("Shutting down {} thread pool", getClass().getName());
//        THREAD_POOL.shutdown();
    }

    public static void submit(Import imp, Resource provGraph, DatasetAccessor accessor, String baseURI, DataManager dataManager)
    {
        importQueue.add(new ImportMetadata(imp, provGraph, accessor, baseURI, dataManager));
    }
    
}
