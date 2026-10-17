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
package com.atomgraph.linkeddatahub.servlet;

import com.atomgraph.linkeddatahub.Application;
import com.atomgraph.linkeddatahub.dataspaces.model.AdminDataspace;
import com.atomgraph.linkeddatahub.dataspaces.model.Dataspace;
import com.atomgraph.linkeddatahub.dataspaces.model.EndUserDataspace;
import com.atomgraph.linkeddatahub.model.Service;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.ws.rs.core.Response;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
import java.io.UncheckedIOException;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.regex.Pattern;
import javax.xml.stream.XMLOutputFactory;
import javax.xml.stream.XMLStreamException;
import javax.xml.stream.XMLStreamWriter;
import org.apache.jena.datatypes.xsd.XSDDatatype;
import org.apache.jena.graph.Node;
import org.apache.jena.graph.NodeFactory;
import org.apache.jena.query.Query;
import org.apache.jena.query.QueryFactory;
import org.apache.jena.query.QuerySolution;
import org.apache.jena.query.ResultSet;
import org.apache.jena.query.ResultSetRewindable;
import org.apache.jena.rdf.model.Literal;
import org.apache.jena.rdf.model.RDFNode;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.sparql.core.Var;
import org.apache.jena.sparql.engine.binding.BindingFactory;
import org.apache.jena.sparql.expr.NodeValue;
import org.apache.jena.sparql.syntax.Element;
import org.apache.jena.sparql.syntax.ElementData;
import org.apache.jena.sparql.syntax.syntaxtransform.ElementTransformCopyBase;
import org.apache.jena.sparql.syntax.syntaxtransform.QueryTransformOps;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Serves the <a href="https://www.sitemaps.org/protocol.html">sitemap</a> and <code>robots.txt</code> of a dataspace.
 * Neither is a document of the dataspace, so they are answered here instead of in JAX-RS, outside of its
 * authentication and authorization; what makes them per-dataspace is the request's origin.
 * <p>
 * A dataspace lists the documents a public read rule of its own grants access to. <code>/sitemap.xml</code> is a
 * sitemap index over buckets, the first hex digits of the MD5 of a document's URI, and
 * <code>/sitemap.xml?bucket={prefix}</code> is the sitemap of one bucket. The prefix is as short as keeps every
 * bucket within the protocol's limit, and a dataspace small enough for a single sitemap serves it as
 * <code>/sitemap.xml</code> itself. Queried on every request, so the sitemap is as current as the store; the
 * responses carry a max-age for the frontend cache.
 * <p>
 * Opt-in through the <code>com.atomgraph.linkeddatahub.enableSitemap</code> system property: the queries walk every
 * public document of the dataspace.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class SitemapServlet extends HttpServlet
{

    private static final Logger log = LoggerFactory.getLogger(SitemapServlet.class);

    /** Path of the sitemap */
    public static final String SITEMAP_PATH = "/sitemap.xml";
    /** Path of the robots exclusion file */
    public static final String ROBOTS_PATH = "/robots.txt";
    /** Query parameter selecting the bucket */
    public static final String BUCKET_PARAM = "bucket";
    /** Max number of URLs in a sitemap, and of sitemaps in a sitemap index */
    public static final int MAX_URLS = 50000;
    /** Length of the bucket prefix the index query groups by; the index merges its groups into shorter prefixes */
    public static final int MAX_BUCKET_LENGTH = 2;
    /** Sitemap namespace */
    public static final String NS = "http://www.sitemaps.org/schemas/sitemap/0.9";
    /** <code>Cache-Control</code> of the responses */
    public static final String CACHE_CONTROL = "public, max-age=3600";

    private static final Pattern BUCKET_PATTERN = Pattern.compile("^[0-9a-f]{1," + MAX_BUCKET_LENGTH + "}$");
    private static final Var TYPE_VAR = Var.alloc("Type"), LOC_VAR = Var.alloc("loc"), TO_VAR = Var.alloc("to");

    private boolean enabled;
    private Query publicRulesQuery, publicDocumentQuery, indexQuery, sitemapQuery;

    @Override
    public void init() throws ServletException
    {
        enabled = Boolean.parseBoolean(System.getProperty("com.atomgraph.linkeddatahub.enableSitemap"));
        publicRulesQuery = loadQuery("public-rules.rq");
        publicDocumentQuery = loadQuery("public-document.rq");
        indexQuery = loadQuery("sitemap-index.rq");
        sitemapQuery = loadQuery("sitemap.rq");
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException
    {
        Application system = (Application)getServletContext().getAttribute(Application.class.getName());
        if (system == null) // the JAX-RS application has not initialized yet
        {
            resp.setHeader("Cache-Control", "no-store");
            resp.setHeader("Retry-After", "60");
            resp.sendError(HttpServletResponse.SC_SERVICE_UNAVAILABLE);
            return;
        }

        // a 404 included, which the frontend cache would otherwise keep for its default TTL
        resp.setHeader("Cache-Control", CACHE_CONTROL);

        Resource app = system.matchApp(URI.create(req.getRequestURL().toString()));
        if (app == null)
        {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        // only an end-user dataspace with its admin app has documents to list; an admin dataspace, which describes
        // agents, keys and authorizations, never does
        EndUserDataspace endUserApp = app.canAs(EndUserDataspace.class) ? app.as(EndUserDataspace.class) : null;
        AdminDataspace adminApp = endUserApp != null ? endUserApp.getAdminDataspace() : null;

        try
        {
            if (req.getServletPath().equals(ROBOTS_PATH))
                writeRobots(resp, enabled && adminApp != null && hasPublicDocument(system, endUserApp, getPublicRules(system, adminApp)) ? endUserApp : null);
            else
            {
                if (!enabled || adminApp == null)
                {
                    resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                    return;
                }

                String bucket = req.getParameter(BUCKET_PARAM);
                if (bucket != null && !BUCKET_PATTERN.matcher(bucket).matches())
                {
                    resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                    return;
                }

                ResultSetRewindable publicRules = getPublicRules(system, adminApp);
                if (bucket != null) writeSitemap(resp, system, endUserApp, publicRules, bucket);
                else writeIndex(resp, system, endUserApp, publicRules);
            }
        }
        catch (XMLStreamException ex)
        {
            throw new ServletException(ex);
        }
        catch (RuntimeException ex) // the store failed to answer
        {
            if (log.isErrorEnabled()) log.error("Could not query the sitemap of <{}>", app, ex);
            resp.setHeader("Cache-Control", "no-store");
            resp.sendError(HttpServletResponse.SC_BAD_GATEWAY);
        }
    }

    /**
     * Writes the robots exclusion file. Having a sitemap is what makes a dataspace crawlable.
     *
     * @param resp servlet response
     * @param app the dataspace whose sitemap to name, or null if crawling is disallowed
     * @throws IOException I/O error
     */
    public void writeRobots(HttpServletResponse resp, Dataspace app) throws IOException
    {
        resp.setContentType("text/plain");
        resp.setCharacterEncoding(StandardCharsets.UTF_8.name());

        PrintWriter writer = resp.getWriter();
        writer.print("User-agent: *\n");
        if (app != null)
        {
            writer.print("Allow: /\n");
            writer.print("Sitemap: " + app.getBaseURI().resolve(SITEMAP_PATH.substring(1)) + "\n");
        }
        else writer.print("Disallow: /\n");
    }

    /**
     * Writes the sitemap index, or the only sitemap if all of the public documents fit in one.
     *
     * @param resp servlet response
     * @param system system application
     * @param app end-user dataspace
     * @param publicRules public read rules
     * @throws IOException I/O error
     * @throws XMLStreamException XML writing error
     */
    public void writeIndex(HttpServletResponse resp, Application system, EndUserDataspace app, ResultSetRewindable publicRules) throws IOException, XMLStreamException
    {
        // the longest buckets, keyed by prefix, with their document count and latest date
        Map<String, Bucket> buckets = new TreeMap<>();
        ResultSetRewindable results = select(system, app.getService(), bindPublicRules(substitute(indexQuery, app, null), publicRules));
        while (results.hasNext())
        {
            QuerySolution solution = results.next();
            buckets.put(solution.getLiteral("bucket").getString(),
                new Bucket(solution.getLiteral("count").getLong(), solution.contains("lastmod") ? solution.get("lastmod") : null));
        }

        if (buckets.isEmpty()) // a dataspace with nothing public has no sitemap rather than an empty one
        {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        // the shortest prefix whose buckets each fit in a sitemap
        Map<String, Bucket> merged = buckets;
        for (int length = 0; length <= MAX_BUCKET_LENGTH; length++)
        {
            merged = merge(buckets, length);
            if (merged.values().stream().allMatch(b -> b.count() <= MAX_URLS)) break;
        }
        if (merged.values().stream().anyMatch(b -> b.count() > MAX_URLS))
            if (log.isWarnEnabled()) log.warn("Sitemap buckets of <{}> exceed {} URLs even with a {}-digit prefix", app.getBaseURI(), MAX_URLS, MAX_BUCKET_LENGTH);

        if (merged.size() == 1 && merged.containsKey(""))
        {
            writeSitemap(resp, system, app, publicRules, "");
            return;
        }

        XMLStreamWriter writer = startDocument(resp);
        writer.writeStartElement("sitemapindex");
        writer.writeDefaultNamespace(NS);
        for (Map.Entry<String, Bucket> bucket : merged.entrySet())
        {
            writer.writeStartElement("sitemap");
            writeElement(writer, "loc", app.getBaseURI().resolve(SITEMAP_PATH.substring(1) + "?" + BUCKET_PARAM + "=" + bucket.getKey()).toString());
            writeLastmod(writer, bucket.getValue().lastmod());
            writer.writeEndElement();
        }
        writer.writeEndElement();
        endDocument(writer);
    }

    /**
     * Writes the sitemap of one bucket.
     *
     * @param resp servlet response
     * @param system system application
     * @param app end-user dataspace
     * @param publicRules public read rules
     * @param bucket MD5 prefix of the documents, empty for all of them
     * @throws IOException I/O error
     * @throws XMLStreamException XML writing error
     */
    public void writeSitemap(HttpServletResponse resp, Application system, EndUserDataspace app, ResultSetRewindable publicRules, String bucket) throws IOException, XMLStreamException
    {
        ResultSetRewindable results = select(system, app.getService(), bindPublicRules(substitute(sitemapQuery, app, bucket), publicRules));
        if (!results.hasNext())
        {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        XMLStreamWriter writer = startDocument(resp);
        writer.writeStartElement("urlset");
        writer.writeDefaultNamespace(NS);
        while (results.hasNext())
        {
            QuerySolution solution = results.next();
            writer.writeStartElement("url");
            writeElement(writer, "loc", solution.getResource("loc").getURI());
            writeLastmod(writer, solution.contains("lastmod") ? solution.get("lastmod") : null);
            writer.writeEndElement();
        }
        writer.writeEndElement();
        endDocument(writer);
    }

    /**
     * Returns the public read rules of a dataspace, read from its admin service.
     *
     * @param system system application
     * @param adminApp admin dataspace
     * @return rules as <code>?to</code> (document) and <code>?Type</code> (class) bindings
     */
    public ResultSetRewindable getPublicRules(Application system, AdminDataspace adminApp)
    {
        return select(system, adminApp.getService(), QueryTransformOps.replaceVars(publicRulesQuery,
            Map.of(Var.alloc("adminBase"), NodeFactory.createURI(adminApp.getBaseURI().toString()))));
    }

    /**
     * Returns true if the dataspace has a public document, which is what gives it a sitemap.
     *
     * @param system system application
     * @param app end-user dataspace
     * @param publicRules public read rules
     * @return true if a public read rule grants access to a document of the dataspace
     */
    public boolean hasPublicDocument(Application system, EndUserDataspace app, ResultSetRewindable publicRules)
    {
        return select(system, app.getService(), bindPublicRules(substitute(publicDocumentQuery, app, null), publicRules)).hasNext();
    }

    /**
     * Replaces the dataspace base and the bucket in a sitemap query.
     *
     * @param query sitemap query
     * @param app end-user dataspace
     * @param bucket MD5 prefix, or null if the query takes none
     * @return query
     */
    public Query substitute(Query query, EndUserDataspace app, String bucket)
    {
        Map<Var, Node> substitutions = new HashMap<>();
        substitutions.put(Var.alloc("base"), NodeFactory.createURI(app.getBaseURI().toString()));
        if (bucket != null) substitutions.put(Var.alloc("bucket"), NodeFactory.createLiteralString(bucket));
        return QueryTransformOps.replaceVars(query, substitutions);
    }

    /**
     * Fills the query's <code>VALUES ?Type</code> block with the class rules and its <code>VALUES ?loc</code> block
     * with the document rules. Inline rather than a trailing <code>VALUES</code>, which would join the rules with the
     * result of the whole pattern instead of restricting each branch as it is matched.
     *
     * @param query sitemap query
     * @param publicRules public read rules
     * @return query
     */
    public Query bindPublicRules(Query query, ResultSetRewindable publicRules)
    {
        List<Node> classes = new ArrayList<>(), documents = new ArrayList<>();
        publicRules.reset();
        while (publicRules.hasNext())
        {
            QuerySolution solution = publicRules.next();
            if (solution.contains(TYPE_VAR.getVarName()) && solution.get(TYPE_VAR.getVarName()).isURIResource())
                classes.add(solution.get(TYPE_VAR.getVarName()).asNode());
            if (solution.contains(TO_VAR.getVarName()) && solution.get(TO_VAR.getVarName()).isURIResource())
                documents.add(solution.get(TO_VAR.getVarName()).asNode());
        }

        return QueryTransformOps.transform(query, new ElementTransformCopyBase()
        {
            @Override
            public Element transform(ElementData data)
            {
                if (data.getVars().equals(List.of(TYPE_VAR))) return values(TYPE_VAR, classes);
                if (data.getVars().equals(List.of(LOC_VAR))) return values(LOC_VAR, documents);
                return data;
            }
        });
    }

    /**
     * Executes a <code>SELECT</code> query on a service.
     *
     * @param system system application
     * @param service SPARQL service
     * @param query query
     * @return results
     */
    public ResultSetRewindable select(Application system, Service service, Query query)
    {
        try (Response cr = system.getServiceContext(service).getSPARQLClient().query(query, ResultSet.class))
        {
            if (!cr.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
                throw new IllegalStateException("SPARQL endpoint of <" + service + "> answered " + cr.getStatus());
            return cr.readEntity(ResultSetRewindable.class);
        }
    }

    /**
     * Merges buckets into ones of a shorter prefix.
     *
     * @param buckets buckets keyed by prefix
     * @param length prefix length
     * @return merged buckets
     */
    public static Map<String, Bucket> merge(Map<String, Bucket> buckets, int length)
    {
        Map<String, Bucket> merged = new TreeMap<>();
        for (Map.Entry<String, Bucket> bucket : buckets.entrySet())
            merged.merge(bucket.getKey().substring(0, Math.min(length, bucket.getKey().length())), bucket.getValue(), Bucket::add);
        return merged;
    }

    private static ElementData values(Var var, List<Node> nodes)
    {
        ElementData data = new ElementData();
        data.add(var);
        nodes.forEach(node -> data.add(BindingFactory.binding(var, node)));
        return data;
    }

    private static XMLStreamWriter startDocument(HttpServletResponse resp) throws IOException, XMLStreamException
    {
        resp.setContentType("application/xml");
        resp.setCharacterEncoding(StandardCharsets.UTF_8.name());

        XMLStreamWriter writer = XMLOutputFactory.newInstance().createXMLStreamWriter(resp.getWriter());
        writer.writeStartDocument(StandardCharsets.UTF_8.name(), "1.0");
        writer.setDefaultNamespace(NS);
        return writer;
    }

    private static void endDocument(XMLStreamWriter writer) throws XMLStreamException
    {
        writer.writeEndDocument();
        writer.flush();
        writer.close();
    }

    private static void writeElement(XMLStreamWriter writer, String name, String value) throws XMLStreamException
    {
        writer.writeStartElement(name);
        writer.writeCharacters(value);
        writer.writeEndElement();
    }

    // only an xsd:dateTime is a W3C Datetime the protocol accepts
    private static void writeLastmod(XMLStreamWriter writer, RDFNode lastmod) throws XMLStreamException
    {
        if (lastmod != null && lastmod.isLiteral() && XSDDatatype.XSDdateTime.getURI().equals(((Literal)lastmod).getDatatypeURI()))
            writeElement(writer, "lastmod", lastmod.asLiteral().getLexicalForm());
    }

    private static Query loadQuery(String name)
    {
        try (InputStream is = SitemapServlet.class.getResourceAsStream("/com/atomgraph/linkeddatahub/sitemap/" + name))
        {
            return QueryFactory.create(new String(is.readAllBytes(), StandardCharsets.UTF_8));
        }
        catch (IOException ex)
        {
            throw new UncheckedIOException(ex);
        }
    }

    /**
     * Documents of one bucket.
     *
     * @param count number of documents
     * @param lastmod latest date of the documents, or null
     */
    public record Bucket(long count, RDFNode lastmod)
    {

        /**
         * Adds up two buckets.
         *
         * @param other the other bucket
         * @return the sum
         */
        public Bucket add(Bucket other)
        {
            return new Bucket(count + other.count, later(lastmod, other.lastmod));
        }

        private static RDFNode later(RDFNode a, RDFNode b)
        {
            if (a == null || !a.isLiteral()) return b;
            if (b == null || !b.isLiteral()) return a;
            return NodeValue.compareAlways(NodeValue.makeNode(a.asNode()), NodeValue.makeNode(b.asNode())) >= 0 ? a : b;
        }

    }

}
