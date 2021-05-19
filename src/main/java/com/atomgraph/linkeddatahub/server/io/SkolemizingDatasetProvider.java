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
package com.atomgraph.linkeddatahub.server.io;

import com.atomgraph.linkeddatahub.server.util.Skolemizer;
import com.atomgraph.linkeddatahub.vocabulary.LSM;
import com.atomgraph.processor.vocabulary.DH;
import com.atomgraph.processor.vocabulary.SIOC;
import com.atomgraph.server.exception.SPINConstraintViolationException;
import com.atomgraph.server.exception.SkolemizationException;
import com.atomgraph.spinrdf.constraints.ConstraintViolation;
import com.atomgraph.spinrdf.constraints.ObjectPropertyPath;
import com.atomgraph.spinrdf.constraints.SimplePropertyPath;
import com.atomgraph.spinrdf.vocabulary.SP;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.UriBuilder;
import org.apache.jena.ontology.OntClass;
import org.apache.jena.ontology.OntDocumentManager;
import org.apache.jena.ontology.Ontology;
import org.apache.jena.query.QueryFactory;
import org.apache.jena.query.QueryParseException;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.Statement;
import org.apache.jena.sparql.vocabulary.FOAF;
import org.apache.jena.update.UpdateFactory;
import org.apache.jena.update.UpdateRequest;
import org.apache.jena.vocabulary.DCTerms;
import org.apache.jena.vocabulary.RDF;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


/**
 * JAX-RS provider that skolemizes blank node resources in the input RDF dataset.
 * It also fixes values of various properties.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class SkolemizingDatasetProvider extends com.atomgraph.server.io.SkolemizingDatasetProvider
{
    
    private static final Logger log = LoggerFactory.getLogger(SkolemizingDatasetProvider.class);

    @Override
    public Model skolemize(Ontology ontology, UriBuilder baseUriBuilder, UriBuilder absolutePathBuilder, Model model)
    {
        try
        {
            return new Skolemizer(ontology, baseUriBuilder, absolutePathBuilder).build(model); // not optimal to create Skolemizer for each Model
        }
        catch (IllegalArgumentException ex)
        {
            throw new SkolemizationException(ex, model);
        }
    }
    
    @Override
    public Resource process(Resource resource) // this logic really belongs in a ContainerRequestFilter but we don't want to buffer and re-serialize the Model
    {
        super.process(resource);
        
        if (getOntology().isPresent() && !resource.hasProperty(DH.slug))
        {
            Statement typeStmt = resource.getProperty(RDF.type);
            if (typeStmt != null && typeStmt.getObject().isURIResource())
            {
                OntClass ontClass = getOntology().get().getOntModel().getOntClass(typeStmt.getResource().getURI());
                if (ontClass != null)
                {
                    // cannot use ontClass.hasSuperClass() here as it does not traverse the chain
                    Set<OntClass> superClasses = ontClass.listSuperClasses().toSet();
                    if (superClasses.contains(DH.Container) || superClasses.contains(DH.Item))
                        resource.addLiteral(DH.slug, UUID.randomUUID().toString());
                }
            }
        }

        if (resource.hasProperty(DCTerms.format) && resource.getProperty(DCTerms.format).getObject().isLiteral())
        {
            Resource format = resource.getProperty(DCTerms.format).
                changeObject(com.atomgraph.linkeddatahub.MediaType.toResource(MediaType.valueOf(resource.getProperty(DCTerms.format).getString()))).getResource();
            if (log.isDebugEnabled()) log.debug("Resource: {} Format: {}", resource, format);
        }

        if (resource.hasProperty(FOAF.mbox) && resource.getProperty(FOAF.mbox).getObject().isLiteral())
        {
            Resource email = resource.getProperty(FOAF.mbox).
                changeObject(resource.getModel().createResource("mailto:" + resource.getProperty(FOAF.mbox).getString())).getResource();
            if (log.isDebugEnabled()) log.debug("Resource: {} Email: {}", resource, email);
        }

        if (resource.hasProperty(FOAF.phone) && resource.getProperty(FOAF.phone).getObject().isLiteral())
        {
            Resource phone = resource.getProperty(FOAF.phone).
                changeObject(resource.getModel().createResource("tel:" + resource.getProperty(FOAF.phone).getString())).getResource();
            if (log.isDebugEnabled()) log.debug("Resource: {} Phone: {}", resource, phone);
        }

        if (resource.hasProperty(SIOC.EMAIL) && resource.getProperty(SIOC.EMAIL).getObject().isLiteral())
        {
            Resource email = resource.getProperty(SIOC.EMAIL).
                changeObject(resource.getModel().createResource("mailto:" + resource.getProperty(SIOC.EMAIL).getString())).getResource();
            if (log.isDebugEnabled()) log.debug("Resource: {} Email: {}", resource, email);
        }
        
        // password only used during WebID signup from now on
        /*
        if (resource.hasProperty(LACL.password) && resource.getProperty(LACL.password).getObject().isLiteral())
        {
            String passwordShaHex = BCrypt.hashpw(resource.getProperty(LACL.password).getString(), BCrypt.gensalt());
            RDFNode password = resource.removeAll(LACL.password).
                addProperty(LACL.passwordHash, passwordShaHex);
            if (log.isDebugEnabled()) log.debug("Resource: {} Password BCrypt hash: {}", resource, password);
        }
        */

        if (resource.hasProperty(SP.text) && resource.getProperty(SP.text).getObject().isLiteral())
        {
            try
            {
                String queryString = resource.getProperty(SP.text).getString();
                QueryFactory.create(queryString);
            }
            catch (QueryParseException ex)
            {
                if (log.isDebugEnabled()) log.debug("Bad request - SPARQL query is syntactically incorrect", ex);
                List<ConstraintViolation> cvs = new ArrayList<>();
                List<SimplePropertyPath> paths = new ArrayList<>();
                paths.add(new ObjectPropertyPath(resource, SP.text));
                cvs.add(new ConstraintViolation(resource, paths, null, ex.getMessage(), null));
                throw new SPINConstraintViolationException(cvs, resource.getModel());
            }
        }
        
        if (resource.hasProperty(RDF.type, SP.Update) &&
                resource.hasProperty(SP.text) &&
                resource.getProperty(SP.text).getObject().isLiteral())
        {
            String updateString = resource.getProperty(SP.text).getString();
            try
            {
                UpdateRequest update = UpdateFactory.create(updateString);
                Resource type = null;
                if (type != null)
                {
                    resource.addProperty(RDF.type, type);
                    if (log.isDebugEnabled()) log.debug("Resource: {} adding type: {}", resource, type);
                }
            }
            catch (QueryParseException ex)
            {
                if (log.isDebugEnabled()) log.debug("Bad request - SPARQL update is syntactically incorrect", ex);
                List<ConstraintViolation> cvs = new ArrayList<>();
                List<SimplePropertyPath> paths = new ArrayList<>();
                paths.add(new ObjectPropertyPath(resource, SP.text));
                cvs.add(new ConstraintViolation(resource, paths, null, ex.getMessage(), null));
                throw new SPINConstraintViolationException(cvs, resource.getModel());
            }
        }
        
        if (resource.hasProperty(RDF.type, LSM.Ontology))
        {
            // clear cached OntModel if ontology is updated. TO-DO: send event instead
            OntDocumentManager.getInstance().getFileManager().removeCacheModel(resource.getURI());
        }
        
        return resource;
    }
    
}
