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
package com.atomgraph.linkeddatahub.server.io;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Collecting error handler.
 * Collects syntax errors reported by the RDF parser.
 * 
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 * @see com.atomgraph.linkeddatahub.server.io.SkolemizingModelProvider
 */
public class CollectingErrorHandler implements org.apache.jena.riot.system.ErrorHandler
{
    public final int WARNING = 0, ERROR = 1, FATAL = 2;
    private final List<Violation> violations = new ArrayList<>();
    
    @Override
    public void warning(String message, long line, long col)
    {
        violations.add(new Violation(WARNING, message, line, col));
    }

    @Override
    public void error(String message, long line, long col)
    {
        violations.add(new Violation(ERROR, message, line, col));
    }

    @Override
    public void fatal(String message, long line, long col)
    {
        violations.add(new Violation(FATAL, message, line, col));
    }
    
    public List<Violation> getViolations()
    {
        return Collections.unmodifiableList(violations);
    }

    public class Violation
    {
        private final int level;
        private final String message;
        private final long line, col;
        
        public Violation(int level, String message, long line, long col)
        {
            this.level = level;
            this.message = message;
            this.line = line;
            this.col = col;
        }

        public int getLevel()
        {
            return level;
        }
        
        public String getMessage()
        {
            return message;
        }
        
        public long getLine()
        {
            return line;
        }
        
        public long getCol()
        {
            return col;
        }
        
        @Override
        public String toString()
        {
            return org.apache.jena.riot.SysRIOT.fmtMessage(getMessage(), getLine(), getCol());
        }
        
    }
    
}
