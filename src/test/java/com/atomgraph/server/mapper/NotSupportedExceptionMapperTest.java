/**
 *  Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.server.mapper;

import com.atomgraph.core.MediaTypes;
import jakarta.ws.rs.NotSupportedException;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import java.net.URI;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Tests that a 415 to <code>PATCH</code> advertises the accepted patch format.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class NotSupportedExceptionMapperTest
{

    protected NotSupportedExceptionMapper getMapper(String method)
    {
        Request request = mock(Request.class);
        when(request.getMethod()).thenReturn(method);
        when(request.selectVariant(any())).thenReturn(null);
        UriInfo uriInfo = mock(UriInfo.class);
        when(uriInfo.getBaseUri()).thenReturn(URI.create("https://localhost:4443/"));

        return new NotSupportedExceptionMapper(new MediaTypes())
        {
            @Override
            public Request getRequest()
            {
                return request;
            }

            @Override
            public UriInfo getUriInfo()
            {
                return uriInfo;
            }
        };
    }

    @Test
    public void testPatchAdvertisesAcceptPatch()
    {
        Response response = getMapper("PATCH").toResponse(new NotSupportedException());

        assertEquals(Response.Status.UNSUPPORTED_MEDIA_TYPE.getStatusCode(), response.getStatus());
        assertEquals(com.atomgraph.core.MediaType.APPLICATION_SPARQL_UPDATE, response.getHeaderString(NotSupportedExceptionMapper.ACCEPT_PATCH));
    }

    @Test
    public void testPostHasNoAcceptPatch()
    {
        Response response = getMapper("POST").toResponse(new NotSupportedException());

        assertEquals(Response.Status.UNSUPPORTED_MEDIA_TYPE.getStatusCode(), response.getStatus());
        assertNull(response.getHeaderString(NotSupportedExceptionMapper.ACCEPT_PATCH));
    }

}
