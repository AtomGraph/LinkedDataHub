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
package com.atomgraph.linkeddatahub.client;

import com.sun.jersey.api.client.config.ClientConfig;
import com.sun.jersey.client.apache4.ApacheHttpClient4;
import com.sun.jersey.client.apache4.ApacheHttpClient4Handler;
import com.sun.jersey.core.spi.component.ioc.IoCComponentProviderFactory;

/**
 * HTTP client that does not send an SSL client certificate.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see com.atomgraph.linkeddatahub.server.filter.request.auth.WebIDFilter
 */
public class NoCertClient extends ApacheHttpClient4
{

    public NoCertClient()
    {
        super();
    }

    public NoCertClient(ApacheHttpClient4Handler root)
    {
        super(root);
    }

    public NoCertClient(ApacheHttpClient4Handler root, ClientConfig config)
    {
        super(root, config);
    }

    public NoCertClient(ApacheHttpClient4Handler root, ClientConfig config, IoCComponentProviderFactory provider)
    {
        super(root, config, provider);
    }

}
