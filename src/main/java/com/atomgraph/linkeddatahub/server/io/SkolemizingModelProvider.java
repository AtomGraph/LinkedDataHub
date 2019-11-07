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

import org.apache.jena.ontology.OntDocumentManager;
import org.apache.jena.query.QueryFactory;
import org.apache.jena.query.QueryParseException;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.sparql.vocabulary.FOAF;
import org.apache.jena.update.UpdateFactory;
import org.apache.jena.update.UpdateRequest;
import org.apache.jena.vocabulary.RDF;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.List;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.UriInfo;
import javax.ws.rs.ext.Providers;
import org.apache.jena.rdf.model.RDFWriter;
import org.apache.jena.rdfxml.xmloutput.impl.Basic;
import org.apache.jena.riot.Lang;
import org.apache.jena.riot.system.ParserProfile;
import org.apache.jena.riot.system.RiotLib;
import com.atomgraph.linkeddatahub.exception.RDFSyntaxException;
import com.atomgraph.linkeddatahub.vocabulary.LSM;
import com.atomgraph.processor.vocabulary.DH;
import com.atomgraph.server.exception.ConstraintViolationException;
import com.atomgraph.processor.vocabulary.SIOC;
import java.util.Set;
import java.util.UUID;
import org.apache.jena.ontology.OntClass;
import org.apache.jena.rdf.model.Statement;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.spinrdf.constraints.ConstraintViolation;
import org.spinrdf.constraints.ObjectPropertyPath;
import org.spinrdf.constraints.SimplePropertyPath;
import org.spinrdf.util.JenaUtil;
import org.spinrdf.vocabulary.SP;

/**
 * JAX-RS provider that skolemizes blank node resources in the input RDF model.
 * It also fixes values of various properties.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class SkolemizingModelProvider extends com.atomgraph.server.io.SkolemizingModelProvider
{
    private static final Logger log = LoggerFactory.getLogger(SkolemizingModelProvider.class);
    
    @Context UriInfo uriInfo;
    @Context Providers providers;

    @Override
    public Model read(Model model, InputStream is, Lang lang, String baseURI)
    {
        if (lang == null) throw new IllegalArgumentException("Lang must be not null");

        CollectingErrorHandler errorHandler = new CollectingErrorHandler(); // collect parse errors. do not throw exceptions
        ParserProfile parserProfile = RiotLib.profile(baseURI, true, true, errorHandler);
        read(model, is, lang, baseURI, errorHandler, parserProfile);

        if (!errorHandler.getViolations().isEmpty())
        {
            if (log.isDebugEnabled()) log.debug("RDF syntax errors detected while parsing model: {}", errorHandler.getViolations());
            throw new RDFSyntaxException(errorHandler.getViolations(), model);
        }

        return model;
    }

    @Override
    public Model write(Model model, OutputStream os, Lang lang, String baseURI)
    {
        if (lang == null) throw new IllegalArgumentException("Lang must be not null");
        
        if (lang.equals(Lang.RDFXML)) // round-tripping RDF/XML with user input may contain invalid URIs
        {
            //RDFWriter writer = model.getWriter(RDFLanguages.RDFXML.getName());
            RDFWriter writer = new Basic(); // workaround for Jena 3.0.1 bug: https://issues.apache.org/jira/browse/JENA-1168
            writer.setProperty("allowBadURIs", true);
            writer.write(model, os, null);

            return model;
        }

        return super.write(model, os, lang, baseURI);
    }
    
    @Override
    public Model process(Model model)
    {   
        ResIterator it = model.listSubjects();
        try
        {
            while (it.hasNext())
            {
                Resource resource = it.next();
                process(resource);
            }
        }
        finally
        {
            it.close();
        }

        return super.process(model); // apply processing from superclasses
    }
    
    @Override
    public Resource process(Resource resource) // this logic really belongs in a ContainerRequestFilter but we don't want to buffer and re-serialize the Model
    {
        super.process(resource);
        
        if (!resource.hasProperty(DH.slug))
        {
            Statement typeStmt = resource.getProperty(RDF.type);
            if (typeStmt != null && typeStmt.getObject().isURIResource())
            {
                OntClass ontClass = getOntology().getOntModel().getOntClass(typeStmt.getResource().getURI());
                if (ontClass != null)
                {
                    // cannot use ontClass.hasSuperClass() here as it does not traverse the chain
                    Set<Resource> superClasses = JenaUtil.getAllSuperClasses(ontClass);
                    if (superClasses.contains(DH.Container) || superClasses.contains(DH.Item))
                        resource.addLiteral(DH.slug, UUID.randomUUID().toString());
                }
            }
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
                throw new ConstraintViolationException(cvs, resource.getModel());
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
                throw new ConstraintViolationException(cvs, resource.getModel());
            }
        }
        
        if (resource.hasProperty(RDF.type, LSM.Ontology))
        {
            // clear cached OntModel if ontology is updated. TO-DO: send event instead
            OntDocumentManager.getInstance().getFileManager().removeCacheModel(resource.getURI());
        }
        
        return resource;
    }

    @Override
    public UriInfo getUriInfo()
    {
        return uriInfo;
    }
    
}