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

import org.apache.jena.ontapi.OntModelFactory;
import org.apache.jena.ontapi.OntSpecification;
import org.apache.jena.ontapi.model.OntModel;
import org.apache.jena.rdf.model.Property;

import org.apache.jena.rdf.model.Resource;

/**
 * LinkedDataHub configuration vocabulary.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class LDHC
{

    static
    {
        org.apache.jena.sys.JenaSystem.init(); // ensure Jena (RDFS vocab) is initialized before ontapi touches it
    }
    /** The RDF model that holds the vocabulary terms */
    private static OntModel m_model = OntModelFactory.createModel(OntSpecification.OWL2_DL_MEM);
    
    /** The namespace of the vocabulary as a string */
    public static final String NS = "https://w3id.org/atomgraph/linkeddatahub/config#";
    
    /**
     * The namespace of the vocabulary as a string
     * 
     * @return namespace URI
     * @see #NS
     */
    public static String getURI()
    {
        return NS;
    }
    
    /** The namespace of the vocabulary as a resource */
    public static final Resource NAMESPACE = m_model.createResource( NS );

    /** Base URI property */
    public static final Property baseUri = m_model.createObjectProperty( NS + "baseUri" );
    
    /** Proxy scheme property */
    public static final Property proxyScheme = m_model.createDataProperty( NS + "proxyScheme" );
    
    /** Proxy host property */
    public static final Property proxyHost = m_model.createDataProperty( NS + "proxyHost" );

    /** Proxy port property */
    public static final Property proxyPort = m_model.createDataProperty( NS + "proxyPort" );

    /** Document type query property */
    public static final Property documentTypeQuery = m_model.createDataProperty( NS + "documentTypeQuery" );

    /** Document owner query property */
    public static final Property documentOwnerQuery = m_model.createDataProperty( NS + "documentOwnerQuery" );

    /** ACL query property */
    public static final Property aclQuery = m_model.createDataProperty( NS + "aclQuery" );

    /** Owner's ACL property */
    public static final Property ownerAclQuery = m_model.createDataProperty( NS + "ownerAclQuery" );

    /** WebID query property */
    public static final Property webIDQuery = m_model.createDataProperty( NS + "webIDQuery" );

    /** Agent query property */
    public static final Property agentQuery = m_model.createDataProperty( NS + "agentQuery" );

    /** User account query property */
    public static final Property userAccountQuery = m_model.createDataProperty( NS + "userAccountQuery" );
    
    /** Ontology query property */
    public static final Property ontologyQuery = m_model.createDataProperty( NS + "ontologyQuery" );

    /** Upload root property */
    public static final Property uploadRoot = m_model.createObjectProperty( NS + "uploadRoot" );

    /** Invalidate cache property */
    public static final Property invalidateCache = m_model.createDataProperty( NS + "invalidateCache" );

    /** Cookie max age property */
    public static final Property cookieMaxAge = m_model.createDataProperty( NS + "cookieMaxAge" );
    
    /** Client keystore property */
    public static final Property clientKeyStore = m_model.createObjectProperty( NS + "clientKeyStore" );
    
    /** Client keystore password property */
    public static final Property clientKeyStorePassword = m_model.createDataProperty( NS + "clientKeyStorePassword" );

    /** Secretary cert alias property */
    public static final Property secretaryCertAlias = m_model.createDataProperty( NS + "secretaryCertAlias" );
        
    /** Client truststore property */
    public static final Property clientTrustStore = m_model.createObjectProperty( NS + "clientTrustStore" );
    
    /** Client truststore password property */
    public static final Property clientTrustStorePassword = m_model.createDataProperty( NS + "clientTrustStorePassword" );

    /** Signup email subject property */
    public static final Property signUpEMailSubject = m_model.createDataProperty( NS + "signUpEMailSubject" );
    
    /** WebID signup email text property */
    public static final Property webIDSignUpEMailText = m_model.createDataProperty( NS + "webIDSignUpEMailText" );

    /** OAuth signup email text property */
    public static final Property oAuthSignUpEMailText = m_model.createDataProperty( NS + "oAuthSignUpEMailText" );

    /** Notification address property */
    public static final Property notificationAddress = m_model.createDataProperty( NS + "notificationAddress" );

    /** Request access email subject property */
    public static final Property requestAccessEMailSubject = m_model.createDataProperty( NS + "requestAccessEMailSubject" );
    
    /** Request access email text property */
    public static final Property requestAccessEMailText = m_model.createDataProperty( NS + "requestAccessEMailText" );

    /** Authorization email subject property */
    public static final Property authorizationEMailSubject = m_model.createDataProperty( NS + "authorizationEMailSubject" );
    
    /** Authorization email text property */
    public static final Property authorizationEMailText = m_model.createDataProperty( NS + "authorizationEMailText" );

    /** Signup cert validity property */
    public static final Property signUpCertValidity = m_model.createDataProperty( NS + "signUpCertValidity" );

    /** Context dataset property */
    public static final Property contextDataset = m_model.createObjectProperty( NS + "contextDataset" );

    /** Max connections per route property */
    public static final Property maxConnPerRoute = m_model.createDataProperty( NS + "maxConnPerRoute" );
    
    /** Max total connections property */
    public static final Property maxTotalConn = m_model.createDataProperty( NS + "maxTotalConn" );

    /** Import keep-alive property */
    public static final Property importKeepAlive = m_model.createDataProperty( NS + "importKeepAlive" );

    /** HTTP client request retry count */
    public static final Property maxRequestRetries = m_model.createDataProperty( NS + "maxRequestRetries" );

    /** Timeout in milliseconds waiting for a connection from the HTTP client pool */
    public static final Property connectionRequestTimeout = m_model.createDataProperty( NS + "connectionRequestTimeout" );

    /** Max content length property */
    public static final Property maxContentLength = m_model.createDataProperty( NS + "maxContentLength" );

    /** Support languages property */
    public static final Property supportedLanguages = m_model.createDataProperty( NS + "supportedLanguages" );

    /** Max import threads property */
    public static final Property maxImportThreads = m_model.createDataProperty( NS + "maxImportThreads" );

    /** Enable WebID signup property **/
    public static final Property enableWebIDSignUp = m_model.createDataProperty( NS + "enableWebIDSignUp" );

    /** Enable Linked Data proxy property */
    public static final Property enableLinkedDataProxy = m_model.createDataProperty( NS + "enableLinkedDataProxy" );

    /** Allow internal URLs property */
    public static final Property allowInternalUrls = m_model.createDataProperty( NS + "allowInternalUrls" );

    /** OIDC refresh token properties property */
    public static final Property oidcRefreshTokens = m_model.createDataProperty( NS + "oidcRefreshTokens" );

    /** Frontend proxy URI property (Varnish frontend cache, used for cache invalidation) */
    public static final Property frontendProxy = m_model.createObjectProperty( NS + "frontendProxy" );

    /** Backend proxy URI for the admin SPARQL service (used for cache invalidation and endpoint URI rewriting) */
    public static final Property backendProxyAdmin = m_model.createObjectProperty( NS + "backendProxyAdmin" );

    /** Backend proxy URI for the end-user SPARQL service (used for cache invalidation and endpoint URI rewriting) */
    public static final Property backendProxyEndUser = m_model.createObjectProperty( NS + "backendProxyEndUser" );

}
