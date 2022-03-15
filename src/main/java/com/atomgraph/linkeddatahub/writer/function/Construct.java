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

import com.atomgraph.client.vocabulary.SPIN;
import com.atomgraph.linkeddatahub.vocabulary.LDH;
import com.atomgraph.linkeddatahub.writer.ModelXSLTWriter;
import java.io.IOException;
import net.sf.saxon.s9api.ExtensionFunction;
import net.sf.saxon.s9api.ItemType;
import net.sf.saxon.s9api.ItemTypeFactory;
import net.sf.saxon.s9api.OccurrenceIndicator;
import net.sf.saxon.s9api.Processor;
import net.sf.saxon.s9api.QName;
import net.sf.saxon.s9api.SaxonApiException;
import net.sf.saxon.s9api.SequenceType;
import net.sf.saxon.s9api.XdmValue;
import org.apache.jena.query.QueryExecution;
import org.apache.jena.query.QuerySolutionMap;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.vocabulary.RDF;

/**
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class Construct implements ExtensionFunction
{

    private final Processor processor;

    /**
     * Constructs function from the specified XSLT processor.
     * 
     * @param processor processor
     */
    public Construct(Processor processor)
    {
        this.processor = processor;
    }
    
    @Override
    public QName getName()
    {
        return new QName(LDH.NS, "construct");
    }

    @Override
    public SequenceType getResultType()
    {
        return SequenceType.makeSequenceType(ItemType.DOCUMENT_NODE, OccurrenceIndicator.ONE);
    }
    
    @Override
    public SequenceType[] getArgumentTypes()
    {
        return new SequenceType[] /* map(xs:anyURI, xs:string*) */
        {
            SequenceType.makeSequenceType(new ItemTypeFactory(getProcessor()).getMapType(ItemType.ANY_URI,
                SequenceType.makeSequenceType(ItemType.STRING, OccurrenceIndicator.ZERO_OR_MORE)), OccurrenceIndicator.ONE)
        };
        
    }

    @Override
    public XdmValue call(XdmValue[] arguments) throws SaxonApiException
    {
        try
        {
            Model model = ModelFactory.createDefaultModel();
            
            if (!arguments[0].isEmpty())
                arguments[0].itemAt(0).asMap().forEach((forClass, constructors) ->
                    {
                        Resource instance = model.createResource();
                        QuerySolutionMap qsm = new QuerySolutionMap();
                        qsm.add(SPIN.THIS_VAR_NAME, instance);

                        instance.addProperty(RDF.type, ResourceFactory.createResource(forClass.getStringValue()));
                        constructors.stream().forEach(constructor ->
                        {
                            try (QueryExecution qex = QueryExecution.model(model).query(constructor.getStringValue()).initialBinding(qsm).build())
                            {
                                qex.execConstruct(model);
                            }
                        });
                    }
                );

            return getProcessor().newDocumentBuilder().build(ModelXSLTWriter.getSource(model));
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
