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
package com.atomgraph.linkeddatahub.client.util;

import com.atomgraph.core.exception.BadGatewayException;
import java.io.FilterInputStream;
import java.io.IOException;
import java.io.InputStream;

/**
 * Input stream that rejects an HTTP response cut short by the upstream.
 * <p>
 * A response whose connection closes before its end - a chunked body with no last chunk - fails the read with an
 * {@link IOException}. Some readers take that for the end of the content: Jena's RDF Thrift result reader returns the
 * rows read so far, so a cut query result would be answered as a complete, shorter one. The failure is rethrown
 * unchecked, as {@link BadGatewayException}, which a reader does not catch and which the platform answers 502.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class RejectTruncatedResponseInputStream extends FilterInputStream
{

    /**
     * Constructs input stream.
     *
     * @param inputStream original input stream
     */
    public RejectTruncatedResponseInputStream(InputStream inputStream)
    {
        super(inputStream);
    }

    @Override
    public int read() throws IOException
    {
        try
        {
            return super.read();
        }
        catch (IOException ex)
        {
            throw new BadGatewayException("Response ended before it was complete", ex);
        }
    }

    @Override
    public int read(byte[] b, int off, int len) throws IOException
    {
        try
        {
            return super.read(b, off, len);
        }
        catch (IOException ex)
        {
            throw new BadGatewayException("Response ended before it was complete", ex);
        }
    }

}
