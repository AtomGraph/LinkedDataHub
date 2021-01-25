/**
 *  Copyright 2020 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.resource.admin;

import com.atomgraph.client.util.DataManager;
import com.atomgraph.core.MediaTypes;
import com.atomgraph.linkeddatahub.model.Service;
import com.atomgraph.linkeddatahub.server.model.ClientUriInfo;
import com.atomgraph.processor.model.TemplateCall;
import java.net.URI;
import java.util.Collections;
import java.util.Optional;
import javax.inject.Inject;
import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.container.ResourceContext;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.SecurityContext;
import javax.ws.rs.core.UriInfo;
import javax.ws.rs.ext.Providers;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.query.Dataset;
import org.apache.jena.query.ParameterizedSparqlString;

/**
 *
 * @author Martynas Jusevičius <martynas@atomgraph.com>
 */
public class ResourceBase extends com.atomgraph.linkeddatahub.server.model.impl.ResourceBase
{
    
    private final String versionUpdate = "PREFIX  owl:  <http://www.w3.org/2002/07/owl#>\n" +
"PREFIX  rdfs: <http://www.w3.org/2000/01/rdf-schema#>\n" +
"\n" +
"DELETE {\n" +
"  GRAPH ?ontologyGraph {\n" +
"    ?ontology owl:versionInfo ?versionInfo .\n" +
"  }\n" +
"}\n" +
"INSERT {\n" +
"  GRAPH ?ontologyGraph {\n" +
"    ?ontology owl:versionInfo ?graphHash .\n" +
"  }\n" +
"}\n" +
"WHERE\n" +
"  { SELECT  ?ontologyGraph ?ontology ?versionInfo (SHA1(GROUP_CONCAT(?tripleStr ; separator=' \\n')) AS ?graphHash)\n" +
"    WHERE\n" +
"      { { SELECT  ?ontologyGraph ?ontology ?versionInfo ?s ?p ?o\n" +
"          WHERE\n" +
"            { GRAPH ?termGraph\n" +
"                { ?s  rdfs:isDefinedBy  ?ontology ;\n" +
"                      ?p                ?o\n" +
"                  GRAPH ?ontologyGraph\n" +
"                    { ?ontology  owl:versionInfo  ?versionInfo }\n" +
"                }\n" +
"            }\n" +
"        }\n" +
"        BIND(if(isURI(?s), concat(\"<\", str(?s), \">\"), concat(\"_:\", str(?s))) AS ?sStr)\n" +
"        BIND(concat(\"<\", str(?p), \">\") AS ?pStr)\n" +
"        BIND(if(isURI(?o), concat(\"<\", str(?o), \">\"), if(isBlank(?o), concat(\"_:\", str(?o)), concat(\"\\\"\", str(?o), \"\\\"\", if(( lang(?o) != \"\" ), concat(\"@\", str(lang(?o))), concat(\"^^<\", str(datatype(?o)), \">\"))))) AS ?oStr)\n" +
"        BIND(concat(?sStr, \" \", ?pStr, \" \", ?oStr, \" .\") AS ?tripleStr)\n" +
"      }\n" +
"    GROUP BY ?ontologyGraph ?ontology ?versionInfo\n" +
"    ORDER BY ?s ?p ?o datatype(?o) lcase(lang(?o))\n" +
"  }";
    
    @Inject
    public ResourceBase(@Context UriInfo uriInfo, ClientUriInfo clientUriInfo, @Context Request request, MediaTypes mediaTypes,
            Service service, com.atomgraph.linkeddatahub.apps.model.Application application,
            Ontology ontology, Optional<TemplateCall> templateCall,
            @Context HttpHeaders httpHeaders, @Context ResourceContext resourceContext,
            @Context HttpServletRequest httpServletRequest, @Context SecurityContext securityContext,
            DataManager dataManager, @Context Providers providers,
            com.atomgraph.linkeddatahub.Application system)
    {
        super(uriInfo, clientUriInfo, request, mediaTypes,
            uriInfo.getAbsolutePath(),
            service, application,
            ontology, templateCall,
            httpHeaders, resourceContext,
            httpServletRequest, securityContext,
            dataManager, providers,
            system);
    }
    
    @Override
    public Response post(Dataset dataset)
    {
        Response response = super.post(dataset);
        
        incrementOntologyVersion();
        
        return response;
    }
            
    @Override
    public Response put(Dataset dataset)
    {
        Response response = super.put(dataset);
        
        incrementOntologyVersion();

        return response;
    }
    
    @Override
    public Response delete()
    {
        Response response = super.delete();
        
        incrementOntologyVersion();

        return response;
    }

    private void incrementOntologyVersion()
    {
        ParameterizedSparqlString updateString = new ParameterizedSparqlString(versionUpdate);
        getService().getEndpointAccessor().update(updateString.asUpdate(), Collections.<URI>emptyList(), Collections.<URI>emptyList());
    }
    
}
