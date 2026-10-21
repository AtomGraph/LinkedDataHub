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
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Follows HTTP redirects on behalf of a client that does not follow them itself, running the SSRF check on every hop.
 * <p>
 * The clients that dereference URIs supplied from outside - the Linked Data proxy's and the WebID loader's - have
 * automatic redirects turned off, because the HTTP connector follows a redirect where neither Jersey's filters nor
 * {@link URLValidator} see it: a public origin could send the platform on to an internal address. This class follows
 * {@code 301}, {@code 302}, {@code 303}, {@code 307} and {@code 308} itself, at most {@link #MAX_REDIRECTS} hops,
 * validating each {@code Location} (resolved against the URI that answered it) before requesting it. A refused hop,
 * a {@code Location} that is not an HTTP(S) URI, or one hop too many answers {@code 502 Bad Gateway} naming the hop.
 * <p>
 * Which redirects are followed is what the connector followed before: {@code 303} for any method, the request going
 * on as {@code GET} ({@code HEAD} stays {@code HEAD}); the others for {@code GET} and {@code HEAD} only, a redirected
 * unsafe request being returned to the caller as it came. So a request entity is never sent twice.
 * <p>
 * The first URI is the caller's to validate, as it does before choosing a client.
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

    private final URLValidator urlValidator;
    private final int maxRedirects;

    /**
     * Constructs a client following at most {@link #MAX_REDIRECTS} redirects.
     *
     * @param urlValidator the validator every redirect target passes before it is requested
     */
    public RedirectingClient(URLValidator urlValidator)
    {
        this(urlValidator, MAX_REDIRECTS);
    }

    /**
     * Constructs a client.
     *
     * @param urlValidator the validator every redirect target passes before it is requested
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
     * @param targets maps each URI requested to its target, with any per-target filters registered on it
     * @param uri the first URI, already validated by the caller
     * @param invoker sends the request on the given target
     * @return the response that did not redirect, open; the caller closes it
     */
    public Response get(Function<URI, WebTarget> targets, URI uri, Function<WebTarget, Response> invoker)
    {
        return invoke(targets, uri, HttpMethod.GET, (target, method) -> invoker.apply(target));
    }

    /**
     * Sends a request, following redirects.
     * The invoker is passed the method each hop goes out with: the request's own, or {@code GET} after a {@code 303}.
     * It sends the request entity only with the request's own method.
     *
     * @param targets maps each URI requested to its target, with any per-target filters registered on it
     * @param uri the first URI, already validated by the caller
     * @param method the request method
     * @param invoker sends the request on the given target with the given method
     * @return the response that did not redirect (or whose redirect is not followed), open; the caller closes it
     * @throws BadGatewayException when a hop is refused or there are more than the allowed hops
     */
    public Response invoke(Function<URI, WebTarget> targets, URI uri, String method, BiFunction<WebTarget, String, Response> invoker)
    {
        URI current = uri;
        String currentMethod = method;

        for (int hop = 0; ; hop++)
        {
            Response response = invoker.apply(targets.apply(current), currentMethod);

            int status = response.getStatus();
            String location = response.getHeaderString(HttpHeaders.LOCATION);
            if (!REDIRECT_STATUSES.contains(status) || location == null) return response;

            boolean safe = HttpMethod.GET.equalsIgnoreCase(currentMethod) || HttpMethod.HEAD.equalsIgnoreCase(currentMethod);
            if (status != 303 && !safe) return response; // an unsafe request is not repeated elsewhere: the caller gets the redirect
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
     * Returns the validator every redirect target passes.
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
