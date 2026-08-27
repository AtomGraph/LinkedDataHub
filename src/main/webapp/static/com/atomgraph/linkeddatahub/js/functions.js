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

// update RDF/POST inputs for the resource when the subject type is flipped between URI ("su") and blank node ("sb")
var onSubjectTypeChange = function(event)
{
    var newType = this.value;
    var controlGroup = this.closest(".control-group");
    var oldSubjectType = controlGroup.querySelector("input.subject-type.old");
    var oldType = oldSubjectType.value; // old value in a hidden input

    var subject = controlGroup.querySelector("input.subject");
    var value = subject.value;
    var newTypeOldSubject = subject.closest(".controls").querySelector("input.old." + newType);
    var newTypeOldValue = newTypeOldSubject.value; // old value (of the new type) in a hidden input

    var form = this.closest("form");
    // flip subject input names and restore old values
    form.querySelectorAll("input").forEach(function(input)
    {
        if (input.name === oldType && input.value === value)
        {
            input.name = newType;
            input.value = newTypeOldValue;
        }
    });

    var subjectObjectMap = { "sb": "ob", "su": "ou" };
    var newObjectType = subjectObjectMap[newType];
    var oldObjectType = subjectObjectMap[oldType];

    // flip object input names and restore old values
    form.querySelectorAll("input").forEach(function(input)
    {
        if (input.name === oldObjectType && input.value === value)
        {
            input.name = newObjectType;
            input.value = newTypeOldValue;
        }
    });

    oldSubjectType.value = newType; // store current subject type which will be the old value next time
    newTypeOldSubject.value = newTypeOldValue; // store current subject value which will be the old value next time
};

// update RDF/POST inputs for the resource when subject URI/bnode value is changed
var onSubjectValueChange = function(event)
{
    var controlGroup = this.closest(".control-group");
    var subjectType = controlGroup.querySelector("select.subject-type").value; // "sb" (bnode) or "su" (URI)
    var subjectObjectMap = { "sb": "ob", "su": "ou" };
    var objectType = subjectObjectMap[subjectType];

    var newValue = this.value; // new value after change
    var oldSubject = controlGroup.querySelector("input.old." + subjectType);
    var oldValue = oldSubject.value; // old value in a hidden input

    var form = this.closest("form");
    // update subject input values
    form.querySelectorAll("input").forEach(function(input)
    {
        if (input.name === subjectType && input.value === oldValue) input.value = newValue;
    });

    // update object input values
    form.querySelectorAll("input").forEach(function(input)
    {
        if (input.name === objectType && input.value === oldValue) input.value = newValue;
    });

    oldSubject.value = newValue; // store value in the hidden input
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
