// Copyright 2019 Martynas Jusevičius <martynas@atomgraph.com>
// SPDX-FileCopyrightText: 2017-2022 2017 Martynas Jusevicius, <martynas@atomgraph.com> et al.
//
// SPDX-License-Identifier: Apache-2.0

/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.atomgraph.linkeddatahub.server.util.stream;

import java.io.IOException;

/**
 * Interface of an object, which may be closed.
 */
public interface Closeable {

    /**
     * Closes the object.
     *
     * @throws IOException An I/O error occurred.
     */
    void close() throws IOException;

    /**
     * Returns, whether the object is already closed.
     *
     * @return True, if the object is closed, otherwise false.
     * @throws IOException An I/O error occurred.
     */
    boolean isClosed() throws IOException;

}
