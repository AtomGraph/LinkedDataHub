// Copyright 2022 Martynas Jusevičius <martynas@atomgraph.com>
// SPDX-FileCopyrightText: 2017-2022 2017 Martynas Jusevicius, <martynas@atomgraph.com> et al.
//
// SPDX-License-Identifier: Apache-2.0

package com.atomgraph.linkeddatahub.server.security;

import com.atomgraph.linkeddatahub.model.auth.Authorization;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import java.net.URI;
import java.util.HashSet;
import java.util.Set;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.vocabulary.RDF;

/**
 * Authorization context.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class AuthorizationContext
{

    public final Model authorizationModel;
    
    public AuthorizationContext(Model authorizationModel)
    {
        this.authorizationModel = authorizationModel;
    }
    
    public Set<URI> getModeURIs()
    {
        Set<URI> modeURIs = new HashSet<>();
        
        ResIterator it = authorizationModel.listSubjectsWithProperty(RDF.type, ACL.Authorization);
        try
        {
            while (it.hasNext())
            {
                Authorization auth = it.next().as(Authorization.class);
                modeURIs.addAll(auth.getModeURIs());
            }
            
            return modeURIs;
        }
        finally
        {
            it.close();
        }
    }
    
}
