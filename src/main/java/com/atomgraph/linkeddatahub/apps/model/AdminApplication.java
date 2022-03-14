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
package com.atomgraph.linkeddatahub.apps.model;

/**
 * Administrative application.
 * Controls the end-user application.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public interface AdminApplication extends Application
{
    
    /**
     * The relative path at which the request access endpoint is located.
     * TO-DO: extract from JAX-RS <code>@Path</code> annotation?
     * 
     * @see com.atomgraph.linkeddatahub.resource.admin.RequestAccess
     */
    public static final String REQUEST_ACCESS_PATH = "request access";
    
    /**
     * The relative path of the authorization request container.
     * 
     * @see com.atomgraph.linkeddatahub.resource.admin.RequestAccess
     */
    public static final String AUTHORIZATION_REQUEST_PATH = "acl/authorization-requests/";
    
    /**
     * Gets the end-user application paired with this admin application.
     * @return end-user application
     */
    EndUserApplication getEndUserApplication();
    
}
