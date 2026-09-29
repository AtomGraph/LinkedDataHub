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

import com.atomgraph.linkeddatahub.cli.http.Credentials;
import java.nio.file.Path;
import picocli.CommandLine.Model.CommandSpec;
import picocli.CommandLine.Option;
import picocli.CommandLine.ParameterException;

/**
 * WebID client certificate options shared by all commands. The credential is a PKCS12 keystore or a
 * PEM file with the certificate and its private key.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class CertAuthMixin
{

    @Option(names = {"-c", "--cert"}, defaultValue = "${env:LDH_CERT_FILE}", paramLabel = "CERT_FILE",
        description = "PKCS12 keystore or PEM with the WebID certificate and private key of the agent (env: LDH_CERT_FILE)")
    private Path certFile;

    @Option(names = {"-p", "--cert-password"}, defaultValue = "${env:LDH_CERT_PASSWORD}", paramLabel = "PASSWORD",
        description = "Password of the keystore, or passphrase of an encrypted PEM key (env: LDH_CERT_PASSWORD)")
    private String certPassword;

    /**
     * Validates that the certificate options the credential needs are present. A password is
     * required for a PKCS12 keystore and for a PEM whose private key is encrypted, and is left out
     * for an unencrypted PEM.
     *
     * @param spec command spec used to raise usage errors
     */
    public void validate(CommandSpec spec)
    {
        if (certFile == null) throw new ParameterException(spec.commandLine(), "Missing required option: '--cert=CERT_FILE' (or set LDH_CERT_FILE)");
        if (certPassword == null && Credentials.requiresPassword(certFile)) throw new ParameterException(spec.commandLine(), "Missing required option: '--cert-password=PASSWORD' (or set LDH_CERT_PASSWORD)");
    }

    /**
     * Returns the credential path.
     *
     * @return path of the PKCS12 keystore or PEM file
     */
    public Path getCertFile()
    {
        return certFile;
    }

    /**
     * Returns the credential password.
     *
     * @return keystore password or PEM key passphrase, null when the PEM key is unencrypted
     */
    public String getCertPassword()
    {
        return certPassword;
    }

}
