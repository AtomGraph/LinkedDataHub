/**
 * Copyright (c) 2011 PolicyStat LLC.
 * MIT licensed (MIT-license.txt)
 *
 * This plugin adds the ability to use tab and shift+tab to indent/outdent
 * lists, mimicking a user's expected behavior when inside an editor.
 *
 * @author Wes Winham (winhamwr@gmail.com)
 */

function ListPlugin(options, wym) {
    var listPlugin = this;
    ListPlugin._options = jQuery.extend({}, options);
    listPlugin._wym = wym;

    listPlugin.init();
}

ListPlugin.prototype.init = function() {
    var listPlugin = this;
    listPlugin._wym.listPlugin = listPlugin;

    listPlugin.bindEvents();
};

ListPlugin.prototype.bindEvents = function() {
    var listPlugin = this,
        wym = listPlugin._wym;

    wym.keyboard.combokeys.bind(
        "tab",
        function () {
            wym.indent();
            return false;
        }
    );
    wym.keyboard.combokeys.bind(
        "shift+tab",
        function () {
            wym.outdent();
            return false;
        }
    );
};
