// Copyright 2019 Martynas Jusevičius <martynas@atomgraph.com>
// SPDX-FileCopyrightText: 2017-2022 2017 Martynas Jusevicius, <martynas@atomgraph.com> et al.
//
// SPDX-License-Identifier: Apache-2.0

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
package com.atomgraph.linkeddatahub.model;

import javax.ws.rs.core.MediaType;
import org.apache.jena.rdf.model.Resource;

/**
 * A data file.
 * Defined by its media type and SHA1 content hash.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public interface File extends Resource
{
    /**
     * Returns MIME type of the file as URI resource.
     * 
     * @return MIME type resource
     * @see com.atomgraph.linkeddatahub.MediaType#toResource
     */
    Resource getFormat();

    /**
     * Returns JAX-RS media type.
     * 
     * @return media type
     */
    MediaType getMediaType();

    /**
     * Returns SHA1 hash of the file content.
     * 
     * @return hash string
     */
    String getSHA1Hash();
    
}
