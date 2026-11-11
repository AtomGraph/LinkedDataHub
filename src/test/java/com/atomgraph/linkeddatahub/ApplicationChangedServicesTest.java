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
import org.apache.jena.query.Dataset;
import org.apache.jena.query.DatasetFactory;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;
import org.junit.jupiter.api.Test;

import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * Which services' contexts a reload makes anew: those whose description differs between what was served and what
 * is served now, including services gone or new.
 */
public class ApplicationChangedServicesTest
{

    private static final String APP = "urn:linkeddatahub:apps/x/end-user", SERVICE = "urn:linkeddatahub:services/x/end-user",
        OTHER_APP = "urn:linkeddatahub:apps/y/end-user", OTHER = "urn:linkeddatahub:services/y/end-user";

    private static Dataset descriptions(String endpoint, boolean withOther)
    {
        Dataset dataset = DatasetFactory.create();
        Model app = ModelFactory.createDefaultModel();
        app.createResource(APP).addProperty(RDF.type, LDS.EndUserDataspace).addProperty(LDS.service, app.createResource(SERVICE));
        dataset.addNamedModel(APP, app);
        Model service = ModelFactory.createDefaultModel();
        service.createResource(SERVICE).addProperty(DCTerms.title, "X").addProperty(service.createProperty("http://www.w3.org/ns/sparql-service-description#endpoint"), service.createResource(endpoint));
        dataset.addNamedModel(SERVICE, service);
        if (withOther)
        {
            Model other = ModelFactory.createDefaultModel();
            other.createResource(OTHER_APP).addProperty(RDF.type, LDS.EndUserDataspace).addProperty(LDS.service, other.createResource(OTHER));
            dataset.addNamedModel(OTHER_APP, other);
            dataset.addNamedModel(OTHER, ModelFactory.createDefaultModel().add(ModelFactory.createDefaultModel().createResource(OTHER), DCTerms.title, "Y"));
        }
        return dataset;
    }

    @Test
    public void testTheSameDescriptionsChangeNothing()
    {
        assertEquals(Set.of(), Application.changedServices(descriptions("http://fuseki:3030/x/", false), descriptions("http://fuseki:3030/x/", false)));
    }

    @Test
    public void testADescribedOtherwiseServiceChanged()
    {
        assertEquals(Set.of(SERVICE), Application.changedServices(descriptions("http://fuseki:3030/x/", false), descriptions("http://fuseki:3030/x2/", false)));
    }

    @Test
    public void testANewOrGoneServiceChanged()
    {
        assertEquals(Set.of(OTHER), Application.changedServices(descriptions("http://fuseki:3030/x/", false), descriptions("http://fuseki:3030/x/", true)), "new");
        assertEquals(Set.of(OTHER), Application.changedServices(descriptions("http://fuseki:3030/x/", true), descriptions("http://fuseki:3030/x/", false)), "gone");
    }

}
