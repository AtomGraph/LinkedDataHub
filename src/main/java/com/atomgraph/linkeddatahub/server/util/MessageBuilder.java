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

import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.util.Arrays;
import java.util.Properties;
import javax.activation.DataHandler;
import javax.activation.DataSource;
import javax.mail.Address;
import javax.mail.Authenticator;
import javax.mail.BodyPart;
import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.Multipart;
import javax.mail.Session;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeBodyPart;
import javax.mail.internet.MimeMessage;
import javax.mail.internet.MimeMultipart;
import javax.mail.util.ByteArrayDataSource;

/**
 * Email message builder.
 * Provides a builder pattern; supports attachments.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class MessageBuilder
{
    
    private final MimeMessage message;
    private final MultipartBuilder multipartBuilder = new MultipartBuilder();

    /**
     * Constructs builder from SMTP session.
     * 
     * @param session SMTP session
     */
    private MessageBuilder(Session session)
    {
        this.message = new MimeMessage(session);
    }

    /**
     * Constructs builder from email properties.
     * 
     * @param properties email properties
     */
    private MessageBuilder(Properties properties)
    {
        this(Session.getDefaultInstance(properties));
    }

    /**
     * Constructs builder from email properties and authenticator.
     * 
     * @param properties email properties
     * @param auth authenticator
     */
    private MessageBuilder(Properties properties, Authenticator auth)
    {
        this(Session.getDefaultInstance(properties, auth));
    }

    /**
     * Creates builder from SMTP session.
     * 
     * @param session SMTP session
     * @return message builder
     */
    public static MessageBuilder fromSession(Session session)
    {
        return new MessageBuilder(session);
    }
    
    /**
     * Creates builder from email properties.
     * 
     * @param properties email properties
     * @return message builder
     */
    public static MessageBuilder fromProperties(Properties properties)
    {
        return new MessageBuilder(properties);
    }
    
    /**
     * Creates builder from email properties and authenticator.
     * 
     * @param properties email properties
     * @param auth authenticator
     * @return message builder
     */
    public static MessageBuilder fromPropertiesAndAuth(Properties properties, Authenticator auth)
    {
        return new MessageBuilder(properties, auth);
    }
    
    /**
     * Sets sender address.
     * 
     * @param address from address
     * @return message builder
     * @throws MessagingException failed to set
     */
    public MessageBuilder from(Address address) throws MessagingException
    {
        getMessage().setFrom(address);
        return this;
    }
    
    /**
     * Sets sender address with name.
     * 
     * @param from from address
     * @param personal personal name
     * @return message builder
     * @throws MessagingException failed to set
     * @throws UnsupportedEncodingException encoding error
     */
    public MessageBuilder from(String from, String personal) throws MessagingException, UnsupportedEncodingException
    {
        return from(new InternetAddress(from, personal));
    }
    
    /**
     * Sets recipient address.
     * 
     * @param type recipient type
     * @param address recipient address
     * @return message builder
     * @throws MessagingException failed to set
     */
    public MessageBuilder recipient(Message.RecipientType type, Address address) throws MessagingException
    {
        getMessage().addRecipient(type, address);
        return this;
    }
    
    /**
     * Sets recipient address.
     * 
     * @param type recipient type
     * @param to recipient address
     * @return message builder
     * @throws MessagingException failed to send
     * @throws UnsupportedEncodingException encoding error
     */
    public MessageBuilder recipient(Message.RecipientType type, String to) throws MessagingException, UnsupportedEncodingException
    {        
        return recipient(type, new InternetAddress(to));
    }
    
    /**
     * Sets recipient address with name.
     * 
     * @param type recipient type
     * @param to recipient address
     * @param personal personal name
     * @return message builder
     * @throws MessagingException failed to set
     * @throws UnsupportedEncodingException encoding error
     */
    public MessageBuilder recipient(Message.RecipientType type, String to, String personal) throws MessagingException, UnsupportedEncodingException
    {
        return recipient(type, new InternetAddress(to, personal));
    }
    
    /**
     * Sets "To" address.
     * 
     * @param address "To" address
     * @return message builder
     * @throws MessagingException failed to set
     * @throws UnsupportedEncodingException encoding error
     */
    public MessageBuilder to(Address address) throws MessagingException, UnsupportedEncodingException
    {
        return recipient(Message.RecipientType.TO, address);
    }
    
    /**
     * Sets "To" address.
     * 
     * @param to "To" address
     * @return message builder
     * @throws MessagingException failed to set
     * @throws UnsupportedEncodingException encoding error
     */
    public MessageBuilder to(String to) throws MessagingException, UnsupportedEncodingException
    {
        return recipient(Message.RecipientType.TO, to);
    }
    
    /**
     * Sets "To" address with name.
     * 
     * @param to "To" address
     * @param personal personal name
     * @return message builder
     * @throws MessagingException failed to set
     * @throws UnsupportedEncodingException encoding error
     */
    public MessageBuilder to(String to, String personal) throws MessagingException, UnsupportedEncodingException
    {
        return recipient(Message.RecipientType.TO, to, personal);
    }
    
    /**
     * Sets "Reply to" addresses.
     * 
     * @param addresses "Reply to" addresses
     * @return message builder
     * @throws MessagingException failed to set
     * @throws UnsupportedEncodingException encoding error
     */
    public MessageBuilder replyTo(Address[] addresses) throws MessagingException, UnsupportedEncodingException
    {
        getMessage().setReplyTo(addresses);
        return this;
    }
    
    /**
     * Appends "Reply to" address.
     * 
     * @param address "Reply to" address
     * @return message builder
     * @throws MessagingException failed to set
     * @throws UnsupportedEncodingException encoding error
     */
    public MessageBuilder replyTo(Address address) throws MessagingException, UnsupportedEncodingException
    {
        if (getMessage().getReplyTo() == null)
            // create an array with one ReplyTo and set it
            return replyTo(new Address[] { address });
        else
        {
            // append ReplyTo
            Address[] addresses = Arrays.copyOf(getMessage().getReplyTo(), getMessage().getReplyTo().length + 1);
            addresses[addresses.length - 1] = address;
            return replyTo(addresses);
        }
    }
    
    /**
     * Sets "Reply to" address.
     * 
     * @param replyTo "Reply to" address
     * @return message builder
     * @throws MessagingException failed to set
     * @throws UnsupportedEncodingException encoding error
     */
    public MessageBuilder replyTo(String replyTo) throws MessagingException, UnsupportedEncodingException
    {
        return replyTo(new InternetAddress(replyTo));
    }
    
    /**
     * Sets "Reply to" address with name.
     * 
     * @param replyTo "Reply to" address
     * @param personal personal name
     * @return message builder
     * @throws MessagingException failed to set
     * @throws UnsupportedEncodingException encoding error
     */
    public MessageBuilder replyTo(String replyTo, String personal) throws MessagingException, UnsupportedEncodingException
    {
        return replyTo(new InternetAddress(replyTo, personal));
    }
    
    /**
     * Sets email subject.
     * 
     * @param subject subject value
     * @return message builder
     * @throws MessagingException failed to set
     */
    public MessageBuilder subject(String subject) throws MessagingException
    {
        getMessage().setSubject(subject);
        return this;
    }

    /**
     * Sets email text.
     * 
     * @param text text value
     * @return message builder
     * @throws MessagingException failed to set
     */
    public MessageBuilder text(String text) throws MessagingException
    {        
        getMessage().setText(text);
        return this;
    }
    
    /**
     * Sets body part (attachment).
     * 
     * @param bodyPart body part
     * @return message builder
     * @throws MessagingException failed to set
     */
    public MessageBuilder bodyPart(BodyPart bodyPart) throws MessagingException
    {
        getMultipartBuilder().part(bodyPart);
        return this;
    }
    
    /**
     * Sets text body part (attachment).
     * 
     * @param body text
     * @return message builder
     * @throws MessagingException failed to set
     */
    public MessageBuilder textBodyPart(String body) throws MessagingException
    {
        getMultipartBuilder().textPart(body);
        return this;
    }
    
    /**
     * Sets data body part (attachment).
     * 
     * @param source data
     * @param fileName filename
     * @return message builder
     * @throws MessagingException failed to set
     */
    public MessageBuilder dataBodyPart(DataSource source, String fileName) throws MessagingException
    {
        getMultipartBuilder().dataPart(source, fileName);
        return this;
    }
    
    /**
     * Sets byte array body part (attachment).
     * 
     * @param data byte array
     * @param type data source type
     * @param fileName filename
     * @return message builder
     * @throws MessagingException failed to set
     */
    public MessageBuilder byteArrayBodyPart(byte[] data, String type, String fileName) throws MessagingException
    {
        getMultipartBuilder().byteArrayPart(data, type, fileName);
        return this;
    }
    
    /**
     * Sets input stream body part (attachment).
     * 
     * @param data input stream
     * @param type data source type
     * @param fileName filename
     * @return message builder
     * @throws MessagingException failed to set
     * @throws IOException stream I/O error
     */
    public MessageBuilder inputStreamBodyPart(InputStream data, String type, String fileName) throws MessagingException, IOException
    {
        getMultipartBuilder().inputStreamPart(data, type, fileName);
        return this;
    }
    
    /**
     * Enable debug output.
     * 
     * @return message builder
     */
    public MessageBuilder debug()
    {
        getMessage().getSession().setDebug(true);
        return this;
    }

    /**
     * Builds message from the current builder state.
     * 
     * @return message builder
     * @throws MessagingException failed to set
     */
    public Message build() throws MessagingException
    {
        getMessage().setContent(getMultipartBuilder().getMultipart());
        return getMessage();
    }
   
    private MimeMessage getMessage()
    {
        return message;
    }
    
    private MultipartBuilder getMultipartBuilder()
    {
        return multipartBuilder;
    }
    
    /**
     * Multipart builder.
     */
    public class MultipartBuilder
    {
        private final Multipart multipart = new MimeMultipart();
        
        private MultipartBuilder()
        {
        }
        
        /**
         * Sets body part.
         * 
         * @param bodyPart body part
         * @return multipart builder
         * @throws MessagingException failed to set
         */
        public MultipartBuilder part(BodyPart bodyPart) throws MessagingException
        {
            getMultipart().addBodyPart(bodyPart);
            return this;
        }
        
        /**
         * Sets text part.
         * 
         * @param body text
         * @return multipart builder
         * @throws MessagingException failed to set
         */
        public MultipartBuilder textPart(String body) throws MessagingException
        {
            BodyPart textPart = new MimeBodyPart();
            textPart.setText(body);
            return part(textPart);
        }

        /**
         * Sets data part.
         * 
         * @param source data source
         * @param fileName filename
         * @return multipart builder
         * @throws MessagingException failed to set
         */
        public MultipartBuilder dataPart(DataSource source, String fileName) throws MessagingException
        {
            BodyPart dataPart = new MimeBodyPart();
            dataPart.setDataHandler(new DataHandler(source));
            dataPart.setFileName(fileName);
            return part(dataPart);
        }
    
        /**
         * Sets byte array part.
         * 
         * @param data byte array
         * @param type data source type
         * @param fileName filename
         * @return multipart builder
         * @throws MessagingException failed to set
         */
        public MultipartBuilder byteArrayPart(byte[] data, String type, String fileName) throws MessagingException
        {
            return dataPart(new ByteArrayDataSource(data, type), fileName);
        }
        
        /**
         * Sets input stream part.
         * 
         * @param data input stream
         * @param type data source type
         * @param fileName filename
         * @return multipart builder
         * @throws MessagingException failed to set
         * @throws IOException stream I/O error
         */
        public MultipartBuilder inputStreamPart(InputStream data, String type, String fileName) throws MessagingException, IOException
        {
            return dataPart(new ByteArrayDataSource(data, type), fileName);
        }
        
        private Multipart getMultipart()
        {
            return multipart;
        }
        
    }
    
}
