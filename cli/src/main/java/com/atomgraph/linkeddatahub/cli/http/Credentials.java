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

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.GeneralSecurityException;
import java.security.KeyFactory;
import java.security.KeyStore;
import java.security.PrivateKey;
import java.security.cert.Certificate;
import java.security.cert.CertificateFactory;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.PKCS8EncodedKeySpec;
import java.util.Base64;
import javax.crypto.Cipher;
import javax.crypto.EncryptedPrivateKeyInfo;
import javax.crypto.SecretKey;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;

/**
 * Loads the agent's WebID credential into a keystore the TLS layer can use.
 *
 * Two formats are accepted, told apart by content rather than by file extension: a PKCS12
 * keystore, and a PEM file holding both the certificate and its PKCS#8 private key — the same
 * pairing <code>curl -E</code> requires. A PEM carrying a PKCS#1 or SEC1 key is rejected with the
 * conversion command, as the JDK has no parser for those.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class Credentials
{

    /** DER sequence tag, the first byte of a PKCS12 keystore. */
    private static final byte DER_SEQUENCE = 0x30;

    /** Alias the PEM certificate and key are stored under. */
    private static final String PEM_ALIAS = "webid";

    private static final String CERTIFICATE = "CERTIFICATE";
    private static final String PRIVATE_KEY = "PRIVATE KEY";
    private static final String ENCRYPTED_PRIVATE_KEY = "ENCRYPTED PRIVATE KEY";
    private static final String RSA_PRIVATE_KEY = "RSA PRIVATE KEY";
    private static final String EC_PRIVATE_KEY = "EC PRIVATE KEY";

    private Credentials() { }

    /**
     * Loads the credential file into a keystore.
     *
     * @param certFile PKCS12 keystore or PEM file with the certificate and its private key
     * @param password keystore password, or the passphrase of an encrypted PEM key; null for an unencrypted PEM
     * @return keystore holding the agent's certificate and private key
     */
    public static KeyStore load(Path certFile, String password)
    {
        if (isPKCS12(certFile)) return loadPKCS12(certFile, password);

        return loadPEM(certFile, password);
    }

    /**
     * Returns whether opening the credential needs a password: a PKCS12 keystore always does, a PEM
     * only when its private key is encrypted. A file that cannot be read, or one whose key is in a
     * format {@link #load(Path, String)} rejects, reports false and leaves the error to the load.
     *
     * @param certFile credential file
     * @return true if a password is required
     */
    public static boolean requiresPassword(Path certFile)
    {
        if (!Files.isReadable(certFile)) return false;
        if (isPKCS12(certFile)) return true;

        return readString(certFile).contains(begin(ENCRYPTED_PRIVATE_KEY));
    }

    /**
     * Tells a PKCS12 keystore from a PEM file by its first byte: DER starts with a sequence tag,
     * PEM with the dashes of its first header.
     */
    private static boolean isPKCS12(Path certFile)
    {
        try (InputStream is = Files.newInputStream(certFile))
        {
            return is.read() == DER_SEQUENCE;
        }
        catch (IOException ex)
        {
            throw new IllegalArgumentException("Could not read certificate file '" + certFile + "': " + ex.getMessage(), ex);
        }
    }

    private static KeyStore loadPKCS12(Path certFile, String password)
    {
        if (password == null) throw new IllegalArgumentException("PKCS12 keystore '" + certFile + "' cannot be opened without a password");

        try (InputStream is = Files.newInputStream(certFile))
        {
            KeyStore keyStore = KeyStore.getInstance("PKCS12");
            keyStore.load(is, password.toCharArray());

            return keyStore;
        }
        catch (IOException ex) // PKCS12 reports a failed MAC check as an IOException
        {
            throw new IllegalArgumentException("Could not load PKCS12 keystore '" + certFile + "': " + ex.getMessage() + " (wrong password?)", ex);
        }
        catch (GeneralSecurityException ex)
        {
            throw new IllegalArgumentException("Could not load PKCS12 keystore '" + certFile + "': " + ex.getMessage(), ex);
        }
    }

    private static KeyStore loadPEM(Path certFile, String password)
    {
        String pem = readString(certFile);

        if (!pem.contains(begin(CERTIFICATE)))
            throw new IllegalArgumentException("No certificate in '" + certFile + "': expected a PKCS12 keystore, or a PEM file with the certificate and its private key");

        if (pem.contains(begin(RSA_PRIVATE_KEY)) || pem.contains(begin(EC_PRIVATE_KEY)))
            throw new IllegalArgumentException("Private key in '" + certFile + "' is PKCS#1/SEC1, which Java cannot read. Convert it: openssl pkcs8 -topk8 -in " + certFile + " -out key.pem");

        if (!pem.contains(begin(PRIVATE_KEY)) && !pem.contains(begin(ENCRYPTED_PRIVATE_KEY)))
            throw new IllegalArgumentException("No private key in '" + certFile + "': client authentication needs the certificate and its private key in the same file");

        try
        {
            Certificate cert = CertificateFactory.getInstance("X.509").
                generateCertificate(new ByteArrayInputStream(block(pem, CERTIFICATE)));
            PrivateKey key = readPrivateKey(pem, password, certFile);

            // the in-memory keystore takes the password the PEM was opened with, an empty one when it had none
            char[] keyPassword = password != null ? password.toCharArray() : new char[0];
            KeyStore keyStore = KeyStore.getInstance("PKCS12");
            keyStore.load(null, keyPassword);
            keyStore.setKeyEntry(PEM_ALIAS, key, keyPassword, new Certificate[] { cert });

            return keyStore;
        }
        catch (IOException | GeneralSecurityException ex)
        {
            throw new IllegalArgumentException("Could not load the certificate and private key from '" + certFile + "': " + ex.getMessage(), ex);
        }
    }

    /**
     * Reads the PEM private key, decrypting it when the file carries an encrypted PKCS#8 block.
     * LinkedDataHub issues RSA WebID certificates, which is what WebID authentication matches on.
     */
    private static PrivateKey readPrivateKey(String pem, String password, Path certFile) throws IOException, GeneralSecurityException
    {
        KeyFactory keyFactory = KeyFactory.getInstance("RSA");

        if (!pem.contains(begin(ENCRYPTED_PRIVATE_KEY)))
            return keyFactory.generatePrivate(new PKCS8EncodedKeySpec(block(pem, PRIVATE_KEY)));

        EncryptedPrivateKeyInfo keyInfo = new EncryptedPrivateKeyInfo(block(pem, ENCRYPTED_PRIVATE_KEY));
        SecretKey pbeKey = SecretKeyFactory.getInstance(keyInfo.getAlgName()).
            generateSecret(new PBEKeySpec(password.toCharArray()));
        Cipher cipher = Cipher.getInstance(keyInfo.getAlgName());
        cipher.init(Cipher.DECRYPT_MODE, pbeKey, keyInfo.getAlgParameters());

        try
        {
            return keyFactory.generatePrivate(keyInfo.getKeySpec(cipher));
        }
        catch (InvalidKeySpecException ex)
        {
            throw new IllegalArgumentException("Could not decrypt the private key in '" + certFile + "' (wrong password?)", ex);
        }
    }

    /** Returns the DER bytes of the first PEM block of a type. */
    private static byte[] block(String pem, String type)
    {
        int start = pem.indexOf(begin(type));
        int end = pem.indexOf("-----END " + type + "-----", start);

        return Base64.getMimeDecoder().decode(pem.substring(start + begin(type).length(), end));
    }

    private static String begin(String type)
    {
        return "-----BEGIN " + type + "-----";
    }

    private static String readString(Path certFile)
    {
        try
        {
            // ISO-8859-1 maps every byte, so a file that is not PEM reaches the format error below
            // instead of failing to decode; PEM headers and base64 are ASCII either way
            return Files.readString(certFile, StandardCharsets.ISO_8859_1);
        }
        catch (IOException ex)
        {
            throw new IllegalArgumentException("Could not read certificate file '" + certFile + "': " + ex.getMessage(), ex);
        }
    }

}
