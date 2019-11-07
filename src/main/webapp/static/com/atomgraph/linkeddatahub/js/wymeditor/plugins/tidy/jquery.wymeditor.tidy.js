"use strict";

function WymTidy(options, wym) {
    var wymTidy = this,
        wandUrl = wym._options.basePath + "plugins/tidy/wand.png";
    options = jQuery.extend({
        sUrl:            wym._options.basePath + "plugins/tidy/tidy.php",
        sButtonHtml:     "" +
            "<li class='wym_tools_tidy'>" +
                "<a name='CleanUp' href='#'" +
                    " style='background-image: url(" + wandUrl + ")'>" +
                    "Clean up HTML" +
                "</a>" +
            "</li>",

        sButtonSelector: "li.wym_tools_tidy a"

    }, options);

    wymTidy._options = options;
    wymTidy._wym = wym;
}

//Extend WYMeditor
WYMeditor.editor.prototype.tidy = function (options) {
    var wym = this,
        tidy = new WymTidy(options, wym);
    return tidy;
};


//WymTidy initialization
WymTidy.prototype.init = function () {
    var tidy = this,
        wym = tidy._wym;

    jQuery(wym._box).find(
        wym._options.toolsSelector + wym._options.toolsListSelector
    ).append(tidy._options.sButtonHtml);

    //handle click event
    jQuery(wym._box).find(
        tidy._options.sButtonSelector
    ).click(
        function () {
            tidy.cleanup();
            return false;
        }
    );
};

//WymTidy cleanup
WymTidy.prototype.cleanup = function () {
    var tidy = this,
        wym = tidy._wym,
        html = "<html><body>" + wym.html() + "</body></html>";

    jQuery.post(
        tidy._options.sUrl,
        {html: html},
        function (data) {
            if (data.length > 0 && data !== '0') {
                if (data.indexOf("<?php") === 0) {
                    wym.status("Ooops... Is PHP installed?");
                } else {
                    wym.html(data);
                    wym.status("HTML has been cleaned up.");
                }
            } else {
                wym.status("An error occurred.");
            }
        }
    );
};
