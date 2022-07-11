// Copyright 2022 Martynas Jusevičius <martynas@atomgraph.com>
// SPDX-FileCopyrightText: 2017-2022 2017 Martynas Jusevicius, <martynas@atomgraph.com> et al.
//
// SPDX-License-Identifier: Apache-2.0

package com.atomgraph.linkeddatahub.model.auth;

import java.net.URI;
import java.util.Set;
import org.apache.jena.rdf.model.Resource;

/**
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public interface Authorization extends Resource
{
    
    Set<Resource> getModes();
    
    Set<URI> getModeURIs();
    
}
