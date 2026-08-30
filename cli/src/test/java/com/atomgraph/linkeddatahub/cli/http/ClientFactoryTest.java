/*
 * Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.atomgraph.linkeddatahub.cli.http;

import java.nio.file.Path;
import java.nio.file.Paths;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

/**
 * Tests for {@link ClientFactory}.
 */
public class ClientFactoryTest
{

    static Path keyStorePath() throws Exception
    {
        return Paths.get(ClientFactoryTest.class.getResource("/test-keystore.p12").toURI());
    }

    @Test
    public void createsClientFromPKCS12Keystore() throws Exception
    {
        assertNotNull(ClientFactory.createClient(keyStorePath(), "changeit"));
    }

    @Test
    public void failsCleanlyOnWrongPassword() throws Exception
    {
        Path keyStore = keyStorePath();

        assertThrows(IllegalArgumentException.class, () -> ClientFactory.createClient(keyStore, "wrong"));
    }

    @Test
    public void failsCleanlyOnMissingFile()
    {
        assertThrows(IllegalArgumentException.class, () -> ClientFactory.createClient(Path.of("/nonexistent.p12"), "changeit"));
    }

}
