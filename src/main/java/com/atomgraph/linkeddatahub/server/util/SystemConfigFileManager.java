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
package com.atomgraph.linkeddatahub.server.util;

import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.file.Path;
import org.apache.jena.query.Dataset;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.riot.RDFDataMgr;
import org.apache.jena.riot.RDFFormat;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Utility class for managing system configuration files in TriG format.
 * Provides methods for updating and writing configuration datasets.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class SystemConfigFileManager
{

    private static final Logger log = LoggerFactory.getLogger(SystemConfigFileManager.class);

    /**
     * Writes a dataset to a file in TriG format.
     *
     * @param dataset the dataset to write
     * @param filePath the path to the output file
     * @throws IOException if an I/O error occurs during writing
     */
    public static void writeDataset(Dataset dataset, Path filePath) throws IOException
    {
        if (dataset == null) throw new IllegalArgumentException("Dataset cannot be null");
        if (filePath == null) throw new IllegalArgumentException("File path cannot be null");

        try (FileOutputStream out = new FileOutputStream(filePath.toFile()))
        {
            RDFDataMgr.write(out, dataset, RDFFormat.TRIG_PRETTY);
            if (log.isDebugEnabled()) log.debug("Wrote dataset to file: {}", filePath);
        }
    }

}
