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
package com.atomgraph.linkeddatahub.server.model.impl;

import com.atomgraph.linkeddatahub.resource.Add;
import com.atomgraph.linkeddatahub.resource.Generate;
import com.atomgraph.linkeddatahub.resource.Namespace;
import com.atomgraph.linkeddatahub.resource.Transform;
import com.atomgraph.linkeddatahub.resource.admin.ClearOntology;
import com.atomgraph.linkeddatahub.resource.admin.pkg.InstallPackage;
import com.atomgraph.linkeddatahub.resource.admin.pkg.UninstallPackage;
import com.atomgraph.linkeddatahub.resource.Settings;
import com.atomgraph.linkeddatahub.resource.admin.SignUp;
import com.atomgraph.linkeddatahub.resource.acl.Access;
import com.atomgraph.linkeddatahub.resource.acl.AccessRequest;
import jakarta.ws.rs.Path;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * A catch-all JAX-RS resource that routes requests to sub-resources.
 * Proxy requests ({@code ?uri=} and {@code lapp:Dataset}) are handled earlier by
 * {@link com.atomgraph.linkeddatahub.server.filter.request.ProxyRequestFilter} and never reach this class.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Path("/")
public class Dispatcher
{

    private static final Logger log = LoggerFactory.getLogger(Dispatcher.class);

    /**
     * Returns JAX-RS resource that will handle this request.
     *
     * @return resource
     */
    @Path("{path: .*}")
    public Class getSubResource()
    {
        return getDocumentClass();
    }

    // TO-DO: move @Path annotations onto respective classes?

    /**
     * Returns SPARQL protocol endpoint.
     *
     * @return endpoint resource
     */
    @Path("sparql")
    public Class getSPARQLEndpoint()
    {
        return SPARQLEndpointImpl.class;
    }

    /**
     * Returns SPARQL endpoint for the in-memory ontology model.
     *
     * @return endpoint resource
     */
    @Path("ns")
    public Class getNamespace()
    {
        return Namespace.class;
    }

    /**
     * Returns second-level ontology documents.
     *
     * @return namespace resource
     */
    @Path("ns/{slug}/")
    public Class getSubOntology()
    {
        return Namespace.class;
    }

    /**
     * Returns signup endpoint.
     *
     * @return endpoint resource
     */
    @Path("sign up")
    public Class getSignUp()
    {
        return SignUp.class;
    }

    /**
     * Returns the access description endpoint.
     *
     * @return endpoint resource
     */
    @Path("access")
    public Class getAccess()
    {
        return Access.class;
    }

    /**
     * Returns the access request endpoint.
     *
     * @return endpoint resource
     */
    @Path("access/request")
    public Class getAccessRequest()
    {
        return AccessRequest.class;
    }

    /**
     * Returns content-addressed file item resource.
     *
     * @return resource
     */
    @Path("uploads/{sha1sum}")
    public Class getFileItem()
    {
        return com.atomgraph.linkeddatahub.resource.upload.Item.class;
    }

    /**
     * Returns the endpoint for synchronous RDF imports.
     *
     * @return endpoint resource
     */
    @Path("add")
    public Class getAddEndpoint()
    {
        return Add.class;
    }

    /**
     * Returns the endpoint for synchronous RDF imports with a <code>CONSTRUCT</code> query transformation.
     *
     * @return endpoint resource
     */
    @Path("transform")
    public Class getTransformEndpoint()
    {
        return Transform.class;
    }

    /**
     * Returns the endpoint for container generation.
     *
     * @return endpoint resource
     */
    @Path("generate")
    public Class getGenerateEndpoint()
    {
        return Generate.class;
    }

    /**
     * Returns the endpoint that allows clearing ontologies from cache by URI.
     *
     * @return endpoint resource
     */
    @Path("clear")
    public Class getClearEndpoint()
    {
        return ClearOntology.class;
    }

    /**
     * Returns the endpoint for installing LinkedDataHub packages.
     *
     * @return endpoint resource
     */
    @Path("packages/install")
    public Class getInstallPackageEndpoint()
    {
        return InstallPackage.class;
    }

    /**
     * Returns the endpoint for uninstalling LinkedDataHub packages.
     *
     * @return endpoint resource
     */
    @Path("packages/uninstall")
    public Class getUninstallPackageEndpoint()
    {
        return UninstallPackage.class;
    }

    /**
     * Returns the endpoint for updating dataspace settings.
     *
     * @return endpoint resource
     */
    @Path("settings")
    public Class getSettingsEndpoint()
    {
        return Settings.class;
    }

    /**
     * Returns the default JAX-RS resource class.
     * Only directly identified access to named graphs is allowed (the Graph Store Protocol endpoint is not exposed).
     *
     * @return resource class
     */
    public Class getDocumentClass()
    {
        return DocumentHierarchyGraphStoreImpl.class;
    }

}
