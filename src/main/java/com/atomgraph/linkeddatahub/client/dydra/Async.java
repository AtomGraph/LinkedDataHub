/**
 *  Copyright 2020 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.client.dydra;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public interface Async
{
    
    public static final String HEADER_NAME = "Accept-Asynchronous";
    
    public enum Mode {
        
        NOTIFY("notify"),
        EXECUTE("execute");
    
        private final String headerValue;
        
        Mode(String headerValue)
        {
            this.headerValue = headerValue;
        }

        public String getHeaderName()
        {
            return HEADER_NAME;
        }

        public String getHeaderValue()
        {
            return headerValue;
        }
        
    };
    
}
