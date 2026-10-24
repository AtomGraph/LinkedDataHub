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
package com.atomgraph.linkeddatahub.server.io;

import com.atomgraph.core.io.UpdateRequestProvider;
import com.atomgraph.linkeddatahub.server.exception.URISyntaxViolationException;
import com.atomgraph.linkeddatahub.server.util.InvalidIRIs;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.ext.Provider;
import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.Optional;
import org.apache.jena.query.QueryParseException;
import org.apache.jena.update.UpdateFactory;
import org.apache.jena.update.UpdateRequest;
import static com.atomgraph.core.MediaType.APPLICATION_SPARQL_UPDATE;

/**
 * SPARQL update reader that refuses malformed IRIs as URI syntax violations naming the value, as
 * {@link ValidatingModelProvider} does for RDF bodies. An IRI with a space or a <code>&lt;</code> in it stops the
 * lexer, and is read off the update at the error's position; any other the lexer lets through, so the parsed
 * update is checked as well, or the IRI would be stored.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
@Provider
@Consumes(APPLICATION_SPARQL_UPDATE)
@Produces(APPLICATION_SPARQL_UPDATE)
public class ValidatingUpdateRequestProvider extends UpdateRequestProvider
{

    @Override
    public UpdateRequest read(InputStream in, String baseURI)
    {
        final String update;
        try
        {
            update = new String(in.readAllBytes(), StandardCharsets.UTF_8);
        }
        catch (IOException ex)
        {
            throw new UncheckedIOException(ex);
        }

        final UpdateRequest updateRequest;
        try
        {
            updateRequest = UpdateFactory.create(update, baseURI);
        }
        catch (QueryParseException ex)
        {
            Optional<String> iri = InvalidIRIs.atError(update, ex);
            if (iri.isPresent()) throw new URISyntaxViolationException(Map.of(iri.get(), InvalidIRIs.check(iri.get()).get()));
            throw new BadRequestException(ex);
        }

        Map<String, String> violations = InvalidIRIs.of(updateRequest);
        if (!violations.isEmpty()) throw new URISyntaxViolationException(violations);

        return updateRequest;
    }

}
