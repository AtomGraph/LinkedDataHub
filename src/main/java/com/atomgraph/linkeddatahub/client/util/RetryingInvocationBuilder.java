/**
 *  Copyright 2025 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.client.util;

import jakarta.ws.rs.ProcessingException;
import jakarta.ws.rs.client.*;
import jakarta.ws.rs.core.*;

import java.util.Locale;
import java.util.concurrent.Callable;

public class RetryingInvocationBuilder implements Invocation.Builder
{

    private final Invocation.Builder delegate;
    private final long defaultDelayMillis;
    private final int maxRetryCount;

    public RetryingInvocationBuilder(Invocation.Builder delegate, long defaultDelayMillis, int maxRetryCount)
    {
        this.delegate = delegate;
        this.defaultDelayMillis = defaultDelayMillis;
        this.maxRetryCount = maxRetryCount;
    }

    private <T> T invokeWithRetry(Callable<T> operation)
    {
        int retryCount = 0;

        while (true)
        {
            try
            {
                T result = operation.call();

                if (result instanceof Response response)
                {
                    if (response.getStatusInfo().equals(Response.Status.TOO_MANY_REQUESTS))
                    {
                        long delay = defaultDelayMillis;
                        String retryAfter = response.getHeaderString(HttpHeaders.RETRY_AFTER);
                        if (retryAfter != null)
                        {
                            try
                            {
                                delay = Long.parseLong(retryAfter) * 1000;
                            }
                            catch (NumberFormatException ignore) {}
                        }

                        response.close();

                        if (++retryCount > maxRetryCount)
                            throw new ProcessingException("Max retries exceeded");

                        try
                        {
                            Thread.sleep(delay);
                        }
                        catch (InterruptedException e)
                        {
                            Thread.currentThread().interrupt();
                            throw new ProcessingException("Interrupted during retry", e);
                        }

                        continue;
                    }
                }

                return result;
            }
            catch (RuntimeException e)
            {
                throw e;
            }
            catch (Exception e)
            {
                throw new ProcessingException("Unexpected checked exception during retry", e);
            }
        }
    }

    @Override public Response get() { return invokeWithRetry(delegate::get); }
    @Override public <T> T get(Class<T> responseType) { return invokeWithRetry(() -> delegate.get(responseType)); }
    @Override public <T> T get(GenericType<T> responseType) { return invokeWithRetry(() -> delegate.get(responseType)); }

    @Override public Response put(Entity<?> entity) { return invokeWithRetry(() -> delegate.put(entity)); }
    @Override public <T> T put(Entity<?> entity, Class<T> responseType) { return invokeWithRetry(() -> delegate.put(entity, responseType)); }
    @Override public <T> T put(Entity<?> entity, GenericType<T> responseType) { return invokeWithRetry(() -> delegate.put(entity, responseType)); }

    @Override public Response post(Entity<?> entity) { return invokeWithRetry(() -> delegate.post(entity)); }
    @Override public <T> T post(Entity<?> entity, Class<T> responseType) { return invokeWithRetry(() -> delegate.post(entity, responseType)); }
    @Override public <T> T post(Entity<?> entity, GenericType<T> responseType) { return invokeWithRetry(() -> delegate.post(entity, responseType)); }

    @Override public Response delete() { return invokeWithRetry(delegate::delete); }
    @Override public <T> T delete(Class<T> responseType) { return invokeWithRetry(() -> delegate.delete(responseType)); }
    @Override public <T> T delete(GenericType<T> responseType) { return invokeWithRetry(() -> delegate.delete(responseType)); }

    @Override public Response head() { return invokeWithRetry(delegate::head); }
    @Override public Response options() { return invokeWithRetry(delegate::options); }
    @Override public <T> T options(Class<T> responseType) { return invokeWithRetry(() -> delegate.options(responseType)); }
    @Override public <T> T options(GenericType<T> responseType) { return invokeWithRetry(() -> delegate.options(responseType)); }

    @Override public Response trace() { return invokeWithRetry(delegate::trace); }
    @Override public <T> T trace(Class<T> responseType) { return invokeWithRetry(() -> delegate.trace(responseType)); }
    @Override public <T> T trace(GenericType<T> responseType) { return invokeWithRetry(() -> delegate.trace(responseType)); }

    @Override public Response method(String name) { return invokeWithRetry(() -> delegate.method(name)); }
    @Override public <T> T method(String name, Class<T> responseType) { return invokeWithRetry(() -> delegate.method(name, responseType)); }
    @Override public <T> T method(String name, GenericType<T> responseType) { return invokeWithRetry(() -> delegate.method(name, responseType)); }
    @Override public Response method(String name, Entity<?> entity) { return invokeWithRetry(() -> delegate.method(name, entity)); }
    @Override public <T> T method(String name, Entity<?> entity, Class<T> responseType) { return invokeWithRetry(() -> delegate.method(name, entity, responseType)); }
    @Override public <T> T method(String name, Entity<?> entity, GenericType<T> responseType) { return invokeWithRetry(() -> delegate.method(name, entity, responseType)); }

    // Delegate non-invocation methods directly
    @Override public Invocation build(String method) { return delegate.build(method); }
    @Override public Invocation build(String method, Entity<?> entity) { return delegate.build(method, entity); }
    @Override public Invocation buildGet() { return delegate.buildGet(); }
    @Override public Invocation buildDelete() { return delegate.buildDelete(); }
    @Override public Invocation buildPost(Entity<?> entity) { return delegate.buildPost(entity); }
    @Override public Invocation buildPut(Entity<?> entity) { return delegate.buildPut(entity); }

    @Override public AsyncInvoker async() { return delegate.async(); }
    @Override public CompletionStageRxInvoker rx() { return delegate.rx(); }
    @Override public <T extends RxInvoker> T rx(Class<T> clazz) { return delegate.rx(clazz); }

    @Override public Invocation.Builder accept(String... mediaTypes) { delegate.accept(mediaTypes); return this; }
    @Override public Invocation.Builder accept(MediaType... mediaTypes) { delegate.accept(mediaTypes); return this; }
    @Override public Invocation.Builder acceptLanguage(Locale... locales) { delegate.acceptLanguage(locales); return this; }
    @Override public Invocation.Builder acceptLanguage(String... locales) { delegate.acceptLanguage(locales); return this; }
    @Override public Invocation.Builder acceptEncoding(String... encodings) { delegate.acceptEncoding(encodings); return this; }
    @Override public Invocation.Builder cookie(Cookie cookie) { delegate.cookie(cookie); return this; }
    @Override public Invocation.Builder cookie(String name, String value) { delegate.cookie(name, value); return this; }
    @Override public Invocation.Builder cacheControl(CacheControl cacheControl) { delegate.cacheControl(cacheControl); return this; }
    @Override public Invocation.Builder header(String name, Object value) { delegate.header(name, value); return this; }
    @Override public Invocation.Builder headers(MultivaluedMap<String, Object> headers) { delegate.headers(headers); return this; }
    @Override public Invocation.Builder property(String name, Object value) { delegate.property(name, value); return this; }
    
}
