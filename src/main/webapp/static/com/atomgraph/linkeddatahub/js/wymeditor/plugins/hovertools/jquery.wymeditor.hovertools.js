/*jslint evil: true */
/**
    WYMeditor.hovertools
    ====================

    A hovertools plugin.
*/

WYMeditor.editor.prototype.hovertools = function() {
    var wym = this;

    wym.status('&#160;');

    // Bind events on buttons
    jQuery(wym._box).find(wym._options.toolSelector).hover(
        function() {
            var button = this;
            wym.status(jQuery(button).html());
        },
        function() {
            wym.status('&#160;');
        }
    );

    // Classes: add/remove a style attr to matching elems
    // while mouseover/mouseout
    jQuery(wym._box).find(wym._options.classSelector).hover(
        function() {
            var button = this,
                aClasses = eval(wym._options.classesItems),
                sName = jQuery(button).attr(WYMeditor.NAME),
                oClass = WYMeditor.Helper._getFromArrayByName(aClasses, sName);

            if (oClass){
                jqexpr = oClass.expr;
                // Don't use jQuery.find() on the iframe body
                // because of MSIE + jQuery + expando issue (#JQ1143)
                if (!WYMeditor.isInternetExplorerPre11()) {
                    wym.$body().find(jqexpr).css('background-color','#cfc');
                }
            }
        },
        function() {
            // Don't use jQuery.find() on the iframe body
            // because of MSIE + jQuery + expando issue (#JQ1143)
            if (!WYMeditor.isInternetExplorerPre11()) {
                wym.$body().find('*').removeAttr('style');
            }
        }
    );
};
