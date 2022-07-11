// Copyright (c) 2011 PolicyStat LLC.
// SPDX-FileCopyrightText: 2017-2022 2017 Martynas Jusevicius, <martynas@atomgraph.com> et al.
//
// SPDX-License-Identifier: Apache-2.0

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
