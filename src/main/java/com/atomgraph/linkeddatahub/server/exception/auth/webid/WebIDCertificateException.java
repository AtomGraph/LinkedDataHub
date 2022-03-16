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
package com.atomgraph.linkeddatahub.server.exception.auth.webid;

import java.security.cert.CertificateException;

/**
 * WebID certificate exception.
 * Thrown when the SSL client certificate cannot parse, is expired or not yet valid.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class WebIDCertificateException extends RuntimeException
{
    
    /**
     * Constructs exception.
     * 
     * @param ex certificate exception
     */
    public WebIDCertificateException(CertificateException ex)
    {
        super(ex);
    }
    
}
