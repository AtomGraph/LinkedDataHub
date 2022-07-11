// Copyright 2019 Martynas Jusevičius <martynas@atomgraph.com>
// SPDX-FileCopyrightText: 2017-2022 2017 Martynas Jusevicius, <martynas@atomgraph.com> et al.
//
// SPDX-License-Identifier: Apache-2.0

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
package com.atomgraph.linkeddatahub.writer;

import java.net.URI;
import java.util.function.Supplier;

/**
 * Class representing layout mode.
 * Each mode is identified with a URI.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class Mode implements Supplier<URI>
{

    private final URI uri;

    /**
     * Constructs mode from URI string.
     * 
     * @param uri URI string
     */
    public Mode(String uri)
    {
        this.uri = URI.create(uri);
    }
    
    /**
     * Constructs mode from URI.
     * 
     * @param uri URI
     */
    public Mode(URI uri)
    {
        this.uri = uri;
    }
    
    @Override
    public URI get()
    {
        return uri;
    }

}
