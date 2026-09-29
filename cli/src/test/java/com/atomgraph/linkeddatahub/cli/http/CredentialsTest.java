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
import java.security.KeyStore;
import java.security.PrivateKey;
import java.security.cert.Certificate;
import java.util.Base64;
import java.util.Enumeration;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Tests for {@link Credentials}, covering both accepted formats and the PEM shapes that are not.
 * <code>test-cert.pem</code> is the same credential as <code>test-keystore.p12</code> exported by
 * openssl, so it carries the PBES2 encryption the platform's own PEMs do; the remaining shapes need
 * no encryption and are derived from the keystore in-test.
 */
public class CredentialsTest
{

    private static final String PASSWORD = "changeit";

    private static Certificate cert;
    private static PrivateKey key;

    @TempDir
    private Path dir;

    @BeforeAll
    public static void readKeystore() throws Exception
    {
        KeyStore keyStore = Credentials.load(keyStorePath(), PASSWORD);
        String alias = keyStore.aliases().nextElement();
        cert = keyStore.getCertificate(alias);
        key = (PrivateKey) keyStore.getKey(alias, PASSWORD.toCharArray());
    }

    static Path keyStorePath() throws Exception
    {
        return Path.of(CredentialsTest.class.getResource("/test-keystore.p12").toURI());
    }

    static Path certPEMPath() throws Exception
    {
        return Path.of(CredentialsTest.class.getResource("/test-cert.pem").toURI());
    }

    // fixtures

    private static String pem(String type, byte[] der)
    {
        return "-----BEGIN " + type + "-----\n" +
            Base64.getMimeEncoder(64, new byte[] { '\n' }).encodeToString(der) +
            "\n-----END " + type + "-----\n";
    }

    private Path write(String name, String contents) throws Exception
    {
        Path file = dir.resolve(name);
        Files.writeString(file, contents);

        return file;
    }

    private Path unencryptedPEM() throws Exception
    {
        return write("nodes.pem", pem("CERTIFICATE", cert.getEncoded()) + pem("PRIVATE KEY", key.getEncoded()));
    }

    private static void assertHoldsKeyAndCertificate(KeyStore keyStore) throws Exception
    {
        Enumeration<String> aliases = keyStore.aliases();
        assertTrue(aliases.hasMoreElements(), "keystore has no entries");
        String alias = aliases.nextElement();
        assertTrue(keyStore.isKeyEntry(alias), "entry '" + alias + "' holds no private key");
        assertEquals(1, keyStore.getCertificateChain(alias).length);
    }

    // accepted formats

    @Test
    public void loadsPKCS12Keystore() throws Exception
    {
        assertHoldsKeyAndCertificate(Credentials.load(keyStorePath(), PASSWORD));
    }

    @Test
    public void loadsPEMWithEncryptedKey() throws Exception
    {
        assertHoldsKeyAndCertificate(Credentials.load(certPEMPath(), PASSWORD));
    }

    @Test
    public void loadsPEMWithUnencryptedKeyWithoutPassword() throws Exception
    {
        assertHoldsKeyAndCertificate(Credentials.load(unencryptedPEM(), null));
    }

    @Test
    public void readsFormatFromContentNotExtension() throws Exception
    {
        Path pkcs12 = dir.resolve("cert.pem"); // a PKCS12 keystore named .pem
        Files.copy(keyStorePath(), pkcs12);

        assertHoldsKeyAndCertificate(Credentials.load(pkcs12, PASSWORD));
    }

    // password requirement

    @Test
    public void requiresPasswordForPKCS12AndEncryptedPEM() throws Exception
    {
        assertTrue(Credentials.requiresPassword(keyStorePath()));
        assertTrue(Credentials.requiresPassword(certPEMPath()));
    }

    @Test
    public void needsNoPasswordForUnencryptedPEM() throws Exception
    {
        assertFalse(Credentials.requiresPassword(unencryptedPEM()));
    }

    @Test
    public void leavesAnUnreadableFileToTheLoad()
    {
        assertFalse(Credentials.requiresPassword(Path.of("/nonexistent.p12")));
    }

    // rejected shapes

    @Test
    public void rejectsCertificateWithoutKey() throws Exception
    {
        Path certOnly = write("public.pem", pem("CERTIFICATE", cert.getEncoded()));
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> Credentials.load(certOnly, PASSWORD));

        assertTrue(ex.getMessage().contains("No private key"), ex.getMessage());
    }

    @Test
    public void rejectsKeyWithoutCertificate() throws Exception
    {
        Path keyOnly = write("key.pem", pem("PRIVATE KEY", key.getEncoded()));
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> Credentials.load(keyOnly, null));

        assertTrue(ex.getMessage().contains("No certificate"), ex.getMessage());
    }

    @Test
    public void rejectsPKCS1KeyWithTheConversionCommand() throws Exception
    {
        // the header alone is what the rejection reads, so the body need not be PKCS#1
        Path pkcs1 = write("legacy.pem", pem("CERTIFICATE", cert.getEncoded()) + pem("RSA PRIVATE KEY", key.getEncoded()));
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> Credentials.load(pkcs1, PASSWORD));

        assertTrue(ex.getMessage().contains("openssl pkcs8 -topk8"), ex.getMessage());
    }

    @Test
    public void rejectsAFileThatIsNeitherFormat() throws Exception
    {
        // non-ASCII bytes must not turn the format error into a decoding error
        Path text = write("notes.md", "# Notes\n\nMartynas Jusevičius\n");
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> Credentials.load(text, PASSWORD));

        assertTrue(ex.getMessage().contains("expected a PKCS12 keystore"), ex.getMessage());
    }

    @Test
    public void rejectsWrongPEMPassword() throws Exception
    {
        Path pem = certPEMPath();

        assertThrows(IllegalArgumentException.class, () -> Credentials.load(pem, "wrong"));
    }

    @Test
    public void rejectsAKeystoreWithoutAPassword() throws Exception
    {
        Path keyStore = keyStorePath();
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> Credentials.load(keyStore, null));

        assertTrue(ex.getMessage().contains("without a password"), ex.getMessage());
    }

    @Test
    public void rejectsWrongKeystorePassword() throws Exception
    {
        Path keyStore = keyStorePath();
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> Credentials.load(keyStore, "wrong"));

        assertTrue(ex.getMessage().contains("wrong password?"), ex.getMessage());
    }

}
