/* global -$ */
"use strict";

/**
 * The resizable plugin makes the wymeditor box vertically resizable.
 * It it based on the ui.resizable.js plugin of the jQuery UI library.
 *
 * The WYMeditor resizable plugin supports all parameters of the jQueryUI
 * resizable plugin. The parameters are passed like this:
 *
 *         wym.resizable({ handles: "s,e",
 *                         maxHeight: 600 });
 *
 * DEPENDENCIES: jQuery UI, jQuery UI resizable
 *
 * @param options options for the plugin
 */
WYMeditor.editor.prototype.resizable = function (options) {
    var wym = this,
        $iframe = jQuery(wym._box).find('iframe'),
        $iframeDiv = jQuery(wym._box).find('.wym_iframe'),
        // Define some default options
        defaultOptions = {
            resize: function () {
                $iframeDiv.height($iframe.height());
            },
            alsoResize: $iframe,
            handles: "s,e,se",
            minHeight: 250
        },
        // Merge given options with default options. Given options override
        // default ones.
        finalOptions = jQuery.extend(defaultOptions, options);

    if (jQuery.isFunction(jQuery.fn.resizable)) {
        jQuery(wym._box).resizable(finalOptions);
    } else {
        WYMeditor.console.error('Oops, jQuery UI.resizable unavailable.');
    }

};
