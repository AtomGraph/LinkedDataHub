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
package com.atomgraph.linkeddatahub.server.mapper.auth.webid;

import com.atomgraph.linkeddatahub.server.exception.auth.webid.InvalidWebIDPublicKeyException;
import com.atomgraph.linkeddatahub.vocabulary.Cert;
import com.atomgraph.linkeddatahub.vocabulary.LACL;
import com.atomgraph.linkeddatahub.vocabulary.PROV;
import com.atomgraph.server.mapper.ExceptionMapperBase;
import javax.ws.rs.core.Response;
import javax.ws.rs.ext.ExceptionMapper;
import org.apache.jena.datatypes.xsd.XSDDatatype;
import org.apache.jena.query.DatasetFactory;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.apache.jena.vocabulary.RDF;

/**
 * JAX-RS mapper for invalid WebID public key exceptions.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class InvalidWebIDPublicKeyExceptionMapper extends ExceptionMapperBase implements ExceptionMapper<InvalidWebIDPublicKeyException>
{
    // TO-DO: use a non-standard SSL-specific status code such as 495 SSL Certificate Error?
    // https://en.wikipedia.org/wiki/List_of_HTTP_status_codes#nginx
    @Override
    public Response toResponse(InvalidWebIDPublicKeyException ex)
    {
        Resource resource = toResource(ex, Response.Status.BAD_REQUEST,
                    ResourceFactory.createResource("http://www.w3.org/2011/http-statusCodes#BadRequest"));
        
        // if public key is provided, append its metadata to the error response
        if (ex.getPublicKey() != null)
            resource.addProperty(PROV.wasDerivedFrom, resource.getModel().createResource().
                addProperty(RDF.type, LACL.PublicKey).
                addLiteral(Cert.modulus, ResourceFactory.createTypedLiteral(ex.getPublicKey().getModulus().toString(16), XSDDatatype.XSDhexBinary)).
                addLiteral(Cert.exponent, ResourceFactory.createTypedLiteral(ex.getPublicKey().getPublicExponent())));
                
        return getResponseBuilder(DatasetFactory.create(resource.getModel())).
            status(Response.Status.BAD_REQUEST).
            build();
    }
    
}
