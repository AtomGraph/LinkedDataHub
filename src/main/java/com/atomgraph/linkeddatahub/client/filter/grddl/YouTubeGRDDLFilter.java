/**
 *  Copyright 2025 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.client.filter.grddl;

import com.atomgraph.linkeddatahub.client.filter.JSONGRDDLFilter;
import java.net.URI;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.regex.Pattern;
import net.sf.saxon.s9api.SaxonApiException;
import net.sf.saxon.s9api.XsltCompiler;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Client filter that implements GRDDL pattern for YouTube videos.
 * Redirects YouTube URLs to oEmbed endpoints and transforms JSON responses to RDF.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class YouTubeGRDDLFilter extends JSONGRDDLFilter
{
    
    private static final Logger log = LoggerFactory.getLogger(YouTubeGRDDLFilter.class);
    
    // YouTube URL patterns
    private static final Pattern YOUTUBE_WATCH_PATTERN = Pattern.compile("https?://(?:www\\.)?youtube\\.com/watch\\?.*v=([a-zA-Z0-9_-]+)");
    private static final Pattern YOUTUBE_SHORT_PATTERN = Pattern.compile("https?://youtu\\.be/([a-zA-Z0-9_-]+)");
    
    // YouTube oEmbed endpoint
    private static final String OEMBED_ENDPOINT = "https://www.youtube.com/oembed";
    
    /**
     * Classpath resource path of XSLT stylesheet for transforming YouTube oEmbed JSON to RDF.
     */
    public static final String YOUTUBE_XSLT_PATH = "/com/atomgraph/linkeddatahub/xsl/grddl/youtube.xsl";
    
    /**
     * Constructs YouTube GRDDL filter.
     * 
     * @param xsltCompiler XSLT compiler
     * @throws SaxonApiException if stylesheet compilation fails
     */
    public YouTubeGRDDLFilter(XsltCompiler xsltCompiler) throws SaxonApiException
    {
        super(xsltCompiler, YOUTUBE_XSLT_PATH);
    }
    
    @Override
    protected boolean isApplicable(URI requestURI)
    {
        return isYouTubeURL(requestURI.toString());
    }
    
    @Override
    protected URI getJSONURI(URI requestURI)
    {
        String youtubeURL = requestURI.toString();
        
        if (!isYouTubeURL(youtubeURL))
            return null;
            
        try
        {
            // Encode the YouTube URL for the oEmbed endpoint
            String encodedURL = URLEncoder.encode(youtubeURL, StandardCharsets.UTF_8);
            String oembedURL = OEMBED_ENDPOINT + "?url=" + encodedURL + "&format=json";
            
            if (log.isDebugEnabled()) log.debug("Converting YouTube URL {} to oEmbed URL {}", youtubeURL, oembedURL);
            
            return URI.create(oembedURL);
        }
        catch (Exception ex)
        {
            if (log.isErrorEnabled()) log.error("Failed to create oEmbed URL for YouTube URL: {}", youtubeURL, ex);
            return null;
        }
    }
    
    /**
     * Determines if the given URL is a YouTube video URL.
     * Supports both youtube.com/watch?v= and youtu.be/ formats.
     * 
     * @param url the URL to check
     * @return true if it's a YouTube video URL
     */
    public static boolean isYouTubeURL(String url)
    {
        return YOUTUBE_WATCH_PATTERN.matcher(url).matches() || 
               YOUTUBE_SHORT_PATTERN.matcher(url).matches();
    }
    
}