/*
 * Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.atomgraph.linkeddatahub.cli.mixin;

import java.net.URI;
import picocli.CommandLine.Model.CommandSpec;
import picocli.CommandLine.ParameterException;
import picocli.CommandLine.Parameters;

/**
 * Application base URI, the positional parameter of the commands that address no document of their
 * own and so need the dataspace named: the <code>packages</code> family, the admin
 * <code>create</code>, <code>clear</code> and <code>import</code> commands and <code>make-public</code>.
 * It is the thing those commands act on, which is why it sits where every other command puts its
 * target.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class BaseMixin
{

    @Parameters(index = "0", arity = "0..1", defaultValue = "${env:LDH_BASE}", paramLabel = "BASE_URI",
        description = "Base URI of the application (default: LDH_BASE)")
    private URI base;

    /**
     * Validates presence of the base URI and returns it.
     *
     * @param spec command spec used to raise usage errors
     * @return base URI
     */
    public URI require(CommandSpec spec)
    {
        if (base == null) throw new ParameterException(spec.commandLine(), "Missing required parameter: 'BASE_URI' (or set LDH_BASE)");

        return base;
    }

    /**
     * Returns the base URI, if any.
     *
     * @return base URI or null
     */
    public URI getBase()
    {
        return base;
    }

}
