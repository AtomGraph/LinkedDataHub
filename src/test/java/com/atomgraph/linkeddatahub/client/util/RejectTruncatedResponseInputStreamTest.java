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
import com.atomgraph.core.mapper.BadGatewayExceptionMapper;
import jakarta.ws.rs.core.Response;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.SequenceInputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import org.apache.jena.graph.NodeFactory;
import org.apache.jena.query.ResultSet;
import org.apache.jena.query.ResultSetFactory;
import org.apache.jena.riot.ResultSetMgr;
import org.apache.jena.riot.resultset.ResultSetLang;
import org.apache.jena.sparql.core.Var;
import org.apache.jena.sparql.engine.binding.Binding;
import org.apache.jena.sparql.engine.binding.BindingFactory;
import org.apache.jena.sparql.exec.RowSetStream;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Unit tests for {@link RejectTruncatedResponseInputStream}.
 * <p>
 * The platform reads the store's query results as RDF Thrift. When the store's Varnish cache cuts a result short, the
 * connection closes with no last chunk and the read fails with an {@link IOException}, which Jena's Thrift reader
 * takes for the end of the results: the SPARQL endpoint answered 200 with the rows that had arrived.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class RejectTruncatedResponseInputStreamTest
{

    private static final int ROWS = 1000;

    private static byte[] thriftResult()
    {
        Var s = Var.alloc("s");
        List<Binding> rows = new ArrayList<>();
        for (int i = 0; i < ROWS; i++) rows.add(BindingFactory.binding(s, NodeFactory.createURI("http://example.org/" + i)));

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ResultSetMgr.write(out, ResultSet.adapt(RowSetStream.create(List.of(s), rows.iterator())), ResultSetLang.RS_Thrift);
        return out.toByteArray();
    }

    /** The first half of a result, then the read failure a connection closed mid-body raises. */
    private static InputStream cut(byte[] body)
    {
        return new SequenceInputStream(new ByteArrayInputStream(Arrays.copyOf(body, body.length / 2)), new InputStream()
        {
            @Override
            public int read() throws IOException
            {
                throw new IOException("Premature end of chunk coded message body: closing chunk expected");
            }
        });
    }

    private static int rows(InputStream in)
    {
        return ResultSetFactory.makeRewindable(ResultSetMgr.read(in, ResultSetLang.RS_Thrift)).size();
    }

    /** A result that arrives whole is read whole. */
    @Test
    public void testWholeResultIsRead()
    {
        assertEquals(ROWS, rows(new RejectTruncatedResponseInputStream(new ByteArrayInputStream(thriftResult()))));
    }

    /** What the stream guards against: unwrapped, a cut result reads as a complete, shorter one. */
    @Test
    public void testCutResultReadsShortWithoutTheStream()
    {
        int read = rows(cut(thriftResult()));

        assertTrue(read > 0 && read < ROWS, "read " + read + " of " + ROWS + " rows");
    }

    /** Wrapped, the same cut result fails the read. */
    @Test
    public void testCutResultIsRejected()
    {
        assertThrows(BadGatewayException.class, () -> rows(new RejectTruncatedResponseInputStream(cut(thriftResult()))));
    }

    /** 502, through the mapper the platform registers for the exception: what failed is the upstream's response. */
    @Test
    public void testAnswersBadGateway()
    {
        BadGatewayException e = assertThrows(BadGatewayException.class, () -> rows(new RejectTruncatedResponseInputStream(cut(thriftResult()))));
        assertEquals(Response.Status.BAD_GATEWAY.getStatusCode(), new BadGatewayExceptionMapper().toResponse(e).getStatus());
    }

}
