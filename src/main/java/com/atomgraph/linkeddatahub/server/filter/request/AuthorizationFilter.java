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
package com.atomgraph.linkeddatahub.server.filter.request;

import com.atomgraph.linkeddatahub.server.exception.auth.AuthorizationException;
import com.atomgraph.linkeddatahub.model.auth.Agent;
import com.atomgraph.linkeddatahub.server.security.AccessModes;
import com.atomgraph.linkeddatahub.server.security.AuthorizationContext;
import com.atomgraph.linkeddatahub.server.util.Authorizer;
import com.atomgraph.linkeddatahub.server.util.DocumentContext;
import com.atomgraph.linkeddatahub.server.util.UploadRecords;
import com.atomgraph.linkeddatahub.server.model.impl.DocumentHierarchyGraphStoreImpl;
import com.atomgraph.linkeddatahub.vocabulary.ACL;
import com.atomgraph.linkeddatahub.vocabulary.DH;
import com.atomgraph.linkeddatahub.vocabulary.Default;
import java.io.IOException;
import java.net.URI;
import java.nio.file.Path;
import java.util.List;
import java.util.Collections;
import java.util.Map;
import java.util.Optional;
import jakarta.annotation.Priority;
import jakarta.inject.Inject;
import jakarta.ws.rs.HttpMethod;
import jakarta.ws.rs.InternalServerErrorException;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.container.PreMatching;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.PathSegment;
import org.apache.jena.irix.IRIx;
import java.util.Set;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Authorization request filter.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@PreMatching
@Priority(Priorities.USER + 100) // has to execute after all AuthenticationFilters
public class AuthorizationFilter implements ContainerRequestFilter
{
    private static final Logger log = LoggerFactory.getLogger(AuthorizationFilter.class);

    /**
     * A mapping of HTTP methods to ACL access modes.
     */
    public static final Map<String, Resource> ACCESS_MODES = Map.of(
        HttpMethod.GET, ACL.Read,
        HttpMethod.HEAD, ACL.Read,
        HttpMethod.POST, ACL.Append,
        HttpMethod.PUT, ACL.Write,
        HttpMethod.DELETE, ACL.Write,
        HttpMethod.PATCH, ACL.Write
    );
    
    @Inject com.atomgraph.linkeddatahub.Application system;
    @Inject jakarta.inject.Provider<Optional<com.atomgraph.linkeddatahub.dataspaces.model.Dataspace>> app;
    @Inject jakarta.inject.Provider<Optional<com.atomgraph.linkeddatahub.dataspaces.model.Dataset>> dataset;

    @Override
    public void filter(ContainerRequestContext request) throws IOException
    {
        if (request == null) throw new IllegalArgumentException("ContainerRequestContext cannot be null");
        if (log.isDebugEnabled()) log.debug("Authorizing request URI: {}", request.getUriInfo().getRequestUri());

        Resource accessMode = getAccessMode(request.getMethod(), request.getHeaderString(HttpHeaders.IF_NONE_MATCH));
        if (log.isDebugEnabled()) log.debug("Request method: {} ACL access mode: {}", request.getMethod(), accessMode);
        if (accessMode == null)
        {
            if (log.isWarnEnabled()) log.warn("Skipping authentication/authorization, request method not recognized: {}", request.getMethod());
            return;
        }

        if (getDataspace().isPresent() && getDataspace().get().isReadAllowed())
        {
            if (request.getMethod().equals(HttpMethod.GET) || request.getMethod().equals(HttpMethod.HEAD)) // allow read-only methods
            {
                if (log.isTraceEnabled()) log.trace("Read methods are allowed on app, skipping authorization for request URI: {}", request.getUriInfo().getAbsolutePath());
                return;
            }
        }

        final Agent agent;
        if (request.getSecurityContext().getUserPrincipal() instanceof Agent) agent = ((Agent)(request.getSecurityContext().getUserPrincipal()));
        else agent = null; // public access

        Model authorizations = authorize(request, agent, accessMode);

        // HEAD is how a client learns a document's entity tag, and a conditional write needs one. Requiring
        // acl:Read for it would leave an agent that may write but not read unable to satisfy the precondition
        // the graph store demands of every write to a document that already exists - quietly turning acl:Write
        // into acl:Write AND acl:Read, a coupling no authorization document states. So a HEAD is granted to any
        // agent with a mode on the document: it carries no body, and a non-reader's is trimmed to the validator
        // and the modes by ResponseHeadersFilter. GET is untouched - content still needs acl:Read. acl:Append is
        // the least of the write modes, so a grant of either one covers it.
        if (authorizations == null && HttpMethod.HEAD.equals(request.getMethod()))
            authorizations = authorize(request, agent, ACL.Append);

        if (authorizations == null)
        {
            if (log.isTraceEnabled()) log.trace("Access not authorized for request URI: {} and access mode: {}", request.getUriInfo().getAbsolutePath(), accessMode);
            throw new AuthorizationException("Access not authorized for request URI", request.getUriInfo().getAbsolutePath(), accessMode);
        }
        else // authorization successful
            request.setProperty(AuthorizationContext.class.getCanonicalName(), new AuthorizationContext(authorizations));
    }
    
