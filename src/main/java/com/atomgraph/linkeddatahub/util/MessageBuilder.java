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

import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
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

    private MessageBuilder(Session session)
    {
        this.message = new MimeMessage(session);
    }

    private MessageBuilder(Properties properties)
    {
        this(Session.getDefaultInstance(properties));
    }
    
    private MessageBuilder(Properties properties, Authenticator auth)
    {
        this(Session.getDefaultInstance(properties, auth));
    }

    public static MessageBuilder fromSession(Session session)
    {
        return new MessageBuilder(session);
    }
    
    public static MessageBuilder fromProperties(Properties properties)
    {
        return new MessageBuilder(properties);
    }
    
    public static MessageBuilder fromPropertiesAndAuth(Properties properties, Authenticator auth)
    {
        return new MessageBuilder(properties, auth);
    }
    
    public MessageBuilder from(Address address) throws MessagingException
    {
        getMessage().setFrom(address);
        return this;
    }
    
    public MessageBuilder from(String from, String personal) throws MessagingException, UnsupportedEncodingException
    {
        return from(new InternetAddress(from, personal));
    }
    
    public MessageBuilder recipient(Message.RecipientType type, Address address) throws MessagingException
    {        
        getMessage().addRecipient(type, address);
        return this;
    }
    
    public MessageBuilder recipient(Message.RecipientType type, String to) throws MessagingException, UnsupportedEncodingException
    {        
        return recipient(type, new InternetAddress(to));
    }
    
    public MessageBuilder recipient(Message.RecipientType type, String to, String personal) throws MessagingException, UnsupportedEncodingException
    {        
        return recipient(type, new InternetAddress(to, personal));
    }
    
    public MessageBuilder to(Address address) throws MessagingException, UnsupportedEncodingException
    {
        return recipient(Message.RecipientType.TO, address);
    }
    
    public MessageBuilder to(String to) throws MessagingException, UnsupportedEncodingException
    {
        return recipient(Message.RecipientType.TO, to);
    }
    
    public MessageBuilder to(String to, String personal) throws MessagingException, UnsupportedEncodingException
    {
        return recipient(Message.RecipientType.TO, to, personal);
    }
    
    public MessageBuilder subject(String subject) throws MessagingException
    {        
        getMessage().setSubject(subject);
        return this;
    }

    public MessageBuilder text(String text) throws MessagingException
    {        
        getMessage().setText(text);
        return this;
    }
    
    public MessageBuilder bodyPart(BodyPart bodyPart) throws MessagingException
    {
        getMultipartBuilder().part(bodyPart);
        return this;
    }
    
    public MessageBuilder textBodyPart(String body) throws MessagingException
    {
        getMultipartBuilder().textPart(body);
        return this;
    }
    
    public MessageBuilder dataBodyPart(DataSource source, String fileName) throws MessagingException
    {
        getMultipartBuilder().dataPart(source, fileName);
        return this;
    }
    
    public MessageBuilder byteArrayBodyPart(byte[] data, String type, String fileName) throws MessagingException
    {
        getMultipartBuilder().byteArrayPart(data, type, fileName);
        return this;
    }
    
    public MessageBuilder inputStreamBodyPart(InputStream data, String type, String fileName) throws MessagingException, IOException
    {
        getMultipartBuilder().inputStreamPart(data, type, fileName);
        return this;
    }
    
    public MessageBuilder debug()
    {
        getMessage().getSession().setDebug(true);
        return this;
    }

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
    
    public class MultipartBuilder
    {
        private final Multipart multipart = new MimeMultipart();
        
        private MultipartBuilder()
        {
        }
        
        public MultipartBuilder part(BodyPart bodyPart) throws MessagingException
        {
            getMultipart().addBodyPart(bodyPart);
            return this;
        }
        
        public MultipartBuilder textPart(String body) throws MessagingException
        {
            BodyPart textPart = new MimeBodyPart();
            textPart.setText(body);
            return part(textPart);
        }

        public MultipartBuilder dataPart(DataSource source, String fileName) throws MessagingException
        {
            BodyPart dataPart = new MimeBodyPart();
            dataPart.setDataHandler(new DataHandler(source));
            dataPart.setFileName(fileName);
            return part(dataPart);
        }
    
        public MultipartBuilder byteArrayPart(byte[] data, String type, String fileName) throws MessagingException
        {
            return dataPart(new ByteArrayDataSource(data, type), fileName);
        }
        
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
