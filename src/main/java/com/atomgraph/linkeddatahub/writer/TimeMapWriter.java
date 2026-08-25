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
package com.atomgraph.linkeddatahub.writer;

import com.atomgraph.linkeddatahub.server.model.impl.DocumentHierarchyGraphStoreImpl;
import com.atomgraph.linkeddatahub.vocabulary.PROV;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.core.UriInfo;
import jakarta.ws.rs.ext.MessageBodyWriter;
import jakarta.ws.rs.ext.Provider;
import java.io.IOException;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.lang.annotation.Annotation;
import java.lang.reflect.Type;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.RDFNode;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResIterator;
import org.apache.jena.vocabulary.RDF;

/**
 * Serializes a TimeMap model as <code>application/link-format</code>, the serialization RFC 7089 requires
 * TimeMaps to support. The model is the PROV-O description built by
 * {@link com.atomgraph.linkeddatahub.server.util.GraphVersioningService#toTimeMap}: the TimeMap is the
 * <code>prov:Collection</code>, its <code>prov:hadMember</code> values are the Mementos, and the Original
 * Resource is the <code>prov:specializationOf</code> target they share.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see <a href="https://datatracker.ietf.org/doc/html/rfc7089#section-5">RFC 7089: TimeMap</a>
 * @see <a href="https://datatracker.ietf.org/doc/html/rfc6690#section-2">RFC 6690: Link Format</a>
 */
@Provider
@Produces(TimeMapWriter.APPLICATION_LINK_FORMAT)
public class TimeMapWriter implements MessageBodyWriter<Model>
{

    @Context private UriInfo uriInfo;

    /** The link-format media type as a string */
    public static final String APPLICATION_LINK_FORMAT = "application/link-format";

    /** The link-format media type */
    public static final MediaType APPLICATION_LINK_FORMAT_TYPE = new MediaType("application", "link-format");

    /**
     * Datetime format required by RFC 7089. Not {@link DateTimeFormatter#RFC_1123_DATE_TIME}, which leaves the
     * day of month unpadded, while the RFC 7089 grammar specifies <code>date1 = 2DIGIT SP month SP 4DIGIT</code>.
     */
    public static final DateTimeFormatter RFC_1123_GMT = DateTimeFormatter.ofPattern("EEE, dd MMM yyyy HH:mm:ss 'GMT'", Locale.US);

    @Override
    public boolean isWriteable(Class<?> type, Type genericType, Annotation[] annotations, MediaType mediaType)
    {
        return Model.class.isAssignableFrom(type);
    }

    @Override
    public void writeTo(Model model, Class<?> type, Type genericType, Annotation[] annotations, MediaType mediaType,
        MultivaluedMap<String, Object> httpHeaders, OutputStream entityStream) throws IOException, WebApplicationException
    {
        Resource timeMap = getTimeMap(model);
        List<Resource> mementos = getMementos(timeMap);
        if (mementos.isEmpty()) throw new IllegalStateException("TimeMap <" + timeMap.getURI() + "> has no mementos");

        Resource original = mementos.get(0).getPropertyResourceValue(PROV.specializationOf);
        Resource first = mementos.get(0), last = mementos.get(mementos.size() - 1);

        List<String> links = new ArrayList<>();
        links.add("<" + original.getURI() + ">;rel=\"original\"");
        links.add("<" + timeMap.getURI() + ">;rel=\"self\";type=\"" + APPLICATION_LINK_FORMAT + "\"" +
            ";from=\"" + datetime(first) + "\";until=\"" + datetime(last) + "\"");
        // the TimeGate is deployment hypermedia rather than part of the version history, so it comes from the request
        getTimeGateURI().ifPresent(timeGate -> links.add("<" + timeGate + ">;rel=\"timegate\""));

        for (Resource memento : mementos)
        {
            // a single memento is both the first and the last one known
            List<String> rels = new ArrayList<>();
            if (memento.equals(first)) rels.add("first");
            if (memento.equals(last)) rels.add("last");
            rels.add("memento");

            links.add("<" + memento.getURI() + ">;rel=\"" + String.join(" ", rels) + "\";datetime=\"" + datetime(memento) + "\"");
        }

        Writer writer = new OutputStreamWriter(entityStream, StandardCharsets.UTF_8);
        writer.write(String.join(",\n", links));
        writer.flush();
    }

    /**
     * Returns the TimeGate URI of the resource being served, if there is a request to derive it from.
     *
     * @return TimeGate URI, or empty outside a request
     */
    protected Optional<URI> getTimeGateURI()
    {
        if (getUriInfo() == null) return Optional.empty();

        return Optional.of(URI.create(getUriInfo().getAbsolutePath() + "?" + DocumentHierarchyGraphStoreImpl.TIMEGATE_PARAM_NAME));
    }

    /**
     * Returns the URI info of the current request.
     *
     * @return URI info, or null outside a request
     */
    public UriInfo getUriInfo()
    {
        return uriInfo;
    }

    /**
     * Returns the TimeMap resource of the model.
     *
     * @param model TimeMap model
     * @return the <code>prov:Collection</code> resource
     */
    protected Resource getTimeMap(Model model)
    {
        ResIterator it = model.listResourcesWithProperty(RDF.type, PROV.Collection);
        try
        {
            if (!it.hasNext()) throw new IllegalStateException("Model does not contain a prov:Collection TimeMap resource");
            return it.next();
        }
        finally
        {
            it.close();
        }
    }

    /**
     * Returns the TimeMap's mementos, oldest first.
     *
     * @param timeMap TimeMap resource
     * @return memento resources ordered by generation time
     */
    protected List<Resource> getMementos(Resource timeMap)
    {
        List<Resource> mementos = new ArrayList<>();
        timeMap.listProperties(PROV.hadMember).forEachRemaining(stmt ->
        {
            RDFNode member = stmt.getObject();
            if (member.isURIResource()) mementos.add(member.asResource());
        });

        mementos.sort(Comparator.comparing(memento -> Instant.parse(memento.getProperty(PROV.generatedAtTime).getString())));
        return mementos;
    }

    /**
     * Formats a memento's generation time as an RFC 1123 datetime.
     *
     * @param memento memento resource
     * @return datetime in RFC 1123 format
     */
    protected String datetime(Resource memento)
    {
        return RFC_1123_GMT.format(
            ZonedDateTime.parse(memento.getProperty(PROV.generatedAtTime).getString()).withZoneSameInstant(ZoneId.of("GMT")));
    }

}
