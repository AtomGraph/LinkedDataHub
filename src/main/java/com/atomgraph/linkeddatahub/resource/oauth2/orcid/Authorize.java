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
package com.atomgraph.linkeddatahub.resource.oauth2.orcid;

import com.atomgraph.linkeddatahub.resource.oauth2.AuthorizeBase;
import com.atomgraph.linkeddatahub.vocabulary.ORCID;
import java.net.URI;
import jakarta.inject.Inject;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.core.Context;

/**
 * JAX-RS resource that handles ORCID authorization requests.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Path("oauth2/authorize/orcid")
public class Authorize extends AuthorizeBase
{
    /**
     * Constructs resource from current request info.
     *
     * @param httpServletRequest servlet request
     * @param application application
     * @param system JAX-RS application
     */
    @Inject
    public Authorize(@Context HttpServletRequest httpServletRequest, com.atomgraph.linkeddatahub.apps.model.Application application, com.atomgraph.linkeddatahub.Application system)
    {
        super(httpServletRequest, application, system, (String)system.getProperty(ORCID.clientID.getURI()));
    }

    @Override
    protected URI getAuthorizeEndpoint()
    {
        return URI.create("https://sandbox.orcid.org/oauth/authorize"); // "https://orcid.org/oauth/authorize"
    }

    @Override
    protected String getScope()
    {
        return "openid";
    }

    @Override
    protected Class<?> getLoginClass()
    {
        return Login.class;
    }

}
