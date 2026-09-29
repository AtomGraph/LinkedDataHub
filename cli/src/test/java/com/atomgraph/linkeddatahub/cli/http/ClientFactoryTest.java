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

package com.atomgraph.linkeddatahub.cli.http;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.KeyStore;
import java.security.PrivateKey;
import java.util.Base64;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

/**
 * Tests for {@link ClientFactory}.
 */
public class ClientFactoryTest
{

    @TempDir
    private Path dir;

    static Path keyStorePath() throws Exception
    {
        return Paths.get(ClientFactoryTest.class.getResource("/test-keystore.p12").toURI());
    }

    static Path certPEMPath() throws Exception
    {
        return Paths.get(ClientFactoryTest.class.getResource("/test-cert.pem").toURI());
    }

    /** Writes the test credential as a PEM with an unencrypted key, the one shape that needs no password. */
    private Path unencryptedPEM() throws Exception
    {
        KeyStore keyStore = Credentials.load(keyStorePath(), "changeit");
        String alias = keyStore.aliases().nextElement();
        PrivateKey key = (PrivateKey) keyStore.getKey(alias, "changeit".toCharArray());
        Base64.Encoder encoder = Base64.getMimeEncoder(64, new byte[] { '\n' });
        Path file = dir.resolve("nodes.pem");
        Files.writeString(file,
            "-----BEGIN CERTIFICATE-----\n" + encoder.encodeToString(keyStore.getCertificate(alias).getEncoded()) + "\n-----END CERTIFICATE-----\n" +
            "-----BEGIN PRIVATE KEY-----\n" + encoder.encodeToString(key.getEncoded()) + "\n-----END PRIVATE KEY-----\n");

        return file;
    }

    @Test
    public void createsClientFromPKCS12Keystore() throws Exception
    {
        assertNotNull(ClientFactory.createClient(keyStorePath(), "changeit"));
    }

    @Test
    public void createsClientFromPEM() throws Exception
    {
        assertNotNull(ClientFactory.createClient(certPEMPath(), "changeit"));
    }

    @Test
    public void createsClientFromPEMWithUnencryptedKeyAndNoPassword() throws Exception
    {
        assertNotNull(ClientFactory.createClient(unencryptedPEM(), null));
    }

    @Test
    public void failsCleanlyOnWrongPassword() throws Exception
    {
        Path keyStore = keyStorePath();

        assertThrows(IllegalArgumentException.class, () -> ClientFactory.createClient(keyStore, "wrong"));
    }

    @Test
    public void failsCleanlyOnMissingFile()
    {
        assertThrows(IllegalArgumentException.class, () -> ClientFactory.createClient(Path.of("/nonexistent.p12"), "changeit"));
    }

}
