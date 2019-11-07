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
package com.atomgraph.linkeddatahub.util;

import java.nio.file.Path;

/**
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class WebIDCertGen
{
    
    private final String keyAlg;
    private final String storeType;
    
    public WebIDCertGen()
    {
        this("RSA", "PKCS12");
    }
    
    public WebIDCertGen(String keyAlg, String storeType)
    {
        this.keyAlg = keyAlg;
        this.storeType = storeType;
    }
    
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

    // escape characters with backslash: DQUOTE / PLUS / COMMA / SEMI / LANGLE / RANGLE
    // https://www.ietf.org/rfc/rfc4514.txt
    public static String escapeDName(String string)
    {
        return string.replace("\"", "\\\"").
                replace("+", "\\+").
                replace(",", "\\,").
                replace(";", "\\;").
                replace("<", "\\<").
                replace(">", "\\>");
    }
    
    public String getKeyAlg()
    {
        return keyAlg;
    }
    
    public String getStoreType()
    {
        return storeType;
    }
    
}
