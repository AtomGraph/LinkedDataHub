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
package com.atomgraph.linkeddatahub.server.model.impl;

import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.EntityTag;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Request;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.function.Predicate;
import java.util.function.Supplier;

/**
 * A response whose rendered variants carry the stylesheet they are rendered with in their entity tag.
 *
 * The HTML representation is the graph transformed by the dataspace's stylesheet, composed with the packages it
 * imports. A tag computed from the graph, the variant and the accepted languages alone stays the same across a
 * deployment of a new stylesheet or an <code>ldh packages add</code>, both of which change the HTML, so a cache
 * revalidating its copy was answered <code>304</code> and kept serving the stale page. The rendering key - which
 * changes whenever the stylesheet or the package set does - is digested into the tag of the variants the predicate
 * selects; the RDF variants are not rendered and keep their tag.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class RenderedResponse extends com.atomgraph.core.model.impl.Response
{

    /** Digest algorithm the rendering key is mixed in with */
    public static final String DIGEST_ALGORITHM = "SHA-256";
    /** Bytes of digest kept, rendered as hex, as in {@link com.atomgraph.linkeddatahub.server.util.EntityTags} */
    public static final int TAG_BYTES = 16;

    private final Predicate<MediaType> isRendered;
    private final Supplier<String> renderingKey;

    /**
     * Builds a response from the request, selecting its variant.
     *
     * @param request request
     * @param httpHeaders request headers
     * @param entity response entity
     * @param lastModified last modified date
     * @param entityTag entity tag of the entity
     * @param mediaTypes media types offered
     * @param languages content languages offered
     * @param encodings content encodings offered
     * @param isMediaTypeLangSignificant predicate selecting the media types whose representation depends on language
     * @param acceptableLanguages languages the request accepts, in priority order
     * @param isRendered predicate selecting the media types rendered with the stylesheet
     * @param renderingKey supplies the key of the stylesheet and package set, or null when there is none; only asked
     * for when the selected variant is rendered
     */
    public RenderedResponse(Request request, HttpHeaders httpHeaders, Object entity, Date lastModified, EntityTag entityTag,
            List<MediaType> mediaTypes, List<Locale> languages, List<String> encodings,
            Predicate<MediaType> isMediaTypeLangSignificant, List<Locale> acceptableLanguages,
            Predicate<MediaType> isRendered, Supplier<String> renderingKey)
    {
        super(request, httpHeaders, entity, lastModified, entityTag, mediaTypes, languages, encodings, isMediaTypeLangSignificant, acceptableLanguages);
        if (isRendered == null) throw new IllegalArgumentException("Predicate<MediaType> cannot be null");
        if (renderingKey == null) throw new IllegalArgumentException("Supplier<String> cannot be null");
        this.isRendered = isRendered;
        this.renderingKey = renderingKey;
    }

    /**
     * Returns the variant entity tag, with the rendering key digested in when the selected variant is rendered.
     *
     * @return entity tag
     */
    @Override
    public EntityTag getVariantEntityTag()
    {
        EntityTag entityTag = super.getVariantEntityTag();
        if (entityTag == null || !isRendered.test(getVariant().getMediaType())) return entityTag;

        String key = renderingKey.get();
        if (key == null) return entityTag;

        return withRenderingKey(entityTag, key);
    }

    /**
     * Digests a rendering key into an entity tag.
     *
     * The result is lowercase hex, like the tag it is derived from: the XSLT writers parse it as a number to add the
     * agent to it.
     *
     * @param entityTag entity tag
     * @param renderingKey key of the stylesheet and package set
     * @return entity tag
     */
    public static EntityTag withRenderingKey(EntityTag entityTag, String renderingKey)
    {
        if (entityTag == null) throw new IllegalArgumentException("EntityTag cannot be null");
        if (renderingKey == null) throw new IllegalArgumentException("Rendering key cannot be null");

        try
        {
            MessageDigest digest = MessageDigest.getInstance(DIGEST_ALGORITHM);
            digest.update(entityTag.getValue().getBytes(StandardCharsets.UTF_8));
            digest.update((byte)0);
            digest.update(renderingKey.getBytes(StandardCharsets.UTF_8));

            byte[] hash = digest.digest();
            StringBuilder hex = new StringBuilder(TAG_BYTES * 2);
            for (int i = 0; i < TAG_BYTES; i++) hex.append(String.format("%02x", hash[i]));

            return new EntityTag(hex.toString(), entityTag.isWeak());
        }
        catch (NoSuchAlgorithmException ex)
        {
            throw new IllegalStateException(DIGEST_ALGORITHM + " is required of every JVM", ex);
        }
    }

}
