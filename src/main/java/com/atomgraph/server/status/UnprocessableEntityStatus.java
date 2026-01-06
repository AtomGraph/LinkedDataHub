/*
 * Copyright 2023 Martynas Jusevičius <martynas@atomgraph.com>.
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

package com.atomgraph.server.status;

import jakarta.ws.rs.core.Response;

/**
 * Custom response status enum for <code>422 Unprocessable Entity</code>.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public enum UnprocessableEntityStatus implements Response.StatusType
{

    UNPROCESSABLE_ENTITY(422, "Unprocessable Entity");

    private final int code;
    private final String reason;
    private final Response.Status.Family family;

    UnprocessableEntityStatus(int code, String reason)
    {
        this.code = code;
        this.reason = reason;
        this.family = Response.Status.Family.familyOf(code);
    }

    @Override
    public int getStatusCode()
    {
        return code;
    }

    @Override
    public Response.Status.Family getFamily()
    {
        return family;
    }

    @Override
    public String getReasonPhrase() {
        return reason;
    }
    
}
