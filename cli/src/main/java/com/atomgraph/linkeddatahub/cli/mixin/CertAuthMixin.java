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

import java.nio.file.Path;
import picocli.CommandLine.Model.CommandSpec;
import picocli.CommandLine.Option;
import picocli.CommandLine.ParameterException;

/**
 * WebID client certificate options shared by all commands.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class CertAuthMixin
{

    @Option(names = {"-f", "--cert-file"}, defaultValue = "${env:LDH_CERT_FILE}", paramLabel = "CERT_FILE",
        description = ".p12 (PKCS12) keystore with the WebID certificate of the agent (env: LDH_CERT_FILE)")
    private Path certFile;

    @Option(names = {"-p", "--cert-password"}, defaultValue = "${env:LDH_CERT_PASSWORD}", paramLabel = "CERT_PASSWORD",
        description = "Password of the WebID certificate (env: LDH_CERT_PASSWORD)")
    private String certPassword;

    /**
     * Validates that both certificate options are present.
     *
     * @param spec command spec used to raise usage errors
     */
    public void validate(CommandSpec spec)
    {
        if (certFile == null) throw new ParameterException(spec.commandLine(), "Missing required option: '--cert-file=CERT_FILE' (or set LDH_CERT_FILE)");
        if (certPassword == null) throw new ParameterException(spec.commandLine(), "Missing required option: '--cert-password=CERT_PASSWORD' (or set LDH_CERT_PASSWORD)");
    }

    /**
     * Returns the keystore path.
     *
     * @return keystore path
     */
    public Path getCertFile()
    {
        return certFile;
    }

    /**
     * Returns the keystore password.
     *
     * @return keystore password
     */
    public String getCertPassword()
    {
        return certPassword;
    }

}
