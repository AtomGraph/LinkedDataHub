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
package com.atomgraph.linkeddatahub.server.model.impl;

import com.atomgraph.linkeddatahub.server.model.ClientUriInfo;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.Iterator;
import java.util.List;
import javax.ws.rs.core.MultivaluedHashMap;
import javax.ws.rs.core.MultivaluedMap;
import javax.ws.rs.core.PathSegment;
import javax.ws.rs.core.UriBuilder;
import javax.ws.rs.core.UriInfo;
import org.apache.jena.query.QuerySolutionMap;
import org.apache.jena.rdf.model.RDFNode;
import org.apache.jena.riot.out.NodeFmtLib;

/**
 * A client-side implementation of <code>UriInfo</code>.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see UriInfo
 */
public class ClientUriInfoImpl implements ClientUriInfo
{
    private final URI baseUri, requestUri;
    private final MultivaluedMap<String, String> queryParams; 

    public static MultivaluedMap<String, String> solutionMapToMultivaluedMap(QuerySolutionMap qsm)
    {
        if (qsm == null) throw new IllegalArgumentException("QuerySolutionMap cannot be null");
        
        MultivaluedMap<String, String> params = new MultivaluedHashMap();
        Iterator<String> it = qsm.varNames();
        while (it.hasNext())
        {
            String varName = it.next();
            RDFNode node = qsm.get(varName);
            params.add("$" + varName, NodeFmtLib.str(node.asNode()));
        }
        
        return params;
    }
    
    public ClientUriInfoImpl(URI baseUri, URI requestUri, MultivaluedMap<String, String> queryParams)
    {
        this.baseUri = baseUri;
        this.requestUri = requestUri;
        this.queryParams = queryParams;
    }
    
    @Override
    public String getPath()
    {
        return requestUri.getPath();
    }

    @Override
    public String getPath(boolean decode)
    {
        throw new UnsupportedOperationException();
    }

    @Override
    public List<PathSegment> getPathSegments()
    {
        throw new UnsupportedOperationException();
    }

    @Override
    public List<PathSegment> getPathSegments(boolean decode)
    {
        throw new UnsupportedOperationException();
    }

    @Override
    public URI getRequestUri()
    {
        return requestUri;
    }

    @Override
    public UriBuilder getRequestUriBuilder()
    {
        return UriBuilder.fromUri(getRequestUri());
    }

    @Override
    public URI getAbsolutePath()
    {
        try
        {
            return new URI(requestUri.getScheme(), requestUri.getAuthority(), requestUri.getPath(), null, requestUri.getFragment());
        }
        catch (URISyntaxException ex)
        {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public UriBuilder getAbsolutePathBuilder()
    {
        throw new UnsupportedOperationException();
    }

    @Override
    public URI getBaseUri()
    {
        return baseUri;
    }

    @Override
    public UriBuilder getBaseUriBuilder()
    {
        return UriBuilder.fromUri(getBaseUri());
    }

    @Override
    public MultivaluedMap<String, String> getPathParameters()
    {
        throw new UnsupportedOperationException();
    }

    @Override
    public MultivaluedMap<String, String> getPathParameters(boolean decode)
    {
        throw new UnsupportedOperationException();
    }

    @Override
    public MultivaluedMap<String, String> getQueryParameters()
    {
        return queryParams;
    }

    @Override
    public MultivaluedMap<String, String> getQueryParameters(boolean decode)
    {
        throw new UnsupportedOperationException();
    }

    @Override
    public List<String> getMatchedURIs()
    {
        throw new UnsupportedOperationException();
    }

    @Override
    public List<String> getMatchedURIs(boolean decode)
    {
        throw new UnsupportedOperationException();
    }

    @Override
    public List<Object> getMatchedResources()
    {
        throw new UnsupportedOperationException();
    }

    @Override
    public URI resolve(URI uri)
    {
        throw new UnsupportedOperationException();
    }

    @Override
    public URI relativize(URI uri)
    {
        throw new UnsupportedOperationException();
    }
    
}
