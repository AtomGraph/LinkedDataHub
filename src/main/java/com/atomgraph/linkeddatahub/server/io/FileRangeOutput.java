/**
 *  Copyright 2022 Martynas Jusevičius <martynas@atomgraph.com>
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

import com.google.common.io.ByteStreams;

import javax.ws.rs.WebApplicationException;
import javax.ws.rs.core.StreamingOutput;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

/**
 * Represents a byte range output from a file.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class FileRangeOutput implements StreamingOutput
{
    
    private final File file;
    private final long length;
    private final long from;

    /**
     * Constructs output from file, range start and length.
     * 
     * @param file file that the byte range will be taken from
     * @param from start byte
     * @param length length in bytes
     */
    public FileRangeOutput(File file, long from, long length)
    {
        this.length = length;
        this.file = file;
        this.from = from;
    }

    @Override
    public void write(OutputStream outputStream) throws IOException, WebApplicationException
    {
        try (FileInputStream fis = new FileInputStream(getFile()))
        {
            fis.skip(getFrom());

            try (InputStream limit = ByteStreams.limit(fis, getLength()))
            {
                ByteStreams.copy(limit, outputStream);
            }
        }
    }
    
    /**
     * Returns the file of this range.
     * 
     * @return file
     */
    public File getFile()
    {
        return file;
    }
    
    /**
     * Returns range start.
     * 
     * @return from byte
     */
    public long getFrom()
    {
        return from;
    }
    
    /**
     * Returns range length
     * 
     * @return number of bytes
     */
    public long getLength()
    {
        return length;
    }
    
}