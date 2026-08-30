/*
 * Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.atomgraph.linkeddatahub.cli.http;

import jakarta.ws.rs.core.Response;
import java.net.URI;

/**
 * Thrown when the server responds with an error status, mirroring <code>curl -f</code>.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class HttpException extends RuntimeException
{

    private static final int BODY_EXCERPT_LENGTH = 1024;

    private final int status;
    private final URI uri;

    /**
     * Constructs the exception.
     *
     * @param status HTTP status code
     * @param reasonPhrase HTTP reason phrase
     * @param uri request URI
     * @param body response body excerpt (can be empty)
     */
    public HttpException(int status, String reasonPhrase, URI uri, String body)
    {
        super("HTTP " + status + " " + reasonPhrase + " — " + uri + (body == null || body.isBlank() ? "" : "\n" + body));
        this.status = status;
        this.uri = uri;
    }

    /**
     * Throws if the response has an error status (&ge; 400), otherwise returns it.
     *
     * @param uri request URI (for the error message)
     * @param response response to check
     * @return the same response
     */
    public static Response check(URI uri, Response response)
    {
        if (response.getStatus() >= 400)
        {
            String body = "";
            try
            {
                body = response.readEntity(String.class);
                if (body.length() > BODY_EXCERPT_LENGTH) body = body.substring(0, BODY_EXCERPT_LENGTH) + "…";
            }
            catch (Exception ex)
            {
                // body is unreadable - leave the excerpt empty
            }
            finally
            {
                response.close();
            }

            throw new HttpException(response.getStatus(), response.getStatusInfo().getReasonPhrase(), uri, body);
        }

        return response;
    }

    /**
     * Returns the HTTP status code.
     *
     * @return status code
     */
    public int getStatus()
    {
        return status;
    }

    /**
     * Returns the request URI.
     *
     * @return request URI
     */
    public URI getUri()
    {
        return uri;
    }

}
