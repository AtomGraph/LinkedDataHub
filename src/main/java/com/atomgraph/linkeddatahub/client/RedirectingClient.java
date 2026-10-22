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
package com.atomgraph.linkeddatahub.client;

import com.atomgraph.core.exception.BadGatewayException;
import com.atomgraph.linkeddatahub.server.exception.InternalURLException;
import com.atomgraph.linkeddatahub.server.util.URLValidator;
import jakarta.ws.rs.HttpMethod;
import jakarta.ws.rs.client.WebTarget;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Response;
import java.net.URI;
import java.util.Set;
import java.util.function.BiFunction;
import java.util.function.Function;
import org.glassfish.jersey.client.ClientProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Follows HTTP redirects, validating every {@code Location} with {@link URLValidator} before requesting it.
 * <p>
 * Follows {@code 301}, {@code 302}, {@code 303}, {@code 307} and {@code 308}, at most {@link #MAX_REDIRECTS} hops.
 * {@code 303} is followed for any method and continues as {@code GET} ({@code HEAD} stays {@code HEAD}); the others
 * are followed for {@code GET} and {@code HEAD} only, and otherwise returned to the caller. A refused hop, a
 * non-HTTP(S) {@code Location} or one hop too many throws {@link BadGatewayException} naming the hop. Automatic
 * redirects are turned off on every target, whatever the client's configuration. The caller validates the first URI.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class RedirectingClient
{

    private static final Logger log = LoggerFactory.getLogger(RedirectingClient.class);

    /** The most redirects followed for one request */
    public static final int MAX_REDIRECTS = 5;

    /** Statuses that redirect */
    public static final Set<Integer> REDIRECT_STATUSES = Set.of(301, 302, 303, 307, 308);

    /**
     * The response that ended a redirect chain, and the URI that answered it.
     *
     * @param uri the URI the response came from: the first URI, or the last redirect's target
     * @param response the response, open
     */
    public record Result(URI uri, Response response) implements AutoCloseable
    {

        @Override
        public void close()
        {
            response.close();
        }

    }

    private final URLValidator urlValidator;
    private final int maxRedirects;

    /**
     * Constructs a client following at most {@link #MAX_REDIRECTS} redirects.
     *
     * @param urlValidator validator for redirect targets
     */
    public RedirectingClient(URLValidator urlValidator)
    {
        this(urlValidator, MAX_REDIRECTS);
    }

    /**
     * Constructs a client.
     *
     * @param urlValidator validator for redirect targets
     * @param maxRedirects the most redirects followed for one request
     */
    public RedirectingClient(URLValidator urlValidator, int maxRedirects)
    {
        if (urlValidator == null) throw new IllegalArgumentException("URLValidator cannot be null");
        this.urlValidator = urlValidator;
        this.maxRedirects = maxRedirects;
    }

    /**
     * Sends a {@code GET} request, following redirects.
     *
     * @param targets maps each URI requested to its target
     * @param uri the first URI, validated by the caller
     * @param invoker sends the request on the given target
     * @return the final response and its URI; the caller closes it
     */
    public Result get(Function<URI, WebTarget> targets, URI uri, Function<WebTarget, Response> invoker)
    {
        return invoke(targets, uri, HttpMethod.GET, (target, method) -> invoker.apply(target));
    }

    /**
     * Sends a request, following redirects.
     * The invoker receives the method each hop uses: the request's own, or {@code GET} after a {@code 303}.
     *
     * @param targets maps each URI requested to its target
     * @param uri the first URI, validated by the caller
     * @param method the request method
     * @param invoker sends the request on the given target with the given method
     * @return the final response and its URI; the caller closes it
     * @throws BadGatewayException when a hop is refused or there are too many
     */
    public Result invoke(Function<URI, WebTarget> targets, URI uri, String method, BiFunction<WebTarget, String, Response> invoker)
    {
        URI current = uri;
        String currentMethod = method;

        for (int hop = 0; ; hop++)
        {
            WebTarget target = targets.apply(current).property(ClientProperties.FOLLOW_REDIRECTS, false);
            Response response = invoker.apply(target, currentMethod);

            int status = response.getStatus();
            String location = response.getHeaderString(HttpHeaders.LOCATION);
            if (!REDIRECT_STATUSES.contains(status) || location == null) return new Result(current, response);

            boolean safe = HttpMethod.GET.equalsIgnoreCase(currentMethod) || HttpMethod.HEAD.equalsIgnoreCase(currentMethod);
            if (status != 303 && !safe) return new Result(current, response);
            response.close();

            if (hop >= getMaxRedirects())
                throw new BadGatewayException("More than " + getMaxRedirects() + " redirects requesting <" + uri + ">; hop " + (hop + 1) + " to <" + location + "> refused");

            URI next;
            try
            {
                next = current.resolve(location.trim());
            }
            catch (IllegalArgumentException ex)
            {
                throw new BadGatewayException("Redirect hop " + (hop + 1) + " from <" + current + "> has an invalid Location: " + location, ex);
            }
            if (!("http".equalsIgnoreCase(next.getScheme()) || "https".equalsIgnoreCase(next.getScheme())))
                throw new BadGatewayException("Redirect hop " + (hop + 1) + " from <" + current + "> to <" + next + "> refused: not an HTTP(S) URI");

            try
            {
                getURLValidator().validate(next);
            }
            catch (InternalURLException | IllegalArgumentException ex)
            {
                if (log.isWarnEnabled()) log.warn("Refused redirect hop {} from <{}> to <{}>: {}", hop + 1, current, next, ex.getMessage());
                throw new BadGatewayException("Redirect hop " + (hop + 1) + " from <" + current + "> to <" + next + "> refused: " + ex.getMessage(), ex);
            }

            if (log.isDebugEnabled()) log.debug("Following redirect hop {} from <{}> to <{}>", hop + 1, current, next);
            if (status == 303 && !HttpMethod.HEAD.equalsIgnoreCase(currentMethod)) currentMethod = HttpMethod.GET;
            current = next;
        }
    }

    /**
     * Returns the validator for redirect targets.
     *
     * @return URL validator
     */
    public URLValidator getURLValidator()
    {
        return urlValidator;
    }

    /**
     * Returns the most redirects followed for one request.
     *
     * @return redirect count
     */
    public int getMaxRedirects()
    {
        return maxRedirects;
    }

}
