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
package com.atomgraph.linkeddatahub.server.util;

import com.atomgraph.client.vocabulary.AC;
import com.atomgraph.linkeddatahub.dataspaces.model.AdminDataspace;
import com.atomgraph.linkeddatahub.dataspaces.model.EndUserDataspace;
import com.atomgraph.linkeddatahub.vocabulary.LDS;
import java.util.Set;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Property;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.rdf.model.Statement;
import org.apache.jena.rdf.model.StmtIterator;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;

/**
 * The public view of the context dataset: the dataspace descriptions, and nothing else.
 * <p>
 * The context dataset also holds the deployment's internal wiring - the SPARQL services behind each dataspace, their
 * backend endpoints, the versioning repositories - and the credentials for them. This view copies a whitelist of
 * properties of the <code>lds:Dataspace</code> resources only, so none of that can reach a stylesheet, a browser or an
 * HTTP client. It adds <code>lds:admin</code> to each end-user dataspace: the pairing the server derives from the admin
 * subdomain, published so that clients never derive it themselves.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public final class PublicContext
{

    /** The dataspace properties that are public. Everything else in the context dataset is withheld. */
    public static final Set<Property> PROPERTIES = Set.of(RDF.type, DCTerms.title, DCTerms.description,
        LDS.origin, LDS.ontology, AC.stylesheet, ResourceFactory.createProperty(LDS.NS + "public"));

    private PublicContext() { }

    /**
     * Returns the public view of a context model.
     *
     * @param context context model, with dataspace personalities registered
     * @return new model with the public dataspace descriptions
     */
    public static Model of(Model context)
    {
        if (context == null) throw new IllegalArgumentException("Context Model cannot be null");

        Model view = ModelFactory.createDefaultModel();

        ResIterator dataspaces = context.listResourcesWithProperty(RDF.type, LDS.Dataspace);
        try
        {
            while (dataspaces.hasNext())
            {
                Resource dataspace = dataspaces.next();

                StmtIterator it = dataspace.listProperties();
                try
                {
                    while (it.hasNext())
                    {
                        Statement stmt = it.next();
                        if (PROPERTIES.contains(stmt.getPredicate())) view.add(stmt);
                    }
                }
                finally
                {
                    it.close();
                }

                if (dataspace.canAs(EndUserDataspace.class))
                {
                    AdminDataspace admin = dataspace.as(EndUserDataspace.class).getAdminDataspace();
                    if (admin != null) view.add(dataspace, LDS.admin, view.createResource(admin.getBaseURI().toString()));
                }
            }
        }
        finally
        {
            dataspaces.close();
        }

        return view;
    }

}
