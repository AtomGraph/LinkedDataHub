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
package com.atomgraph.linkeddatahub;

import com.atomgraph.linkeddatahub.vocabulary.LDS;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.vocabulary.RDF;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

/**
 * Which dataspace a service's context is built for: the admin or end-user dataspace that names it, as the map built
 * at startup has it, so a dataspace added to the descriptions later is served the same way.
 */
public class ApplicationDataspaceOfTest
{

    private static final String END_USER = "urn:linkeddatahub:apps/x/end-user", ADMIN = "urn:linkeddatahub:apps/x/admin",
        END_USER_SERVICE = "urn:linkeddatahub:services/x/end-user", ADMIN_SERVICE = "urn:linkeddatahub:services/x/admin";

    private static Model context()
    {
        Model model = ModelFactory.createDefaultModel();
        model.createResource(END_USER).addProperty(RDF.type, LDS.EndUserDataspace).addProperty(LDS.service, model.createResource(END_USER_SERVICE));
        model.createResource(ADMIN).addProperty(RDF.type, LDS.AdminDataspace).addProperty(LDS.service, model.createResource(ADMIN_SERVICE));
        return model;
    }

    @Test
    public void theDataspaceNamingTheService()
    {
        Model context = context();
        assertEquals(context.createResource(END_USER), Application.dataspaceOf(context, context.createResource(END_USER_SERVICE)));
        assertEquals(context.createResource(ADMIN), Application.dataspaceOf(context, context.createResource(ADMIN_SERVICE)));
    }

    @Test
    public void noneForAServiceNoDataspaceNames()
    {
        Model context = context();
        assertNull(Application.dataspaceOf(context, context.createResource("urn:linkeddatahub:services/orphan")));
    }

    @Test
    public void noneForAServiceOnlyAnUntypedResourceNames()
    {
        Model context = context();
        Resource service = context.createResource("urn:linkeddatahub:services/other");
        context.createResource("urn:linkeddatahub:apps/other").addProperty(LDS.service, service); // neither kind of dataspace
        assertNull(Application.dataspaceOf(context, service));
    }

}
