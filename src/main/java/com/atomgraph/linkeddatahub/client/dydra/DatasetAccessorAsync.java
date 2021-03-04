package com.atomgraph.linkeddatahub.client.dydra;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public interface DatasetAccessorAsync
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
