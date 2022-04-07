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

import com.atomgraph.linkeddatahub.vocabulary.LDHC;
import java.util.concurrent.ExecutorService;
import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
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

    @Override
    public void contextDestroyed(ServletContextEvent sce)
    {
        if (log.isDebugEnabled()) log.debug("Shutting down {} thread pool", getClass().getName());
        ExecutorService executorService = (ExecutorService)sce.getServletContext().getAttribute(LDHC.maxImportThreads.getURI());
        if (executorService != null) executorService.shutdown();
    }
    
}
