/**
 *  Copyright 2022 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.writer.function;

import com.atomgraph.linkeddatahub.vocabulary.LDH;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import javax.xml.transform.stream.StreamSource;
import net.sf.saxon.s9api.ExtensionFunction;
import net.sf.saxon.s9api.ItemType;
import net.sf.saxon.s9api.OccurrenceIndicator;
import net.sf.saxon.s9api.Processor;
import net.sf.saxon.s9api.QName;
import net.sf.saxon.s9api.SaxonApiException;
import net.sf.saxon.s9api.SequenceType;
import net.sf.saxon.s9api.XdmValue;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.RDFParser;
import org.apache.jena.riot.system.StreamRDFLib;

/**
 * Reads an RDF/XML document and re-serializes it using Jena's RDF/XML writer.
 * The output then contains a predictable RDF/XML structure (no nesting, properties grouped into resource descriptions).
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class Reserialize implements ExtensionFunction
{

    public static Lang LANG = Lang.RDFXML;
    
    private final Processor processor;

    /**
     * Constructs function from the specified XSLT processor.
     * 
     * @param processor processor
     */
    public Reserialize(Processor processor)
    {
        this.processor = processor;
    }
    
    @Override
    public QName getName()
    {
        return new QName(LDH.NS, "reserialize");
    }

    @Override
    public SequenceType getResultType()
    {
        return SequenceType.makeSequenceType(ItemType.DOCUMENT_NODE, OccurrenceIndicator.ONE);
    }
    
    @Override
    public SequenceType[] getArgumentTypes()
    {
        return new SequenceType[] { SequenceType.makeSequenceType(ItemType.DOCUMENT_NODE, OccurrenceIndicator.ONE) };
    }

    @Override
    public XdmValue call(XdmValue[] arguments) throws SaxonApiException
    {
        Model model = ModelFactory.createDefaultModel();

        RDFParser parser = RDFParser.fromString(arguments[0].itemAt(0).getStringValue()).
            lang(LANG).
//            errorHandler(errorHandler).
//            base(baseURI).
            build();
        
        parser.parse(StreamRDFLib.graph(model.getGraph()));
        
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        model.write(baos, LANG.getName());
        
        try (InputStream is = new ByteArrayInputStream(baos.toByteArray()))
        {
            return getProcessor().newDocumentBuilder().build(new StreamSource(is));
        }
        catch (IOException ex)
        {
            throw new SaxonApiException(ex);
        }
    }

    /**
     * Returns the associated XSLT processor.
     * 
     * @return processor
     */
    public Processor getProcessor()
    {
        return processor;
    }
    
}
