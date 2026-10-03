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

import jakarta.ws.rs.core.UriBuilder;
import jakarta.ws.rs.ext.RuntimeDelegate;
import java.net.URI;
import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * A web link (RFC 8288) that keeps its target URI exactly as given.
 *
 * Jersey's own implementation of {@link jakarta.ws.rs.core.Link} holds its target in a {@link UriBuilder},
 * which drops an empty fragment: <code>https://localhost:4443/ns#</code> - the shape of every dataspace's
 * ontology namespace - comes out as <code>https://localhost:4443/ns</code>, a different URI, whether the
 * link is built or parsed. This one stores the {@link URI} itself, and Jersey's header delegate, which
 * serializes from {@link #getUri()}, writes it intact. Everything else - the header syntax, the quoting
 * of relation types, parameter parsing - stays Jersey's.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see <a href="https://datatracker.ietf.org/doc/html/rfc8288">RFC 8288: Web Linking</a>
 */
public class Link extends jakarta.ws.rs.core.Link
{

    /** The target of a link-value, and the parameters after it */
    private static final Pattern LINK_VALUE = Pattern.compile("^\\s*<([^>]*)>(.*)$", Pattern.DOTALL);

    /** Stands in for the target when Jersey parses the parameters, so its URI handling never sees the real one */
    private static final String PLACEHOLDER = "<urn:placeholder>";

    private final URI uri;
    private final Map<String, String> params;

    /**
     * @param uri the link target, kept as given
     * @param params the link parameters, <code>rel</code>, <code>type</code> and <code>title</code> included
     */
    protected Link(URI uri, Map<String, String> params)
    {
        if (uri == null) throw new IllegalArgumentException("Link URI cannot be null");
        if (params == null) throw new IllegalArgumentException("Link params cannot be null");

        this.uri = uri;
        this.params = Collections.unmodifiableMap(new LinkedHashMap<>(params));
    }

    /**
     * Starts a link to the given target.
     *
     * @param uri link target
     * @return link builder
     */
    public static Builder fromUri(URI uri)
    {
        return new Builder().uri(uri);
    }

    /**
     * Starts a link to the given target.
     *
     * @param uri link target
     * @return link builder
     */
    public static Builder fromUri(String uri)
    {
        return new Builder().uri(uri);
    }

    /**
     * Parses a link-value. The target is taken from between the angle brackets as it is written; Jersey
     * parses the parameters.
     *
     * @param value link-value, e.g. <code>&lt;https://localhost:4443/ns#&gt;; rel="https://w3id.org/atomgraph/linkeddatahub/dataspaces#ontology"</code>
     * @return the link
     * @throws IllegalArgumentException if the value is not a link-value
     */
    public static Link valueOf(String value)
    {
        if (value == null) throw new IllegalArgumentException("Link value cannot be null");

        Matcher matcher = LINK_VALUE.matcher(value);
        if (!matcher.matches()) throw new IllegalArgumentException("Not a link-value: " + value);

        return new Link(URI.create(matcher.group(1).trim()), jakarta.ws.rs.core.Link.valueOf(PLACEHOLDER + matcher.group(2)).getParams());
    }

    @Override
    public URI getUri()
    {
        return uri;
    }

    @Override
    public UriBuilder getUriBuilder()
    {
        return UriBuilder.fromUri(getUri());
    }

    @Override
    public String getRel()
    {
        return getParams().get(REL);
    }

    @Override
    public List<String> getRels()
    {
        return getRel() == null ? Collections.emptyList() : Arrays.asList(getRel().trim().split("\\s+"));
    }

    @Override
    public String getTitle()
    {
        return getParams().get(TITLE);
    }

    @Override
    public String getType()
    {
        return getParams().get(TYPE);
    }

    @Override
    public Map<String, String> getParams()
    {
        return params;
    }

    /**
     * Serializes the link as a <code>Link</code> header value, with Jersey's header delegate.
     *
     * @return the link-value
     */
    @Override
    public String toString()
    {
        return RuntimeDelegate.getInstance().createHeaderDelegate(jakarta.ws.rs.core.Link.class).toString(this);
    }

    @Override
    public boolean equals(Object obj)
    {
        if (this == obj) return true;
        if (!(obj instanceof jakarta.ws.rs.core.Link other)) return false;

        return getUri().equals(other.getUri()) && getParams().equals(other.getParams());
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(getUri(), getParams());
    }

    /**
     * Builds a {@link Link}. Shaped like Jersey's builder, except that the target is a {@link URI} rather than
     * a {@link UriBuilder}, so it is not normalized on the way through.
     */
    public static class Builder implements jakarta.ws.rs.core.Link.Builder
    {

        private URI uri;
        private URI baseUri;
        private final Map<String, String> params = new LinkedHashMap<>();

        @Override
        public Builder link(jakarta.ws.rs.core.Link link)
        {
            uri(link.getUri());
            params.clear();
            params.putAll(link.getParams());
            return this;
        }

        @Override
        public Builder link(String link)
        {
            return link(valueOf(link));
        }

        @Override
        public Builder uri(URI uri)
        {
            this.uri = uri;
            return this;
        }

        @Override
        public Builder uri(String uri)
        {
            return uri(URI.create(uri));
        }

        @Override
        public Builder baseUri(URI uri)
        {
            this.baseUri = uri;
            return this;
        }

        @Override
        public Builder baseUri(String uri)
        {
            return baseUri(URI.create(uri));
        }

        /**
         * Not supported: a {@link UriBuilder} is what loses the empty fragment.
         *
         * @param uriBuilder URI builder
         * @return never
         * @throws UnsupportedOperationException always
         */
        @Override
        public Builder uriBuilder(UriBuilder uriBuilder)
        {
            throw new UnsupportedOperationException("Build the URI first and pass it to uri(URI): a UriBuilder drops an empty fragment");
        }

        /**
         * Adds a relation type. A repeated call adds another one, space-separated, as Jersey's builder does.
         *
         * @param rel relation type
         * @return this builder
         */
        @Override
        public Builder rel(String rel)
        {
            if (rel == null) throw new IllegalArgumentException("Link relation type cannot be null");

            params.merge(REL, rel, (existing, added) -> existing + " " + added);
            return this;
        }

        @Override
        public Builder title(String title)
        {
            return param(TITLE, title);
        }

        @Override
        public Builder type(String type)
        {
            return param(TYPE, type);
        }

        @Override
        public Builder param(String name, String value)
        {
            if (name == null || value == null) throw new IllegalArgumentException("Link parameter name and value cannot be null");

            params.put(name, value);
            return this;
        }

        /**
         * Builds the link. The target is resolved against the base URI, if one was given.
         *
         * @param values URI template values; not supported, since the target is not a template
         * @return the link
         */
        @Override
        public Link build(Object... values)
        {
            if (values != null && values.length > 0) throw new UnsupportedOperationException("Link URI templates are not supported");
            if (uri == null) throw new IllegalArgumentException("Link URI cannot be null");

            return new Link(baseUri != null ? baseUri.resolve(uri) : uri, params);
        }

        @Override
        public Link buildRelativized(URI uri, Object... values)
        {
            Link link = build(values);

            return new Link(uri.relativize(link.getUri()), link.getParams());
        }

    }

}
