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
public class HostnameRewriteFilter implements ClientRequestFilter
{

    private static final Logger log = LoggerFactory.getLogger(HostnameRewriteFilter.class);

    private final String hostname, newHostname;

    public HostnameRewriteFilter(String hostname, String newHostname)
    {
        this.hostname = hostname;
        this.newHostname = newHostname;
    }
    
    @Override
    public void filter(ClientRequestContext cr) throws IOException
    {
        if (cr.getUri().getHost().equals(getHostname()))
        {
            try
            {
                URI newUri = new URI(cr.getUri().getScheme(), cr.getUri().getUserInfo(), getHostname(), cr.getUri().getPort(),
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
    
    public String getHostname()
    {
        return hostname;
    }
    
    public String getNewHostname()
    {
        return newHostname;
    }
    
}
