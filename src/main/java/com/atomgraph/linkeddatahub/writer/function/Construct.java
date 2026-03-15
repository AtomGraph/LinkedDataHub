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
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import javax.xml.transform.stream.StreamSource;
import net.sf.saxon.s9api.ExtensionFunction;
import net.sf.saxon.s9api.ItemType;
import net.sf.saxon.s9api.ItemTypeFactory;
import net.sf.saxon.s9api.OccurrenceIndicator;
import net.sf.saxon.s9api.Processor;
import net.sf.saxon.s9api.QName;
import net.sf.saxon.s9api.SaxonApiException;
import net.sf.saxon.s9api.SequenceType;
import net.sf.saxon.s9api.XdmValue;
import org.apache.jena.query.Query;
import org.apache.jena.query.QueryExecution;
import org.apache.jena.query.QueryFactory;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.sparql.core.Var;
import org.apache.jena.sparql.engine.binding.Binding;
import org.apache.jena.sparql.engine.binding.BindingFactory;
import org.apache.jena.sparql.expr.ExprVar;
import org.apache.jena.sparql.syntax.ElementBind;
import org.apache.jena.sparql.syntax.ElementGroup;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.riot.RDFLanguages;
import org.apache.jena.vocabulary.RDF;

/**
 * Constructs RDF instances from a given <code>forClass -&gt; constructor</code> map.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class Construct implements ExtensionFunction
{

    private final Processor processor;

    /**
     * Constructs function from the specified XSLT processor.
     * 
     * @param processor Saxon processor
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
                        instance.addProperty(RDF.type, ResourceFactory.createResource(forClass.getStringValue()));

                        // Inject BIND(?_this_bind AS ?this) into the WHERE clause.
                        // This keeps ?this as a variable in the CONSTRUCT template (not a written blank node),
                        // so the template picks up the concrete node value — preserving blank node identity.
                        // See: https://github.com/apache/jena/issues/3267
                        Var bindVar = Var.alloc("_this_bind");
                        Binding binding = BindingFactory.binding(bindVar, instance.asNode());

                        constructors.stream().forEach(constructor ->
                        {
                            Query query = QueryFactory.create(constructor.getStringValue());
                            ElementGroup group = new ElementGroup();
                            group.addElement(query.getQueryPattern());
                            group.addElement(new ElementBind(Var.alloc(SPIN.THIS_VAR_NAME), new ExprVar(bindVar)));
                            query.setQueryPattern(group);

                            try (QueryExecution qex = QueryExecution.create().query(query).model(model).substitution(binding).build())
                            {
                                qex.execConstruct(model);
                            }
                        });
                    }
                );

            return getProcessor().newDocumentBuilder().build(getSource(model));
        }
        catch (IOException ex)
        {
            throw new SaxonApiException(ex);
        }
    }
    
    /**
     * Creates stream source from RDF model.
     * The model is serialized using the RDF/XML syntax.
     * 
     * @param model RDF model
     * @return XML stream source
     * @throws IOException I/O error
     */
    public StreamSource getSource(Model model) throws IOException
    {
        if (model == null) throw new IllegalArgumentException("Model cannot be null");

        try (ByteArrayOutputStream stream = new ByteArrayOutputStream())
        {
            model.write(stream, RDFLanguages.RDFXML.getName(), null);
            return new StreamSource(new ByteArrayInputStream(stream.toByteArray()));
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
