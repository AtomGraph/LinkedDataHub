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
import com.atomgraph.linkeddatahub.imports.ImportRunner;
import com.atomgraph.linkeddatahub.imports.ImportMetadata;
import com.atomgraph.linkeddatahub.model.Import;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingDeque;
import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import org.apache.jena.query.DatasetAccessor;
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
    
    private static final int IMPORT_QUEUE_SIZE = 20; // Graph Store Protocol cannot accept concurrent write requests TO-DO: make configurable    
    private static final BlockingQueue<ImportMetadata> IMPORT_QUEUE = new LinkedBlockingDeque<>(IMPORT_QUEUE_SIZE);
    
    @Override
    public void contextInitialized(ServletContextEvent sce)
    {
//        if (log.isDebugEnabled()) log.debug("{} initialized with a pool of {} threads", getClass().getName());
        new Thread(new ImportRunner(IMPORT_QUEUE)).start();
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce)
    {
        if (log.isDebugEnabled()) log.debug("Shutting down {} thread pool", getClass().getName());
//        THREAD_POOL.shutdown();
    }

    public static void submit(Import imp, Resource provGraph, DatasetAccessor accessor, String baseURI, DataManager dataManager)
    {
        IMPORT_QUEUE.add(new ImportMetadata(imp, provGraph, accessor, baseURI, dataManager));
    }
    
}
