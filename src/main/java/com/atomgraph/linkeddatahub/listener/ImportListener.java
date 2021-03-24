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

import com.atomgraph.client.util.DataManager;
import com.atomgraph.linkeddatahub.imports.Executor;
import com.atomgraph.linkeddatahub.model.CSVImport;
import com.atomgraph.linkeddatahub.model.RDFImport;
import com.atomgraph.linkeddatahub.model.Service;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
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
    
    private static final int MAX_THREADS = 10; // TO-DO: make configurable
    private static final ExecutorService THREAD_POOL = Executors.newFixedThreadPool(MAX_THREADS);
    
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

    public static void submit(CSVImport csvImport, com.atomgraph.linkeddatahub.server.model.Resource importRes, Resource provGraph, Service service, Service adminService, String baseURI, DataManager dataManager)
    {
        if (csvImport == null) throw new IllegalArgumentException("CSVImport cannot be null");
        if (log.isDebugEnabled()) log.debug("Submitting new CSVImport to thread pool: {}", csvImport.toString());
        
        new Executor(THREAD_POOL).start(csvImport, importRes, provGraph, service, adminService, baseURI, dataManager);
    }

    public static void submit(RDFImport rdfImport, com.atomgraph.linkeddatahub.server.model.Resource importRes, Resource provGraph, Service service, Service adminService, String baseURI, DataManager dataManager)
    {
        if (rdfImport == null) throw new IllegalArgumentException("RDFImport cannot be null");
        if (log.isDebugEnabled()) log.debug("Submitting new RDFImport to thread pool: {}", rdfImport.toString());
        
        new Executor(THREAD_POOL).start(rdfImport, importRes, provGraph, service, adminService, baseURI, dataManager);
    }
    
}