    /**
     * Returns authorization for the current request.
     * One decision serves both dataspaces: the document context query reads what the dataspace's store says of the
     * document - itself, its ancestors, its types and its owner, each from the document's own graph - and the ACL query
     * matches the authorizations in the admin dataset against it.
     * 
     * @param request current request
     * @param agent agent resource or null
     * @param accessMode ACL access mode
     * @return authorizations model or null if access denied
     */
    public Model authorize(ContainerRequestContext request, Resource agent, Resource accessMode)
    {
        Resource accessTo = ResourceFactory.createResource(request.getUriInfo().getAbsolutePath().toString());

        // special case for PUT requests: if the document does not exist, check access on the *parent* URI instead -
        // acl:Write for a plain PUT, acl:Append for a create-only one (see getAccessMode()). Whether it exists is the
        // graph store's to say, the same answer put() acts on: having types is not the same thing, since the context query
        // also types an uploaded file, which has no graph of its own
        if (request.getMethod().equals(HttpMethod.PUT) && !getSystem().getServiceContext(getDataspace().get().getService()).getGraphStoreClient().containsModel(accessTo.getURI()))
        {
            // Use Jena's IRIx for RFC 3986-compliant resolution - java.net.URI.resolve("..") is non-compliant
            // (RFC 3986 section 5.2.4 step 2D requires ".." to be removed, but java.net.URI leaves it literal)
            Resource parent = ResourceFactory.createResource(IRIx.create(accessTo.getURI()).resolve("..").toString());
            log.debug("Requested document <{}> not found, falling back to parent URI <{}>", accessTo, parent);

            DocumentContext parentContext = getAuthorizer().getDocumentContext(parent);
            // only root and containers allow child documents
            if (Collections.disjoint(parentContext.getTypes(), Set.of(Default.Root, DH.Container))) return null;

            return getAuthorizer().authorize(parentContext, agent, accessMode); // the document does not exist yet: its container decides
        }

        Model authorizations = getAuthorizer().authorize(getAuthorizer().getDocumentContext(accessTo), agent, accessMode);
        if (authorizations == null && ACL.Read.equals(accessMode)) return authorizeUpload(request, agent);

        return authorizations;
    }

    /**
     * Returns the agent's authorizations to read an upload through a document it was uploaded into, or null if the
     * request is not for an upload or the agent may read none of them.
     * An upload has no graph of its own, so its own context names it only by its URI and <code>nfo:FileDataObject</code>,
     * and a grant on one document did not reach the files uploaded into it. The documents are the platform's record
     * ({@link UploadRecords}), written when a write that uploads the bytes goes ahead: which documents describe the file
     * is any writer's to say, which document it was uploaded into is not (formal/uploads, <code>upload_readable</code>).
     * A document of another dataspace sharing the upload folder is that dataspace's to decide, so only this one's count.
     *
     * @param request current request
     * @param agent agent resource or null
     * @return authorizations model or null if access denied
     */
    public Model authorizeUpload(ContainerRequestContext request, Resource agent)
    {
        List<PathSegment> segments = request.getUriInfo().getPathSegments();
        if (segments.size() != 2 || !DocumentHierarchyGraphStoreImpl.UPLOADS_PATH.equals(segments.get(0).getPath()) ||
            !UploadRecords.SHA1.matcher(segments.get(1).getPath()).matches()) return null;

        final List<URI> documents;
        try
        {
            documents = UploadRecords.getDocuments(Path.of(getSystem().getUploadRoot().resolve(request.getUriInfo().getPath())).getParent(), segments.get(1).getPath());
        }
        catch (IOException ex)
        {
            throw new InternalServerErrorException(ex);
        }

        String base = getDataspace().get().getBase().getURI();
        for (URI document : documents)
        {
            if (!document.toString().startsWith(base)) continue;

            Resource uploadedInto = ResourceFactory.createResource(document.toString());
            Model authorizations = getAuthorizer().authorize(getAuthorizer().getDocumentContext(uploadedInto), agent, ACL.Read);
            if (authorizations != null) return authorizations;
        }

        return null;
    }

    /**
     * Returns the access mode a request requires.
     * The mode follows what the operation does, which the method alone does not always tell. A PUT with
     * <code>If-None-Match: *</code> can only create a document: the graph store refuses it with
     * <code>412 Precondition Failed</code> when the document exists, evaluating the precondition under the
     * document's write lock. Creating a document removes nothing - containment is stored in the child's own
     * graph, so the container's graph is untouched - and an access that only adds information is what
     * <code>acl:Append</code> is. A grant of <code>acl:Write</code> still covers it (see {@link AccessModes}).
     *
     * @param method HTTP method
     * @param ifNoneMatch <code>If-None-Match</code> header value, or <code>null</code>
     * @return ACL access mode, or <code>null</code> if the method is not recognized
     */
    public static Resource getAccessMode(String method, String ifNoneMatch)
    {
        if (HttpMethod.PUT.equals(method) && ifNoneMatch != null && ifNoneMatch.strip().equals("*")) return ACL.Append;

        return ACCESS_MODES.get(method);
    }

    /**
     * Returns the authorization decision of the matched dataspace.
     *
     * @return authorizer
     */
    public Authorizer getAuthorizer()
    {
        return new Authorizer(getSystem(), getDataspace().get());
    }

    /**
     * Returns currently matched application.
     *
     * @return optional application resource
     */
    public Optional<com.atomgraph.linkeddatahub.dataspaces.model.Dataspace> getDataspace()
    {
        return app.get();
    }

    /**
     * Returns currently matched dataset (optional).
     * 
     * @return optional dataset resource
     */
    public Optional<com.atomgraph.linkeddatahub.dataspaces.model.Dataset> getDataset()
    {
        return dataset.get();
    }

    /**
     * Returns system application.
     * 
     * @return JAX-RS application
     */
    public com.atomgraph.linkeddatahub.Application getSystem()
    {
        return system;
    }
    
}