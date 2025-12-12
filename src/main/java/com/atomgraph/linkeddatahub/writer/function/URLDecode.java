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
package com.atomgraph.linkeddatahub.writer.function;

import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;
import net.sf.saxon.expr.XPathContext;
import net.sf.saxon.lib.ExtensionFunctionCall;
import net.sf.saxon.lib.ExtensionFunctionDefinition;
import net.sf.saxon.om.Sequence;
import net.sf.saxon.om.StructuredQName;
import net.sf.saxon.trans.XPathException;
import net.sf.saxon.value.SequenceType;
import net.sf.saxon.value.StringValue;

/**
 * Saxon extension function that URL-decodes a string using java.net.URLDecoder.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class URLDecode extends ExtensionFunctionDefinition
{

    /** The local name of the XSLT function */
    public static final String LOCAL_NAME = "url-decode";
    
    @Override
    public StructuredQName getFunctionQName()
    {
        return new StructuredQName("ldh", "https://w3id.org/atomgraph/linkeddatahub#", LOCAL_NAME);
    }

    @Override
    public int getMinimumNumberOfArguments()
    {
        return 1;
    }

    @Override
    public int getMaximumNumberOfArguments()
    {
        return 2;
    }

    @Override
    public SequenceType[] getArgumentTypes()
    {
        return new SequenceType[]
        {
            SequenceType.SINGLE_STRING, // encoded string
            SequenceType.OPTIONAL_STRING // encoding (optional, defaults to UTF-8)
        };
    }

    @Override
    public SequenceType getResultType(SequenceType[] suppliedArgumentTypes)
    {
        return SequenceType.SINGLE_STRING;
    }

    @Override
    public ExtensionFunctionCall makeCallExpression()
    {
        return new ExtensionFunctionCall()
        {
            
            @Override
            public Sequence call(XPathContext context, Sequence[] arguments) throws XPathException
            {
                String encodedString = arguments[0].head().getStringValue();
                String encoding = arguments.length > 1 && arguments[1].head() != null ? 
                    arguments[1].head().getStringValue() : "UTF-8";
                
                try
                {
                    // Handle + to space conversion for application/x-www-form-urlencoded format
                    String plusDecoded = encodedString.replace("+", " ");
                    String decoded = URLDecoder.decode(plusDecoded, encoding);
                    return StringValue.makeStringValue(decoded);
                }
                catch (UnsupportedEncodingException ex)
                {
                    throw new XPathException("Unsupported encoding: " + encoding, ex);
                }
            }
            
        };
    }
    
}