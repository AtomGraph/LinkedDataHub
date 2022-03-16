/**
 *  Copyright 2019 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.server.util;

import java.nio.file.Path;

/**
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class WebIDCertGen
{
    
    private final String keyAlg;
    private final String storeType;
    
    /**
     * Constructs certificate generator.
     * 
     */
    public WebIDCertGen()
    {
        this("RSA", "PKCS12");
    }
    
    /**
     * Constructs certificate generator.
     * 
     * @param keyAlg key algorithm ID
     * @param storeType keystore type
     */
    public WebIDCertGen(String keyAlg, String storeType)
    {
        this.keyAlg = keyAlg;
        this.storeType = storeType;
    }
    
    /**
     * Generates keystore with a WebID client certificate.
     * This method accesses internal Sun APIs in order to replicate what Java's <code>keytool</code> CLI command does.
     * 
     * @param keyStorePath path to the keystore
     * @param storePass keystore password
     * @param keyPass key password
     * @param alias certificate alias
     * @param commonName subject's common name
     * @param orgUnit subject's organizational unit
     * @param organization subject's organization
     * @param locality subject's locality
     * @param stateOrProvinceName subject's state or province name
     * @param countryName subject's country name
     * @param webIDURI subject's WebID URI
     * @param validity certificate's validity period
     * @throws Exception certificate generation error
     */
    public void generate(Path keyStorePath, String storePass, String keyPass, String alias,
            String commonName, String orgUnit, String organization, String locality, String stateOrProvinceName, String countryName,
            String webIDURI, int validity) throws Exception
    {
        // escape commas with backslash
        String dName = "CN=" + escapeDName(commonName);
        if (orgUnit != null) dName += ", OU="+ escapeDName(orgUnit);
        if (organization != null) dName += ", O=" + escapeDName(organization);
        if (locality != null) dName += ", L=" + escapeDName(locality);
        if (stateOrProvinceName != null) dName += ", S=" + escapeDName(stateOrProvinceName);
        if (countryName != null) dName += ", C=" + escapeDName(countryName);
        
        String[] args =
        {
            "-genkeypair",
            "-keyalg", getKeyAlg(),
            "-storetype", getStoreType(),
            "-keystore", keyStorePath.toString(),
            "-storepass", storePass,
            "-keypass", keyPass,
            "-alias", alias,
            "-dname", dName,
            "-ext", "SAN=uri:" + webIDURI,
            "-validity", String.valueOf(validity)
        };
        
        sun.security.tools.keytool.Main.main(args);
    }

    /**
     * Escapes "Distinguished Name" value.
     * Escape the following characters with a backslash: <code>DQUOTE</code>/<code>PLUS</code>/<code>COMMA</code>/<code>SEMI</code>/<code>LANGLE</code>/<code>RANGLE</code>.
     * 
     * @param string raw DName value
     * @return escaped DName value
     * @see <a href="https://www.ietf.org/rfc/rfc4514.txt">String Representation of Distinguished Names</a>
     */
    public static String escapeDName(String string)
    {
        return string.replace("\"", "\\\"").
                replace("+", "\\+").
                replace(",", "\\,").
                replace(";", "\\;").
                replace("<", "\\<").
                replace(">", "\\>");
    }
    
    /**
     * Returns key algorithm.
     * 
     * @return algorithm ID
     */
    public String getKeyAlg()
    {
        return keyAlg;
    }
    
    /**
     * Returns keystore type.
     * 
     * @return keystore type
     */
    public String getStoreType()
    {
        return storeType;
    }
    
}
