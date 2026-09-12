/* global SaxonJS */

var fetchDispatchXML = function(url, method, headers, body, target, docUri, resources, block, eventName)
{
    let request = new Request(url, { "method": method, "headers": headers, "body": body });

    fetch(request).
    then(function(response)
    {
        const contentLength = response.headers.get("Content-Length");
        if (contentLength && parseInt(contentLength) > 0)
        {
            response.text().
            then(function(xmlString)
            {
                let xml = new DOMParser().parseFromString(xmlString, "text/xml");
                let event = new CustomEvent(eventName, { "detail": { "action": url, "response": response, "xml": xml, "target": target, "docUri": docUri, "resources": resources, "block": block } } );
                // no need to add event listeners here, that is done by IXSL
                document.dispatchEvent(event);
            });
        }
        else
        {
            let event = new CustomEvent(eventName, { "detail": { "action": url, "response": response, "target": target, "docUri": docUri, "resources": resources, "block": block } } );
            // no need to add event listeners here, that is done by IXSL
            document.dispatchEvent(event);
        }
    }).
    catch(function(response)
    {
        let event = new CustomEvent(eventName, { "detail": { "response": response, "target": target, "docUri": docUri, "resources": resources, "block": block } } );
        // no need to add event listeners here, that is done by IXSL
        document.dispatchEvent(event);
    });
};

var ixslTemplateListener = function(eventName, map, olEvent)
{
    let event = new CustomEvent(eventName, { "detail": { "ol-event": olEvent, "map": map } } );
    // no need to add event listeners here, that is done by IXSL
    document.dispatchEvent(event);
};
