/*
 * Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.atomgraph.linkeddatahub.cli.vocab;

import org.apache.jena.rdf.model.Property;
import org.apache.jena.rdf.model.Resource;
import org.apache.jena.rdf.model.ResourceFactory;

/**
 * LinkedDataHub vocabulary.
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public final class LDH
{

    /** Namespace URI */
    public static final String NS = "https://w3id.org/atomgraph/linkeddatahub#";

    private LDH() { }

    /** ldh:Object class */
    public static final Resource Object = ResourceFactory.createResource(NS + "Object");
    /** ldh:XHTML class */
    public static final Resource XHTML = ResourceFactory.createResource(NS + "XHTML");
    /** ldh:View class */
    public static final Resource View = ResourceFactory.createResource(NS + "View");
    /** ldh:ResultSetChart class */
    public static final Resource ResultSetChart = ResourceFactory.createResource(NS + "ResultSetChart");
    /** ldh:CSVImport class */
    public static final Resource CSVImport = ResourceFactory.createResource(NS + "CSVImport");
    /** ldh:RDFImport class */
    public static final Resource RDFImport = ResourceFactory.createResource(NS + "RDFImport");
    /** ldh:MissingPropertyValue constraint class */
    public static final Resource MissingPropertyValue = ResourceFactory.createResource(NS + "MissingPropertyValue");
    /** ldh:ChildrenView resource */
    public static final Resource ChildrenView = ResourceFactory.createResource(NS + "ChildrenView");
    /** ldh:SelectChildren query resource */
    public static final Resource SelectChildren = ResourceFactory.createResource(NS + "SelectChildren");

    /** ldh:service property */
    public static final Property service = ResourceFactory.createProperty(NS + "service");
    /** ldh:file property */
    public static final Property file = ResourceFactory.createProperty(NS + "file");
    /** ldh:delimiter property */
    public static final Property delimiter = ResourceFactory.createProperty(NS + "delimiter");
    /** ldh:chartType property */
    public static final Property chartType = ResourceFactory.createProperty(NS + "chartType");
    /** ldh:categoryVarName property */
    public static final Property categoryVarName = ResourceFactory.createProperty(NS + "categoryVarName");
    /** ldh:seriesVarName property */
    public static final Property seriesVarName = ResourceFactory.createProperty(NS + "seriesVarName");

}
