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

import com.atomgraph.core.client.GraphStoreClient;
import com.univocity.parsers.csv.CsvParser;
import com.univocity.parsers.csv.CsvParserSettings;
import java.io.Reader;
import java.util.function.Function;
import org.apache.jena.query.Query;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Resource;

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
    
    /**
     * Constructs output writer.
     * 
     * @param graphStoreClient GSP client for RDF results
     * @param reader CSV reader
     * @param base application base URI
     * @param query <code>CONSTRUCT</code> transformation query
     * @param createGraph function that derives graph URI from a document model
     * @param delimiter CSV delimiter
     * @param maxCharsPerColumn max number of characters per column
     */
    public CSVGraphStoreOutput(GraphStoreClient graphStoreClient, Reader reader, String base, Query query, Function<Model, Resource> createGraph, char delimiter, Integer maxCharsPerColumn)
    {
        this.base = base;
        this.reader = reader;
        this.query = query;
        this.delimiter = delimiter;
        this.maxCharsPerColumn = maxCharsPerColumn;
        this.processor = new CSVGraphStoreRowProcessor(graphStoreClient, base, query, createGraph);
        
        CsvParserSettings parserSettings = new CsvParserSettings();
        parserSettings.setLineSeparatorDetectionEnabled(true);
        parserSettings.setProcessor(processor);
        parserSettings.setHeaderExtractionEnabled(true);
        parserSettings.getFormat().setDelimiter(delimiter);
        if (maxCharsPerColumn != null) parserSettings.setMaxCharsPerColumn(maxCharsPerColumn);

        parser = new CsvParser(parserSettings);
    }
    
    /**
     * Reads CSV and writes RDF.
     * 
     * First a generic CSV/RDF representation is constructed for each row. Then the row is transformed using the SPARQL query.
     */
    public void write()
    {
        getCsvParser().parse(getReader());
    }
    
    /**
     * Returns the CSV parser.
     * 
     * @return parser
     */
    public CsvParser getCsvParser()
    {
        return parser;
    }
    
    /**
     * Returns the CSV reader.
     * 
     * @return reader
     */
    public Reader getReader()
    {
        return reader;
    }
    
    /**
     * Returns the base URI.
     * 
     * @return base URI
     */
    public String getBase()
    {
        return base;
    }
    
    /**
     * Returns the <code>CONSTRUCT</code> transformation query.
     * 
     * @return SPARQL query
     */
    public Query getQuery()
    {
        return query;
    }
    
    /**
     * Returns the CSV delimiter.
     * 
     * @return delimiter character
     */
    public char getDelimiter()
    {
        return delimiter;
    }
    
    /**
     * Returns the maximum number of characters per CSV column.
     * 
     * @return maximum number of characters
     */
    public Integer getMaxCharsPerColumn()
    {
        return maxCharsPerColumn;
    }
    
    /**
     * Returns the row processor.
     * The processor performs the transformation on each CSV row.
     * 
     * @return processor
     */
    public CSVGraphStoreRowProcessor getCSVGraphStoreRowProcessor()
    {
        return processor;
    }
    
}
