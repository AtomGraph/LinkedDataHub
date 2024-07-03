/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */

package com.atomgraph.linkeddatahub.client.util;

import com.atomgraph.linkeddatahub.client.exception.ResponseContentTooLargeException;
import com.atomgraph.linkeddatahub.util.LimitedInputStream;
import java.io.IOException;
import java.io.InputStream;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class RejectTooLargeResponseInputStream extends LimitedInputStream
{

    /**
     * Constructs input stream.
     * 
     * @param inputStream original input stream
     * @param pSizeMax maximum payload size in bytes
     */
    public RejectTooLargeResponseInputStream(InputStream inputStream, long pSizeMax)
    {
        super(inputStream, pSizeMax);
    }

    @Override
    protected void raiseError(long pSizeMax, long pCount) throws IOException
    {
        throw new ResponseContentTooLargeException(pSizeMax, pCount);
    }
    
}