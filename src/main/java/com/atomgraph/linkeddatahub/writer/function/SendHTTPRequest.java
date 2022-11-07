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
package com.atomgraph.linkeddatahub.writer.function;

import com.atomgraph.linkeddatahub.vocabulary.LDH;
import java.io.IOException;
import java.io.InputStream;
import java.util.stream.Collectors;
import javax.ws.rs.client.Client;
import javax.ws.rs.client.Entity;
import javax.ws.rs.core.MultivaluedHashMap;
import javax.ws.rs.core.MultivaluedMap;
import javax.ws.rs.core.Response;
import javax.xml.transform.stream.StreamSource;
import net.sf.saxon.s9api.ExtensionFunction;
import net.sf.saxon.s9api.ItemType;
import net.sf.saxon.s9api.ItemTypeFactory;
import net.sf.saxon.s9api.OccurrenceIndicator;
import net.sf.saxon.s9api.Processor;
import net.sf.saxon.s9api.QName;
import net.sf.saxon.s9api.SaxonApiException;
import net.sf.saxon.s9api.SequenceType;
import net.sf.saxon.s9api.XdmEmptySequence;
import net.sf.saxon.s9api.XdmValue;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Executes an HTTP request.
 * This function currently only works for public URLs as it does not delegate the authenticated agent.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class SendHTTPRequest implements ExtensionFunction
{

    private static final Logger log = LoggerFactory.getLogger(SendHTTPRequest.class);

    private final Processor processor;
    private final Client client;

    /**
     * Constructs function from the specified XSLT processor and HTTP client
     * 
     * @param processor Saxon processor
     * @param client Jersey client
     */
    public SendHTTPRequest(Processor processor, Client client)
    {
        this.processor = processor;
        this.client = client;
    }
    
    @Override
    public QName getName()
    {
        return new QName(LDH.NS, "send-request");
    }

    @Override
    public SequenceType getResultType()
    {
        return SequenceType.makeSequenceType(ItemType.DOCUMENT_NODE, OccurrenceIndicator.ZERO_OR_ONE); // TO-DO: return response header map
    }

    @Override
    public SequenceType[] getArgumentTypes()
    {
        return new SequenceType[]
        {
            SequenceType.makeSequenceType(ItemType.ANY_URI, OccurrenceIndicator.ONE), // URI href
            SequenceType.makeSequenceType(ItemType.STRING, OccurrenceIndicator.ONE), // method
            SequenceType.makeSequenceType(ItemType.STRING, OccurrenceIndicator.ZERO_OR_ONE), // media type
            SequenceType.makeSequenceType(ItemType.ANY_ITEM, OccurrenceIndicator.ZERO_OR_ONE), // body
            SequenceType.makeSequenceType(new ItemTypeFactory(getProcessor()).getMapType(ItemType.STRING,
                SequenceType.makeSequenceType(ItemType.STRING, OccurrenceIndicator.ZERO_OR_MORE)), OccurrenceIndicator.ONE) // headers as map(xs:string, xs:string*)
        };
    }

    @Override
    public XdmValue call(XdmValue[] arguments) throws SaxonApiException
    {
        String href = arguments[0].itemAt(0).getStringValue();
        String method = arguments[1].itemAt(0).getStringValue();
        MultivaluedMap<String, Object> headers = new MultivaluedHashMap(arguments[4].itemAt(0).
            asMap().
            entrySet().
            stream().
            collect(Collectors.toMap(
                e -> e.getKey().getStringValue(),
                e -> e.getValue().iterator().next().getStringValue())));

        try
        {
            final Response cr;
            if (arguments[2].isEmpty() || arguments[3].isEmpty()) // no media-type or body
                cr = getClient().target(href).request().headers(headers).build(method).invoke();
            else
            {
                String mediaType = arguments[2].itemAt(0).getStringValue();
                Entity entity = Entity.entity(arguments[3].itemAt(0).getStringValue(), mediaType);
                cr = getClient().target(href).request().headers(headers).build(method, entity).invoke();
            }
            if (!cr.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL))
            {
                if (log.isDebugEnabled()) log.debug("Could not execute ldh:send-request function. href: '{}' method: '{}'", href, method);
                throw new IOException("Could not execute ldh:send-request function. href: '" + href + "' method: '" + method + "'");
            }
            if (cr.hasEntity()) return getProcessor().newDocumentBuilder().build(new StreamSource(cr.readEntity(InputStream.class)));
            
            return XdmEmptySequence.getInstance();
        }
        catch (IOException ex)
        {
            throw new SaxonApiException(ex);
        }
    }

    /**
     * Returns the associated XSLT processor.
     * 
     * @return processor
     */
    public Processor getProcessor()
    {
        return processor;
    }
    
    /**
     * Returns the HTTP client.
     * 
     * @return HTTP client
     */
    public Client getClient()
    {
        return client;
    }
    
}
