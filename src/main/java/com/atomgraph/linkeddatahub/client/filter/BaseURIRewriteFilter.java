/**
 *  Copyright 2021 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.client.filter;

import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import javax.ws.rs.client.ClientRequestContext;
import javax.ws.rs.client.ClientRequestFilter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class BaseURIRewriteFilter implements ClientRequestFilter
{

    private static final Logger log = LoggerFactory.getLogger(BaseURIRewriteFilter.class);

    private final URI base, newBase;

    public BaseURIRewriteFilter(URI base, URI newBase)
    {
        this.base = base;
        this.newBase = newBase;
    }
    
    @Override
    public void filter(ClientRequestContext cr) throws IOException
    {
        if (!getBaseURI().relativize(cr.getUri()).isAbsolute())
        {
            try
            {
                URI newUri = new URI(getNewBaseURI().getScheme(), getNewBaseURI().getUserInfo(), getNewBaseURI().getHost(), getNewBaseURI().getPort(),
                        cr.getUri().getPath(), cr.getUri().getQuery(), cr.getUri().getFragment());

                if (log.isDebugEnabled()) log.debug("Rewriting client request URI from '{}' to '{}'", cr.getUri(), newUri);

                cr.setUri(newUri);
            }
            catch (URISyntaxException ex)
            {
                // shouldn't happen
            }
        }
    }
    
    public URI getBaseURI()
    {
        return base;
    }
    
    public URI getNewBaseURI()
    {
        return newBase;
    }
    
}
