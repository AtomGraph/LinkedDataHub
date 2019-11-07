/*
 * WYMeditor : what you see is What You Mean web-based editor
 * Copyright (c) 2005 - 2011 Jean-Francois Hovinne, http://www.wymeditor.org/
 * Dual licensed under the MIT (MIT-license.txt)
 * and GPL (GPL-license.txt) licenses.
 *
 * For further information visit:
 *        http://www.wymeditor.org/
 *
 * File Name:
 *        jquery.wymeditor.rdfa.js
 *        RDFa plugin for WYMeditor
 *
 * File Authors:
 *        Jean-Francois Hovinne (@jfhovinne)
 */

//Extend WYMeditor
WYMeditor.editor.prototype.rdfa = function (options) {
    var wym = this,
        rdfa = new WYMeditor.RDFa(options, wym);
    return rdfa;
};

//RDFa constructor
WYMeditor.RDFa = function (options, wym) {
    var rdfa = this;
    options = jQuery.extend({
        setStdNameSpaces: true,
        extendXHTMLParser: true,
        buttons: {}
    }, options);

    rdfa._options = options;
    rdfa._wym = wym;
    rdfa.init();
};

//RDFa plugin init
WYMeditor.RDFa.prototype.init = function () {
    var rdfa = this;
    if (rdfa._options.setStdNameSpaces) {
        rdfa.setStdNameSpaces();
    }
    if (rdfa._options.extendXHTMLParser) {
        rdfa.extendXHTMLParser();
    }
    rdfa.setButtons();
};

//Adding the namespaces to the document
WYMeditor.RDFa.prototype.setStdNameSpaces = function () {
    var rdfa = this;
    rdfa.addNameSpace('xmlns', 'http://www.w3.org/1999/xhtml');
    rdfa.addNameSpace('version', 'XHTML+RDFa 1.0');
};

WYMeditor.RDFa.prototype.addNameSpace = function (attr, value) {
    var rdfa = this;
    jQuery('html', rdfa._wym._doc)
        .attr(attr, value);
};

WYMeditor.RDFa.prototype.extendXHTMLParser = function () {
    var rdfa = this;
    rdfa.extendAttributes();
    rdfa.setStdVocabularies();
    rdfa.extendLinkAttributes();
};

WYMeditor.RDFa.prototype.extendAttributes = function () {
    //Add the RDFa attributes
    WYMeditor.XhtmlValidator._attributes.core.attributes.push(
        'rel',
        'rev',
        'content',
        'href',
        'src',
        'about',
        'property',
        'resource',
        'datatype',
        'typeof'
    );
};

WYMeditor.RDFa.prototype.setStdVocabularies = function () {
    var rdfa = this;
    //Add the 'standard' vocabularies
    vocabularies = [
        'xmlns:biblio',
        'xmlns:cc',
        'xmlns:dbp',
        'xmlns:dbr',
        'xmlns:dc',
        'xmlns:ex',
        'xmlns:foaf',
        'xmlns:rdf',
        'xmlns:rdfs',
        'xmlns:taxo',
        'xmlns:xhv',
        'xmlns:xsd'
    ];
    jQuery.each(vocabularies, function (index, vocabulary) {
        rdfa.addVocabulary(vocabulary);
    });
};

WYMeditor.RDFa.prototype.addVocabulary = function (vocabulary) {
    WYMeditor.XhtmlValidator._attributes.core.attributes.push(vocabulary);
};

WYMeditor.RDFa.prototype.extendLinkAttributes = function () {
    //Overwrite the <a> attributes 'rel' and 'rev'
    WYMeditor.XhtmlValidator._tags.a = {
        "attributes": {
            "0": "charset",
            "1": "coords",
            "2": "href",
            "3": "hreflang",
            "4": "name",
            "5": "rel",
            "6": "rev",
            "shape": /^(rect|rectangle|circ|circle|poly|polygon)$/,
            "7": "type"
        }
    };
};

WYMeditor.RDFa.prototype.setButtons = function () {
    var rdfa = this,
        list = jQuery(rdfa._wym._box).find('div.wym_classes ul');
    jQuery.each(rdfa._options.buttons, function (index, button) {
        list
            .append('<li></li>')
            .children(':last')
            .append('<a></a>')
            .children(':last')
            .attr('href', '#')
            .text(button.title)
            .bind('click',
                {
                    instance: rdfa._wym,
                    button: button,
                    ns: button.ns,
                    attr: button.attr,
                    value: button.value
                },
                rdfa.clickButtonHandler);
    });
};

WYMeditor.RDFa.prototype.clickButtonHandler = function (evt) {
    var wym = evt.data.instance,
        selected  = wym.selectedContainer();

    //the attribute already exists, remove it
    if (typeof jQuery(selected).attr(evt.data.attr) !== 'undefined' &&
            jQuery(selected).attr(evt.data.attr) !== '') {
        WYMeditor.console.log(
            'attribute already exists, remove it:',
            evt.data.attr,
            jQuery(selected).attr(evt.data.attr)
        );
        jQuery(selected)
            .removeAttr(evt.data.attr)
            .removeClass(evt.data.ns)
            .removeClass(evt.data.attr)
            .removeClass(evt.data.value);

    //else, add it
    } else {
        WYMeditor.console.log('attribute does not exist, add it:', evt.data.attr, evt.data.value);
        if (evt.data.value) { //value available
            jQuery(selected)
                .attr(evt.data.attr, evt.data.ns + ':' + evt.data.value)
                .addClass(evt.data.ns)
                .addClass(evt.data.attr)
                .addClass(evt.data.value);
        } else { //value not available
            evt.data.value = prompt('Value', '');
            if (evt.data.value !== null) {
                jQuery(selected)
                    .attr(evt.data.attr, evt.data.value)
                    .addClass(evt.data.ns)
                    .addClass(evt.data.attr)
                    .addClass(evt.data.value);
            }
        }
    }
    return false;
};
