/**
 *  Copyright 2020 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.writer.factory.xslt;

import net.sf.saxon.s9api.XsltExecutable;

/**
 * Implementation of XSLT executable supplier.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class XsltExecutableSupplierImpl implements XsltExecutableSupplier
{
    
    private final XsltExecutable xsltExec;
    
    /**
     * Constructs supplier.
     * 
     * @param xsltExec XSLT executable
     */
    public XsltExecutableSupplierImpl(XsltExecutable xsltExec)
    {
        this.xsltExec = xsltExec;
    }
    
    @Override
    public XsltExecutable get()
    {
        return xsltExec;
    }
    
}
