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
public class LDHC
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

    /** Base URI property */
    public static final ObjectProperty baseUri = m_model.createObjectProperty( NS + "baseUri" );
    
    /** Proxy scheme property */
    public static final DatatypeProperty proxyScheme = m_model.createDatatypeProperty( NS + "proxyScheme" );
    
    /** Proxy host property */
    public static final DatatypeProperty proxyHost = m_model.createDatatypeProperty( NS + "proxyHost" );

    /** Proxy port property */
    public static final DatatypeProperty proxyPort = m_model.createDatatypeProperty( NS + "proxyPort" );

    /** Auth query property */
    public static final DatatypeProperty authQuery = m_model.createDatatypeProperty( NS + "authQuery" );

    /** Owner auth property */
    public static final DatatypeProperty ownerAuthQuery = m_model.createDatatypeProperty( NS + "ownerAuthQuery" );

    /** WebID query property */
    public static final DatatypeProperty webIDQuery = m_model.createDatatypeProperty( NS + "webIDQuery" );
    
    /** User account query property */
    public static final DatatypeProperty userAccountQuery = m_model.createDatatypeProperty( NS + "userAccountQuery" );
    
    /** Ontology query property */
    public static final DatatypeProperty ontologyQuery = m_model.createDatatypeProperty( NS + "ontologyQuery" );

    /** Upload root property */
    public static final ObjectProperty uploadRoot = m_model.createObjectProperty( NS + "uploadRoot" );

    /** Invalidate cache property */
    public static final DatatypeProperty invalidateCache = m_model.createDatatypeProperty( NS + "invalidateCache" );

    /** Cookie max age property */
    public static final DatatypeProperty cookieMaxAge = m_model.createDatatypeProperty( NS + "cookieMaxAge" );
    
    /** Client keystore property */
    public static final ObjectProperty clientKeyStore = m_model.createObjectProperty( NS + "clientKeyStore" );
    
    /** Client keystore password property */
    public static final DatatypeProperty clientKeyStorePassword = m_model.createDatatypeProperty( NS + "clientKeyStorePassword" );

    /** Secretary cert alias property */
    public static final DatatypeProperty secretaryCertAlias = m_model.createDatatypeProperty( NS + "secretaryCertAlias" );
        
    /** Client truststore property */
    public static final ObjectProperty clientTrustStore = m_model.createObjectProperty( NS + "clientTrustStore" );
    
    /** Client truststore password property */
    public static final DatatypeProperty clientTrustStorePassword = m_model.createDatatypeProperty( NS + "clientTrustStorePassword" );

    /** Signup email subject property */
    public static final DatatypeProperty signUpEMailSubject = m_model.createDatatypeProperty( NS + "signUpEMailSubject" );
    
    /** WebID signup email text property */
    public static final DatatypeProperty webIDSignUpEMailText = m_model.createDatatypeProperty( NS + "webIDSignUpEMailText" );

    /** OAuth signup email text property */
    public static final DatatypeProperty oAuthSignUpEMailText = m_model.createDatatypeProperty( NS + "oAuthSignUpEMailText" );

    /** Notification address property */
    public static final DatatypeProperty notificationAddress = m_model.createDatatypeProperty( NS + "notificationAddress" );

    /** Request access email subject property */
    public static final DatatypeProperty requestAccessEMailSubject = m_model.createDatatypeProperty( NS + "requestAccessEMailSubject" );
    
    /** Request access email text property */
    public static final DatatypeProperty requestAccessEMailText = m_model.createDatatypeProperty( NS + "requestAccessEMailText" );

    /** Authorization email subject property */
    public static final DatatypeProperty authorizationEMailSubject = m_model.createDatatypeProperty( NS + "authorizationEMailSubject" );
    
    /** Authorization email text property */
    public static final DatatypeProperty authorizationEMailText = m_model.createDatatypeProperty( NS + "authorizationEMailText" );

    /** Signup cert validity property */
    public static final DatatypeProperty signUpCertValidity = m_model.createDatatypeProperty( NS + "signUpCertValidity" );

    /** Context dataset property */
    public static final ObjectProperty contextDataset = m_model.createObjectProperty( NS + "contextDataset" );

    /** Max connections per route property */
    public static final DatatypeProperty maxConnPerRoute = m_model.createDatatypeProperty( NS + "maxConnPerRoute" );
    
    /** Max total connections property */
    public static final DatatypeProperty maxTotalConn = m_model.createDatatypeProperty( NS + "maxTotalConn" );

    /** Import keep-alive property */
    public static final DatatypeProperty importKeepAlive = m_model.createDatatypeProperty( NS + "importKeepAlive" );
    
    /** Max content length property */
    public static final DatatypeProperty maxContentLength = m_model.createDatatypeProperty( NS + "maxContentLength" );

}
