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
package com.atomgraph.linkeddatahub.listener;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.function.Function;
import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.Transport;
import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Email listener.
 * Used to send email messages asynchronously.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class EMailListener implements ServletContextListener
{

    private static final int MAX_THREADS = 10; // TO-DO: move to config?
    private static final ExecutorService THREAD_POOL = Executors.newFixedThreadPool(MAX_THREADS);
    
    private static final Logger log = LoggerFactory.getLogger(EMailListener.class);

    @Override
    public void contextInitialized(ServletContextEvent sce)
    {
        if (log.isDebugEnabled()) log.debug("{} initialized with a pool of {} threads", getClass().getName(), MAX_THREADS);
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce)
    {
        if (log.isDebugEnabled()) log.debug("Shutting down {} thread pool", getClass().getName());
        THREAD_POOL.shutdown();
    }
    
    public static void submit(Message message)
    {
        CompletableFuture.runAsync(new MessageSender(message)).
            exceptionally(failure(message));
    }
    
    public static Function<Throwable, Void> failure(final Message message)
    {
        return new Function<Throwable, Void>()
        {

            @Override
            public Void apply(Throwable t)
            {
                try
                {
                    if (log.isErrorEnabled()) log.error("Could not send Message with subject: {} to addresses: {}", message.getSubject(), message.getAllRecipients());
                    throw new RuntimeException(t);
                }
                catch (MessagingException ex)
                {
                    if (log.isErrorEnabled()) log.error("Could not Message properties: {}", message);
                    throw new RuntimeException(ex);
                }
            }
        
        };

    }
    
    public static final class MessageSender implements Runnable
    {
        
        private final Message message;
        
        public MessageSender(Message message)
        {
            this.message = message;
        }
        
        @Override
        public void run()
        {
            try
            {
                Transport.send(getMessage());
            }
            catch (MessagingException ex)
            {
                throw new RuntimeException(ex);
            }
        }
        
        public Message getMessage()
        {
            return message;
        }
        
    }
    
}