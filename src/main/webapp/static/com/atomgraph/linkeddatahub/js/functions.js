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

document.addEventListener("DOMContentLoaded", function()
{
    // turn off browser autocomplete for inputs with our own autocomplete
    document.querySelectorAll("input.typeahead").forEach(function(input)
    {
        input.setAttribute("autocomplete", "off");
    });

    // close open dropdowns on outside click, and after picking a menu item.
    // Deferred so it settles after the IXSL btn-group toggle that handles the same click.
    document.body.addEventListener("click", function(event)
    {
        if (!document.querySelector(".btn-group.open")) return; // nothing open - skip the deferred scan

        var pickedItem = event.target.closest(".ldh-add-menu, .ldh-of-menu, .modes-pop, .dropdown-menu");
        setTimeout(function()
        {
            document.querySelectorAll(".btn-group.open").forEach(function(group)
            {
                if (!group.contains(event.target) || pickedItem) group.classList.remove("open", "is-open");
            });
        }, 0);
    });
});
