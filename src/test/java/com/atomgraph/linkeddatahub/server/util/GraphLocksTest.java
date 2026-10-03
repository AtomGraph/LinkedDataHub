/**
 *  Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>
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

import java.net.URI;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.Lock;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;

/**
 * The properties a document write relies on its lock for.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class GraphLocksTest
{

    private static final URI GRAPH = URI.create("https://localhost:4443/inbox/");

    private final GraphLocks locks = new GraphLocks();

    @Test
    public void sameGraphGivesTheSameLock() // two writers to one document have to contend for one lock
    {
        assertSame(locks.get(GRAPH), locks.get(URI.create(GRAPH.toString())));
    }

    @Test
    public void nullGraphIsRefused()
    {
        assertThrows(IllegalArgumentException.class, () -> locks.get(null));
    }

    @Test
    public void lockIsReentrant() // a PATCH that empties the graph completes as a DELETE, which takes the lock again
    {
        Lock lock = locks.get(GRAPH);
        lock.lock();
        try
        {
            assertTrue(lock.tryLock());
            lock.unlock();
        }
        finally
        {
            lock.unlock();
        }
    }

    @Test
    public void heldLockKeepsASecondWriterOut() throws InterruptedException
    {
        Lock lock = locks.get(GRAPH);
        CountDownLatch held = new CountDownLatch(1), release = new CountDownLatch(1);
        Thread first = new Thread(() ->
        {
            lock.lock();
            try
            {
                held.countDown();
                release.await();
            }
            catch (InterruptedException ex)
            {
                Thread.currentThread().interrupt();
            }
            finally
            {
                lock.unlock();
            }
        });
        first.start();
        assertTrue(held.await(5, TimeUnit.SECONDS));

        Lock same = locks.get(GRAPH);
        assertFalse(same.tryLock(100, TimeUnit.MILLISECONDS)); // the second writer waits while the first is between its read and its write

        release.countDown();
        first.join(5000);
        assertTrue(same.tryLock(5, TimeUnit.SECONDS)); // and gets in once the first has written
        same.unlock();
    }

}
