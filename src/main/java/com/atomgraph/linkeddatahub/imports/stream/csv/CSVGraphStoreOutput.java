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
package com.atomgraph.linkeddatahub.imports.stream.csv;

import com.atomgraph.linkeddatahub.client.GraphStoreClient;
import com.univocity.parsers.csv.CsvParser;
import com.univocity.parsers.csv.CsvParserSettings;
import java.io.Reader;
import org.apache.jena.query.Query;

/**
 * RDF output stream.
 * Used to write CSV data transformed to RDF.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see com.atomgraph.linkeddatahub.listener.ImportListener
 */
public class CSVGraphStoreOutput // extends com.atomgraph.etl.csv.stream.CSVStreamRDFOutput
{

    private final String base;
    private final Reader reader;
    private final Query query;
    private final char delimiter;
    private final Integer maxCharsPerColumn;
    private final CSVGraphStoreRowProcessor processor;
    private final CsvParser parser;
    
    public CSVGraphStoreOutput(GraphStoreClient graphStoreClient, Reader reader, String base, Query query, char delimiter, Integer maxCharsPerColumn)
    {
        this.base = base;
        this.reader = reader;
        this.query = query;
        this.delimiter = delimiter;
        this.maxCharsPerColumn = maxCharsPerColumn;
        this.processor = new CSVGraphStoreRowProcessor(graphStoreClient, base, query);
        
        CsvParserSettings parserSettings = new CsvParserSettings();
        parserSettings.setLineSeparatorDetectionEnabled(true);
        parserSettings.setProcessor(processor);
        parserSettings.setHeaderExtractionEnabled(true);
        parserSettings.getFormat().setDelimiter(delimiter);
        if (maxCharsPerColumn != null) parserSettings.setMaxCharsPerColumn(maxCharsPerColumn);

        parser = new CsvParser(parserSettings);
    }
    
    public void write()
    {
        getCsvParser().parse(getReader());
    }
    
    public CsvParser getCsvParser()
    {
        return parser;
    }
    
    public Reader getReader()
    {
        return reader;
    }
    
    public String getBase()
    {
        return base;
    }
       
    public Query getQuery()
    {
        return query;
    }
    
    public char getDelimiter()
    {
        return delimiter;
    }
    
    public Integer getMaxCharsPerColumn()
    {
        return maxCharsPerColumn;
    }
    
    public CSVGraphStoreRowProcessor getCSVGraphStoreRowProcessor()
    {
        return processor;
    }
    
}
