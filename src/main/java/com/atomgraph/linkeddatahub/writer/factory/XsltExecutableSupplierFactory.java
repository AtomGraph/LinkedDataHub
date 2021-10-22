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
package com.atomgraph.linkeddatahub.writer.factory;

import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.linkeddatahub.writer.factory.xslt.XsltExecutableSupplierImpl;
import com.atomgraph.linkeddatahub.writer.factory.xslt.XsltExecutableSupplier;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.core.Context;
import javax.ws.rs.ext.Provider;
import net.sf.saxon.s9api.XsltExecutable;
import org.glassfish.hk2.api.Factory;
import org.glassfish.hk2.api.ServiceLocator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Provider
public class XsltExecutableSupplierFactory implements Factory<XsltExecutableSupplier>
{
    
    private static final Logger log = LoggerFactory.getLogger(XsltExecutableSupplierFactory.class);

    @Context private ServiceLocator serviceLocator;

    @Override
    public XsltExecutableSupplier provide()
    {
        return new XsltExecutableSupplierImpl((XsltExecutable)getContainerRequestContext().getProperty(AC.stylesheet.getURI()));
    }

    @Override
    public void dispose(XsltExecutableSupplier instance)
    {

    }
    
    public ContainerRequestContext getContainerRequestContext()
    {
        return serviceLocator.getService(ContainerRequestContext.class);
    }
    
}
