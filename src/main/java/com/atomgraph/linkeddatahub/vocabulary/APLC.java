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
package com.atomgraph.linkeddatahub.vocabulary;

import org.apache.jena.ontology.DatatypeProperty;
import org.apache.jena.ontology.ObjectProperty;
import org.apache.jena.ontology.OntModel;
import org.apache.jena.ontology.OntModelSpec;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;

/**
 * LinkedDataHub configuration vocabulary.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class APLC
{
    /** <p>The RDF model that holds the vocabulary terms</p> */
    private static OntModel m_model = ModelFactory.createOntologyModel(OntModelSpec.OWL_MEM, null);
    
    /** <p>The namespace of the vocabulary as a string</p> */
    public static final String NS = "https://w3id.org/atomgraph/linkeddatahub/config#";
    
    /** <p>The namespace of the vocabulary as a string</p>
     *  @see #NS */
    public static String getURI()
    {
        return NS;
    }
    
    /** <p>The namespace of the vocabulary as a resource</p> */
    public static final Resource NAMESPACE = m_model.createResource( NS );

    // CONFIG

    public static final ObjectProperty baseUri = m_model.createObjectProperty( NS + "baseUri" );
    
    public static final DatatypeProperty authQuery = m_model.createDatatypeProperty( NS + "authQuery" );

    public static final DatatypeProperty ownerAuthQuery = m_model.createDatatypeProperty( NS + "ownerAuthQuery" );

    public static final DatatypeProperty webIDQuery = m_model.createDatatypeProperty( NS + "webIDQuery" );

    public static final DatatypeProperty authCacheControl = m_model.createDatatypeProperty( NS + "authCacheControl" );

    public static final DatatypeProperty sitemapQuery = m_model.createDatatypeProperty( NS + "sitemapQuery" );

    public static final DatatypeProperty graphDocumentQuery = m_model.createDatatypeProperty( NS + "graphDocumentQuery" );
    
    public static final DatatypeProperty restrictionsQuery = m_model.createDatatypeProperty( NS + "restrictionsQuery" );
    
    public static final DatatypeProperty putUpdate = m_model.createDatatypeProperty( NS + "putUpdate" );
    
    public static final DatatypeProperty deleteUpdate = m_model.createDatatypeProperty( NS + "deleteUpdate" );
    
    public static final ObjectProperty uploadRoot = m_model.createObjectProperty( NS + "uploadRoot" );

    public static final DatatypeProperty remoteVariableBindings = m_model.createDatatypeProperty( NS + "remoteVariableBindings" );

    public static final DatatypeProperty invalidateCache = m_model.createDatatypeProperty( NS + "invalidateCache" );

    public static final DatatypeProperty cookieMaxAge = m_model.createDatatypeProperty( NS + "cookieMaxAge" );
    
    public static final ObjectProperty clientKeyStore = m_model.createObjectProperty( NS + "clientKeyStore" );
    
    public static final DatatypeProperty clientKeyStorePassword = m_model.createDatatypeProperty( NS + "clientKeyStorePassword" );

    public static final DatatypeProperty secretaryCertAlias = m_model.createDatatypeProperty( NS + "secretaryCertAlias" );
        
    public static final ObjectProperty clientTrustStore = m_model.createObjectProperty( NS + "clientTrustStore" );
    
    public static final DatatypeProperty clientTrustStorePassword = m_model.createDatatypeProperty( NS + "clientTrustStorePassword" );

    public static final DatatypeProperty signUpAddress = m_model.createDatatypeProperty( NS + "signUpAddress" );

    public static final DatatypeProperty signUpEMailSubject = m_model.createDatatypeProperty( NS + "signUpEMailSubject" );
    
    public static final DatatypeProperty webIDSignUpEMailText = m_model.createDatatypeProperty( NS + "webIDSignUpEMailText" );

    public static final DatatypeProperty oAuthSignUpEMailText = m_model.createDatatypeProperty( NS + "oAuthSignUpEMailText" );

    public static final DatatypeProperty notificationAddress = m_model.createDatatypeProperty( NS + "notificationAddress" );

    public static final DatatypeProperty requestAccessEMailSubject = m_model.createDatatypeProperty( NS + "requestAccessEMailSubject" );
    
    public static final DatatypeProperty requestAccessEMailText = m_model.createDatatypeProperty( NS + "requestAccessEMailText" );
    
    public static final DatatypeProperty signUpCertValidity = m_model.createDatatypeProperty( NS + "signUpCertValidity" );

    public static final ObjectProperty contextDataset = m_model.createObjectProperty( NS + "contextDataset" );

    public static final DatatypeProperty appQuery = m_model.createDatatypeProperty( NS + "appQuery" );
    
    public static final DatatypeProperty insertOwnerUpdate = m_model.createDatatypeProperty( NS + "insertOwnerUpdate" );
    
    public static final DatatypeProperty ontologyImportQuery = m_model.createDatatypeProperty( NS + "ontologyImportQuery" );

    public static final DatatypeProperty maxConnPerRoute = m_model.createDatatypeProperty( NS + "maxConnPerRoute" );
    
    public static final DatatypeProperty maxTotalConn = m_model.createDatatypeProperty( NS + "maxTotalConn" );

    public static final DatatypeProperty importKeepAlive = m_model.createDatatypeProperty( NS + "importKeepAlive" );
    
}
