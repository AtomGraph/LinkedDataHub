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
package com.atomgraph.linkeddatahub.imports;

import com.atomgraph.core.client.LinkedDataClient;
import com.atomgraph.spinrdf.vocabulary.SP;
import java.net.URI;
import java.util.function.Supplier;
import javax.ws.rs.core.Response;
import org.apache.jena.query.Query;
import org.apache.jena.query.QueryFactory;
import org.apache.jena.query.Syntax;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Resource;

/**
 * SPIN query loader.
 * Loads a query resource from URI and uses it's <code>sp:text</code> property value to construct a query object.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class QueryLoader implements Supplier<Query>
{

    private final URI uri;
    private final String baseURI;
    private final Syntax syntax;
    private final LinkedDataClient ldc;
    
    /**
     * Constructs loader from query URI.
     * 
     * @param uri query URI
     * @param baseURI base URI
     * @param ldc Linked Data client
     */
    public QueryLoader(URI uri, String baseURI, LinkedDataClient ldc)
    {
        this(uri, baseURI, Syntax.syntaxSPARQL_11, ldc);
    }
    
    /**
     * Constructs loader from query URI.
     * 
     * @param uri query URI
     * @param baseURI base URI
     * @param syntax query syntax
     * @param ldc Linked Data client
     */
    public QueryLoader(URI uri, String baseURI, Syntax syntax, LinkedDataClient ldc)
    {
        this.uri = uri;
        this.baseURI = baseURI;
        this.syntax = syntax;
        this.ldc = ldc;
    }
    
    @Override
    public Query get()
    {
        try (Response cr = getLinkedDataClient().get(getURI()))
        {
            Resource queryRes = cr.readEntity(Model.class).getResource(getURI().toString());
            return QueryFactory.create(queryRes.getRequiredProperty(SP.text).getString(), getBaseURI(), getSyntax());
        }
    }

    /**
     * Returns query URI.
     * 
     * @return query URI
     */
    public URI getURI()
    {
        return uri;
    }

    /**
     * Returns query base URI.
     * 
     * @return base URI
     */
    public String getBaseURI()
    {
        return baseURI;
    }

    /**
     * Returns SPARQL syntax.
     * 
     * @return syntax
     */
    public Syntax getSyntax()
    {
        return syntax;
    }
    
    /**
     * Returns Linked Data client.
     * 
     * @return Linked Data client
     */
    public LinkedDataClient getLinkedDataClient()
    {
        return ldc;
    }
    
}
