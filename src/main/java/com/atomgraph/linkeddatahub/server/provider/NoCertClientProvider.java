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
package com.atomgraph.linkeddatahub.server.provider;

import com.atomgraph.core.io.DatasetProvider;
import com.atomgraph.core.io.ModelProvider;
import com.atomgraph.core.io.QueryProvider;
import com.atomgraph.core.io.ResultSetProvider;
import com.atomgraph.core.io.UpdateRequestReader;
import java.security.KeyManagementException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import javax.inject.Singleton;
import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSession;
import javax.net.ssl.TrustManagerFactory;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.client.Client;
import javax.ws.rs.client.ClientBuilder;
import javax.ws.rs.ext.Provider;
import org.apache.http.conn.ClientConnectionManager;
import org.apache.http.conn.scheme.PlainSocketFactory;
import org.apache.http.conn.scheme.Scheme;
import org.apache.http.conn.scheme.SchemeRegistry;
import org.apache.http.conn.ssl.SSLSocketFactory;
import org.apache.http.impl.conn.tsccm.ThreadSafeClientConnManager;
import org.glassfish.hk2.api.Factory;
import org.glassfish.jersey.apache.connector.ApacheClientProperties;
import org.glassfish.jersey.client.ClientConfig;
import org.glassfish.jersey.client.HttpUrlConnectorProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * JAX-RS provider of an HTTP client which does not send SSL client certificate.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
@Provider
@Singleton
public class NoCertClientProvider implements Factory<Client> // extends PerRequestTypeInjectableProvider<Context, NoCertClient> implements ContextResolver<NoCertClient>
{

    private static final Logger log = LoggerFactory.getLogger(NoCertClientProvider.class);
    
    private final KeyStore trustStore;
    private final Client client;
    
    public NoCertClientProvider(KeyStore trustStore)
    {
        this.trustStore = trustStore;
        
//        clientConfig.getProperties().put(URLConnectionClientHandler.PROPERTY_HTTP_URL_CONNECTION_SET_METHOD_WORKAROUND, true);
        // cannot CSVReader with Client because it depends on request URI
        //clientConfig.getProperties().put(ApacheHttpClient4Config.PROPERTY_CONNECTION_MANAGER, new ThreadSafeClientConnManager());
//        clientConfig.getProperties().put(ApacheHttpClient4Config.PROPERTY_ENABLE_BUFFERING , true);
        ClientConfig clientConfig = new ClientConfig();
        clientConfig.connectorProvider(new HttpUrlConnectorProvider().useSetMethodWorkaround());
        clientConfig.register(new ModelProvider());
        clientConfig.register(new DatasetProvider());
        clientConfig.register(new ResultSetProvider());
        clientConfig.register(new QueryProvider());
        clientConfig.register(new UpdateRequestReader()); // TO-DO: UpdateRequestProvider
        
        try
        {
            // for trusting server certificate
            TrustManagerFactory tmf = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
            tmf.init(trustStore);
            
            SSLContext ctx = SSLContext.getInstance("TLSv1");
            ctx.init(null, tmf.getTrustManagers(), null);

            HostnameVerifier hv = new HostnameVerifier()
            {
                @Override
                public boolean verify(String hostname, SSLSession session)
                {
                    if ( log.isDebugEnabled()) log.debug("Warning: URL Host: {} vs. {}", hostname, session.getPeerHost());

                    return true;
                }
            };
//
//            // clientConfig.getProperties().put(HTTPSProperties.PROPERTY_HTTPS_PROPERTIES, new HTTPSProperties(hv, ctx));
            SchemeRegistry schemeRegistry = new SchemeRegistry();
            SSLSocketFactory ssf = new SSLSocketFactory(ctx);
            Scheme httpsScheme = new Scheme("https", 443, ssf);
            schemeRegistry.register(httpsScheme);
            Scheme httpScheme = new Scheme("http", 80, PlainSocketFactory.getSocketFactory());
            schemeRegistry.register(httpScheme);
            ClientConnectionManager conman = new ThreadSafeClientConnManager(schemeRegistry);
            
//            HttpClient httpClient = new DefaultHttpClient(conman);
//            ApacheHttpClient4Handler handler = new ApacheHttpClient4Handler(httpClient, null, false);
//            client = new NoCertClient(handler, clientConfig);
            client = ClientBuilder.newBuilder().
                sslContext(ctx).
                hostnameVerifier(hv).
                property(ApacheClientProperties.CONNECTION_MANAGER, conman).
                build();
        
        }
        catch (NoSuchAlgorithmException ex)
        {
            if ( log.isErrorEnabled()) log.error("No such algorithm: {}", ex);
            throw new WebApplicationException(ex);
        }
        catch (KeyStoreException ex)
        {
            if ( log.isErrorEnabled()) log.error("Key store error: {}", ex);
            throw new WebApplicationException(ex);
        }
        catch (KeyManagementException ex)
        {
            if ( log.isErrorEnabled()) log.error("Key management error: {}", ex);
            throw new WebApplicationException(ex);
        }
        
        //client.setFollowRedirects(true);
        //if (log.isDebugEnabled()) client.addFilter(new LoggingFilter(System.out));
    }
    
    @Override
    public Client provide()
    {
        return getClient();
    }

    @Override
    public void dispose(Client t)
    {
    }
    
//    @Override
//    public Injectable<NoCertClient> getInjectable(ComponentContext ic, Context a)
//    {
//        return new Injectable<NoCertClient>()
//        {
//            @Override
//            public NoCertClient getValue()
//            {
//                return getClient();
//            }
//        };
//    }
//
//    @Override
//    public NoCertClient getContext(Class<?> type)
//    {
//        return getClient();
//    }
    
    public KeyStore getTrustStore()
    {
        return trustStore;
    }
    
    public Client getClient()
    {
        return client;
    }
    
}