/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */

package com.atomgraph.linkeddatahub.server.util;

import org.apache.jena.sparql.core.Quad;
import org.apache.jena.sparql.modify.request.UpdateModify;
import org.apache.jena.sparql.modify.request.UpdateVisitorBase;

/**
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class PatchUpdateVisitor extends UpdateVisitorBase
{

    private boolean containsNamedGraph = false;

    @Override
    public void visit(UpdateModify update)
    {
        if (!update.getDeleteAcc().getGraph().equals(Quad.defaultGraphNodeGenerated)) containsNamedGraph = true;
        if (!update.getInsertAcc().getGraph().equals(Quad.defaultGraphNodeGenerated)) containsNamedGraph = true;
        
        
        //update.getWherePattern().visit(ev);
    }

    public boolean isContainsNamedGraph()
    {
        return containsNamedGraph;
    }
    
}
