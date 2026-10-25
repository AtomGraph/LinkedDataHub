/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */

package com.atomgraph.linkeddatahub.server.util;

import jakarta.ws.rs.WebApplicationException;
import org.apache.jena.sparql.algebra.Algebra;
import org.apache.jena.sparql.algebra.OpVisitorBase;
import org.apache.jena.sparql.algebra.op.OpDatasetNames;
import org.apache.jena.sparql.algebra.op.OpGraph;
import org.apache.jena.sparql.algebra.op.OpQuad;
import org.apache.jena.sparql.algebra.op.OpQuadBlock;
import org.apache.jena.sparql.algebra.op.OpQuadPattern;
import org.apache.jena.sparql.algebra.walker.Walker;
import org.apache.jena.sparql.core.Quad;
import org.apache.jena.sparql.expr.ExprVisitorBase;
import org.apache.jena.sparql.modify.request.UpdateDeleteWhere;
import org.apache.jena.sparql.modify.request.UpdateModify;
import org.apache.jena.sparql.modify.request.UpdateVisitorBase;
import org.apache.jena.update.Update;
import org.apache.jena.update.UpdateRequest;
import static com.atomgraph.server.status.UnprocessableEntityStatus.UNPROCESSABLE_ENTITY;

/**
 * Visitor for SPARQL PATCH updates to detect named graph usage.
 * A PATCH is executed against the document's graph alone, as the default graph of a dataset with no named
 * graphs, so a <code>GRAPH</code> pattern or a <code>WITH</code>/<code>USING</code> clause cannot match anything
 * there: the update would change nothing and still be answered as a success.
 *
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class PatchUpdateVisitor extends UpdateVisitorBase
{

    private boolean containsNamedGraph = false;
    private boolean containsDataset = false;

    @Override
    public void visit(UpdateDeleteWhere update)
    {
        update.getQuads().forEach(this::visit);
    }

    @Override
    public void visit(UpdateModify update)
    {
        update.getDeleteAcc().getQuads().forEach(this::visit);
        update.getInsertAcc().getQuads().forEach(this::visit);

        if (update.getWithIRI() != null || !update.getUsing().isEmpty() || !update.getUsingNamed().isEmpty()) containsDataset = true;

        // the algebra rather than the syntax tree: the syntax walker does not descend into sub-SELECTs or into
        // the graph patterns of FILTER [NOT] EXISTS, which the algebra walker does once it is given an expression
        // visitor. SERVICE is skipped, as a GRAPH inside it is evaluated by the remote endpoint
        Walker.walkSkipService(Algebra.compile(update.getWherePattern()), new OpVisitorBase()
        {

            @Override
            public void visit(OpGraph opGraph)
            {
                containsNamedGraph = true;
            }

            @Override
            public void visit(OpDatasetNames opDatasetNames)
            {
                containsNamedGraph = true;
            }

            @Override
            public void visit(OpQuadPattern opQuadPattern)
            {
                if (!opQuadPattern.isDefaultGraph()) containsNamedGraph = true;
            }

            @Override
            public void visit(OpQuadBlock opQuadBlock)
            {
                opQuadBlock.getPattern().forEach(PatchUpdateVisitor.this::visit);
            }

            @Override
            public void visit(OpQuad opQuad)
            {
                PatchUpdateVisitor.this.visit(opQuad.getQuad());
            }

        }, new ExprVisitorBase(), null, null);
    }

    /**
     * Records a quad that addresses a graph other than the default one.
     *
     * @param quad template or pattern quad
     */
    protected void visit(Quad quad)
    {
        if (!quad.isDefaultGraph()) containsNamedGraph = true;
    }

    /**
     * Returns true if the SPARQL update contains the <code>GRAPH</code> keyword, in the <code>INSERT</code>/<code>DELETE</code>
     * templates, in the <code>DELETE WHERE</code> pattern or anywhere in the <code>WHERE</code> pattern.
     * @return true if there is a named graph pattern
     */
    public boolean containsNamedGraph()
    {
        return containsNamedGraph;
    }

    /**
     * Returns true if the SPARQL update names its dataset with <code>WITH</code>, <code>USING</code> or <code>USING NAMED</code>.
     * @return true if there is a dataset clause
     */
    public boolean containsDataset()
    {
        return containsDataset;
    }

    /**
     * Refuses an update that a PATCH cannot apply to a single graph, with <code>422 Unprocessable Entity</code>:
     * more than one operation, a form other than <code>DELETE/INSERT ... WHERE</code> and <code>DELETE WHERE</code>,
     * a <code>GRAPH</code> pattern, or a dataset clause.
     *
     * @param updateRequest SPARQL update
     * @throws WebApplicationException if the update cannot be applied
     */
    public static void validate(UpdateRequest updateRequest)
    {
        if (updateRequest.getOperations().size() != 1)
            throw new WebApplicationException("Only a single SPARQL Update is supported by PATCH", UNPROCESSABLE_ENTITY.getStatusCode()); // 422 Unprocessable Entity

        Update update = updateRequest.getOperations().get(0);
        if (!(update instanceof UpdateModify || update instanceof UpdateDeleteWhere))
            throw new WebApplicationException("Only INSERT/WHERE and DELETE WHERE forms of SPARQL Update are supported by PATCH", UNPROCESSABLE_ENTITY.getStatusCode()); // 422 Unprocessable Entity

        PatchUpdateVisitor visitor = new PatchUpdateVisitor();
        update.visit(visitor);
        if (visitor.containsNamedGraph())
            throw new WebApplicationException("SPARQL update used with PATCH method cannot contain the GRAPH keyword", UNPROCESSABLE_ENTITY.getStatusCode()); // 422 Unprocessable Entity
        if (visitor.containsDataset())
            throw new WebApplicationException("SPARQL update used with PATCH method cannot contain WITH, USING or USING NAMED", UNPROCESSABLE_ENTITY.getStatusCode()); // 422 Unprocessable Entity
    }

}
