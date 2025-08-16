/**
 * Fetch document content with retry logic for HTTP 429 responses
 * @param {string} url - The URL to fetch
 * @param {Object} headers - HTTP headers to include in the request
 * @param {number} maxRetries - Maximum number of retry attempts (default: 3)
 * @param {number} retryCount - Current retry count (default: 0)
 * @returns {Promise<string>} Promise that resolves to document content as text
 */
async function getResourceWithRetry(url, headers = {}, maxRetries = 3, retryCount = 0) {
    try {
        const response = await fetch(url, {
            method: 'GET',
            headers: headers
        });
        
        if (response.status === 429) {
            if (retryCount >= maxRetries) {
                throw new Error(`Max retries (${maxRetries}) exceeded for ${url}`);
            }
            
            // Parse Retry-After header
            const retryAfter = response.headers.get('Retry-After');
            let delay = Math.pow(2, retryCount) * 1000; // Exponential backoff default
            
            if (retryAfter) {
                if (/^\d+$/.test(retryAfter)) {
                    delay = parseInt(retryAfter) * 1000;
                } else {
                    const retryTime = new Date(retryAfter);
                    delay = Math.max(0, retryTime.getTime() - Date.now());
                }
            }
            
            console.log(`HTTP 429 for ${url}, retrying in ${delay}ms (attempt ${retryCount + 1}/${maxRetries})`);
            
            await new Promise(resolve => setTimeout(resolve, delay));
            return getResourceWithRetry(url, headers, maxRetries, retryCount + 1);
        }
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }
        
        // Return document content as text
        return response.text();
        
    } catch (error) {
        if (retryCount < maxRetries && (error.name === 'TypeError' || error.message.includes('fetch'))) {
            // Network error, retry with exponential backoff
            const delay = Math.pow(2, retryCount) * 1000;
            console.log(`Network error for ${url}, retrying in ${delay}ms (attempt ${retryCount + 1}/${maxRetries})`);
            await new Promise(resolve => setTimeout(resolve, delay));
            return getResourceWithRetry(url, headers, maxRetries, retryCount + 1);
        }
        throw error;
    }
}