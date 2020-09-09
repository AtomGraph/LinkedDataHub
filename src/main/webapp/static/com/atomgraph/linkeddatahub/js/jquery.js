/* global Saxon, stylesheetUri, baseUri, requestUri, absolutePath, lang, xslt2proc, UriBuilder */

var rdfXml = null; // TO-DO: set as xsl:param instead

function loadRDFXML(event, url, callback)
{
    $.ajax({url: url,
        headers: { "Accept": "application/rdf+xml" }
    }).
    done(function(data, textStatus, jqXHR)
    {
        rdfXml = jqXHR.responseXML;
        callback(event); // TO-DO: replace with xslt2proc.updateHTMLDocument() ?
    } ).
    fail(function(jqXHR, textStatus, errorThrown)
    {
        alert(errorThrown);
    });
}

var onTypeaheadInputBlur = function()
{
    // hide and empty the list with typeahead suggestions (otherwise it gets submitted with RDF/POST)
    $(this).nextAll("ul.typeahead").hide().empty();
};

var onModalFormSubmit = function(event)
{    
    if ($(this).find("input[name=rdf]").length)
    {
        var form = this;
        event.preventDefault();

        var container = $(this).find(".action-container");
        if (container.length) // POST only
        {
            var uriInput = container.find("button input[type=hidden]");
            if (uriInput.length)
            {
                var actionParts = this.action.split("?");
                var newAction = uriInput.val();
                if (actionParts.length > 1) newAction += "?" + actionParts[1]; // add query string
                this.action = newAction;
            }
            else
            {
                container.find(".control-group").toggleClass("error");
                return false;
            }
        }
        
        $(this).css("cursor", "progress"); // notify user that data processing is in progress

        // remove names of RDF/POST inputs with empty values
        $(this).find("input[name=ob]").filter(function() { return $(this).val() === ""; }).removeAttr("name");
        $(this).find("input[name=ou]").filter(function() { return $(this).val() === ""; }).removeAttr("name");
        $(this).find("input[name=ol]").filter(function() { return $(this).val() === ""; }).removeAttr("name");
        
        var settings = null;
        if (this.enctype === "multipart/form-data")
            settings = 
            {
                "method": this.method,
                "data": new FormData(this),
                "processData": false,
                "contentType": false,
                "headers": { "Accept": "text/html" }
            } ;
        else settings = 
            {
                "method": this.method,
                "data": $(this).serialize(),
                "contentType": "application/x-www-form-urlencoded", // RDF/POST
                "headers": { "Accept": "text/html" }
            } ;

        $.ajax(this.action, settings).
        done(function(responseXML, textStatus, jqXHR)
        {
            if (jqXHR.status === 200) // OK response to PUT
            {
                window.location.reload(); // refresh page to see changes from EditMode
                return true;
            }
            
            var location = jqXHR.getResponseHeader("Location"); // from 201 Created response
            console.log("Location: " + jqXHR.getResponseHeader("Location") + " Status: " + textStatus);
            if (location === null || jqXHR.status !== 201) // Created response to POST
            {
                alert("Could not create resource. Response status: " + textStatus);
                return false;
            }
            
            // if form submit did not originate from a typeahead (target), redirect to the created resource
            var targetId = $(form).find("input.target-id").val();
            if (targetId.length === 0) window.location = location;
                
            $.ajax(location,
                {
                    "method": "GET",
                    "headers": { "Accept": "application/rdf+xml, */*;q=0.1" } // RDF/XML response
                }
            ).
            done(function(responseXML, textStatus, jqXHR)
            {
                // render typeahead with XSLT if RDF/XML is returned
                if (jqXHR.getResponseHeader("Content-Type") === "application/rdf+xml;charset=UTF-8")
                {
                    // TO-DO: extract following block into a function
                    xslt2proc.setInitialTemplate(null);
                    xslt2proc.setInitialMode("{http://graphity.org/xsl/bootstrap/2.3.2}CreatedMode"); // namespace ignored
                    xslt2proc.setParameter(null, "constructor-form", form);
                    xslt2proc.setParameter(null, "created-uri", location);
                    xslt2proc.updateHTMLDocument(responseXML);
                }
                else
                {
                    // cannot render typeahead without RDF/XML, simply display URI value and remove form
                    $("#" + targetId).closest("div[class = 'controls']").find("span").find("input").val(location);
                    $(form).remove();
                }

                $(form).css("cursor", "default"); // data processing done
            }).
            fail(function(jqXHR, textStatus, errorThrown)
            {
                $(form).css("cursor", "default"); // data processing done
                alert(textStatus + " " + errorThrown);
            });
        }).
        fail(function(jqXHR, textStatus, errorThrown)
        {
            // if 4xx error (URISyntax/Constraint/SkolemizationViolations or ResourceExistsException), execute XSLT transformation
            if (jqXHR.status === 400 || jqXHR.status === 409) // TO-DO: a more precise check based on exception type?
            {
                var parser = new DOMParser();
                var html = parser.parseFromString(jqXHR.responseText, "text/html");
                
                // TO-DO: extract following block into a function
                xslt2proc.setInitialTemplate(null);
                xslt2proc.setInitialMode("{http://graphity.org/xsl/bootstrap/2.3.2}ConstructMode");  // namespace ignored
                xslt2proc.setParameter(null, "constructor-form", form);
                xslt2proc.setParameter(null, "constructor-doc", html);
                xslt2proc.updateHTMLDocument(html);

                $(form).css("cursor", "default"); // data processing done
            }
            else // otherwise, show error
            {
                $(form).css("cursor", "default"); // data processing done
                alert(errorThrown);
            }
        });
    }    
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

var onPrependedAppendedInputChange = function()
{
    // avoid selecting the tooltip <div> which gets inserted after the <input> (before the second <span>) during mouseover
    var prepended = $(this).prevAll("span.add-on");
    var appended = $(this).nextAll("span.add-on");
    var value = $(this).val();
    if (prepended.length) value = prepended.text() + value;
    if (appended.length) value = value + appended.text();
    $(this).siblings("input[type=hidden]").val(value); // set the concatenated value on the hidden input (which must exist)
};

var onContentDisplayToggle = function()
{
    $('body').find(".ContentMode").toggle();
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
    
    $(".input-prepend.input-append input[type=text]").on("change", onPrependedAppendedInputChange).change();
    
    $("input.typeahead").on("blur", onTypeaheadInputBlur);
    
    $(".btn.btn-toggle-content").on("click", onContentDisplayToggle);

    $("form").on("submit", function()
    {
        if ($(this).find("input[name=rdf]").length)
        {
            // remove names of RDF/POST inputs with empty values
            $(this).find("input[name=ob]").filter(function() { return $(this).val() === ""; }).removeAttr("name");
            $(this).find("input[name=ou]").filter(function() { return $(this).val() === ""; }).removeAttr("name");
            $(this).find("input[name=ol]").filter(function() { return $(this).val() === ""; }).removeAttr("name");
        }
    });
    
    $(".faceted-nav .nav-header.btn").on("click", function()
    {
        $(this).find("span.caret").toggleClass("caret-reversed");
        $(this).nextAll(".nav").toggle(); // hide the list with options
        var hidden = $(this).nextAll(".nav").is(":hidden");
        $(this).parent().find("input").prop("disabled", hidden); // disable all FILTER inputs if facet is hidden
        if (!hidden) $(this).parent().find("input[type='text']").focus(); // focus on text input if facet is visible
    });
    
});