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
import net.sf.saxon.s9api.ExtensionFunction;
import net.sf.saxon.s9api.ItemType;
import net.sf.saxon.s9api.OccurrenceIndicator;
import net.sf.saxon.s9api.QName;
import net.sf.saxon.s9api.SaxonApiException;
import net.sf.saxon.s9api.SequenceType;
import net.sf.saxon.s9api.XdmAtomicValue;
import net.sf.saxon.s9api.XdmEmptySequence;
import net.sf.saxon.s9api.XdmValue;
import org.glassfish.jersey.uri.UriComponent;

/**
 * Decodes URL-encoded string.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class DecodeURI implements ExtensionFunction
{

    @Override
    public QName getName()
    {
        return new QName(LDH.NS, "decode-uri");
    }

    @Override
    public SequenceType getResultType()
    {
        return SequenceType.makeSequenceType(ItemType.STRING, OccurrenceIndicator.ONE);
    }

    @Override
    public SequenceType[] getArgumentTypes()
    {
        return new SequenceType[]
        {
            SequenceType.makeSequenceType(ItemType.STRING, OccurrenceIndicator.ZERO_OR_ONE),
        };
    }

    @Override
    public XdmValue call(XdmValue[] arguments) throws SaxonApiException
    {
        if (!arguments[0].itemAt(0).isEmpty())
            return new XdmAtomicValue(UriComponent.decode(arguments[0].itemAt(0).getStringValue(), null));
        
        return XdmEmptySequence.getInstance();
    }

}
