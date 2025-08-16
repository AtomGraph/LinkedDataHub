/* global contextUri, baseUri, requestUri, absolutePath, lang, xslt2proc, UriBuilder, SaxonJS, ontologyUri, contextUri */

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
        const contentLength = response.headers.get("Content-Length");
        if (contentLength && parseInt(contentLength) > 0)
        {
            response.text().
            then(function(xmlString)
            {
                let xml = new DOMParser().parseFromString(xmlString, "text/xml");
                let event = new CustomEvent(eventName, { "detail": { "response": response, "xml": xml, "target": target, "docUri": docUri, "resources": resources, "block": block } } );
                // no need to add event listeners here, that is done by IXSL
                document.dispatchEvent(event);
            });
        }
        else
        {
            let event = new CustomEvent(eventName, { "detail": { "response": response, "target": target, "docUri": docUri, "resources": resources, "block": block } } );
            // no need to add event listeners here, that is done by IXSL
            document.dispatchEvent(event);
        }
    });
};

var onSubjectTypeChange = function(event)
{
    var newType = $(this).val();
    var oldSubjectType = $(this).closest(".control-group").find("input.subject-type.old");
    var oldType = oldSubjectType.val(); // old value in a hidden input

    var subject = $(this).closest(".control-group").find("input.subject");
    var value = subject.val();
    var newTypeOldSubject = subject.closest(".controls").find("input.old." + newType);
    var newTypeOldValue = newTypeOldSubject.val(); // old value (of the new type) in a hidden input
        
    // flip object input names and restore old values
    $(this).closest("form").find("input"). // filter by properties, not attributes
        filter(function()
        {
            return $(this).prop("name") === oldType && $(this).val() === value;
        }).
        each(function()
        {
            $(this).prop("name", newType);
            $(this).val(newTypeOldValue);
        });
    
    var subjectObjectMap = { "sb": "ob", "su": "ou" };
    var newObjectType = subjectObjectMap[newType];
    var oldObjectType = subjectObjectMap[oldType];

    // flip object input names and restore old values
    $(this).closest("form").find("input"). // filter by properties, not attributes
        filter(function()
        {
            return $(this).prop("name") === oldObjectType && $(this).val() === value;
        }).
        each(function()
        {
            $(this).prop("name", newObjectType);
            $(this).val(newTypeOldValue);
        });
    
    oldSubjectType.val(newType); // store current subject type which will be the old value next time
    newTypeOldSubject.val(newTypeOldValue); // store current subject value which will be the old value next time
};

// update RDF/POST inputs for the resource when subject URI/bnode value is changed
var onSubjectValueChange = function(event)
{
    var subjectType = $(this).closest(".control-group").find("select.subject-type").val(); // "sb" (bnode) or "su" (URI)
    var subjectObjectMap = { "sb": "ob", "su": "ou" };
    var objectType = subjectObjectMap[subjectType];

    var newValue = $(this).val(); // new value after change
    var oldSubject = $(this).closest(".control-group").find("input.old." + subjectType);
    var oldValue = oldSubject.val(); // old value in a hidden input

    // update subject input values
    $(this).closest("form").find("input"). // filter by properties, not attributes
        filter(function()
        {
            return $(this).prop("name") === subjectType && $(this).val() === oldValue;
        }).
        each(function()
        {
            $(this).val(newValue);
        });

    // update object input values
    $(this).closest("form").find("input"). // filter by properties, not attributes
        filter(function()
        {
            return $(this).prop("name") === objectType && $(this).val() === oldValue;
        }).
        each(function()
        {
            $(this).val(newValue);
        });
    
    oldSubject.val(newValue); // store value in the hidden input
};

var ixslTemplateListener = function(eventName, map, olEvent)
{
    let event = new CustomEvent(eventName, { "detail": { "ol-event": olEvent, "map": map } } );
    // no need to add event listeners here, that is done by IXSL
    document.dispatchEvent(event);
};

$(document).ready(function()
{
    // turn off browser autocomplete for input's with our own autocomplete
    $("input.typeahead").attr("autocomplete", "off");
    
    $(".navbar-inner .btn.btn-navbar").on("click", function()
    {
        if ($("#collapsing-top-navbar").hasClass("in"))
            $("#collapsing-top-navbar").removeClass("collapse in").height(0);
        else $("#collapsing-top-navbar").addClass("collapse in").height("auto");
    });

    $("body").on("click", function(event)
    {
        // hide button groups
        var dropdown = $(this).find(".btn-group:has(.btn.dropdown-toggle).open");
        if (!($(event.target).parent().is(dropdown))) dropdown.toggleClass("open");
    });
    
    // handled by Saxon-JS when it's loaded
    $(".dropdown-toggle").on("click", function(event)
    {
        $(event.target).dropdown("toggle");
    });
    
});