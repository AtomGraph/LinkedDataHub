// The taxonomy package's hierarchy blocks - what a concept's Broader and Narrower views show.
//
// Unlike the tree beside them, these are ordinary ontology-defined views: one per hierarchy
// property, each with its SELECT stored in the package, so what a block shows is what its
// query returns. Two properties of those queries have each been wrong once, and neither is
// visible from the tree - which unions the directions itself and joins no label at all:
//
//   - the link is read from BOTH ends, because SKOS lets either carry it;
//   - the label is joined as a SORT KEY and never filtered, because filtering it to English
//     dropped every concept labelled in another language - silently, with the triple sitting
//     in the graph and the tree showing the concept the block denied.
import { test, expect } from '../../../../lib/console.mjs';
import { goto } from '../../../../lib/settle.mjs';
import { addTriple, concept, document, labelOf, removeTriple, seedConcept } from '../../../../lib/taxonomy.mjs';
import { BROADER, NARROWER, PREF_LABEL, rowFor, rowLabel, rows, viewBlock } from '../../../../lib/view.mjs';
import { READ_MODE, inMode } from '../../../../lib/mode.mjs';

const pageFor = name => inMode(document(name), READ_MODE);

test.describe('concept hierarchy blocks', () => {
    // Not ownership - nothing is readable anonymously until an authorization says so, and these
    // documents are dh:Items like any other. These blocks render what the hierarchy query returns,
    // and the query returns it to whoever may run it: who that is belongs to http-tests, which
    // covers the modes and classes directly. See concept-tree for the same reasoning at length.
    test.beforeEach(({}, testInfo) => {
        test.skip(testInfo.project.name !== 'owner',
            'the blocks render what the query returns, identically for either agent; whether a refusal happens is http-tests\' subject');
    });

    test('shows children asserted from either end of the link', async ({ page }) => {
        await goto(page, pageFor('hot-drinks'));
        const narrower = viewBlock(page, NARROWER);

        // coffee names hot-drinks as its skos:broader; tea is named by hot-drinks as
        // skos:narrower, in hot-drinks' own graph. One block, both directions.
        await expect(rowFor(narrower, concept('coffee'))).toHaveCount(1);
        await expect(rowFor(narrower, concept('tea'))).toHaveCount(1);
        await expect(rows(narrower)).toHaveCount(2);
    });

    test('pairs each document with its topic into one row', async ({ page }) => {
        await goto(page, pageFor('hot-drinks'));
        const coffee = rowFor(viewBlock(page, NARROWER), concept('coffee'));

        // The results hold the document AND its topic. Unpaired they render as two rows -
        // one unlabelled document, one inert topic - so the count in the test above is
        // half of this assertion; the label is the other half. The view drops the document
        // that names the topic, so the surviving row is the topic's: it anchors the CONCEPT
        // and takes its label from it.
        await expect(coffee).toHaveCount(1);
        await expect(rowLabel(coffee)).toHaveText(labelOf('coffee'));
    });

    test('shows a concept labelled in a language the reader did not ask for', async ({ page }) => {
        // The browser asks for English. This concept is labelled in Lithuanian and in
        // nothing else - the state every concept created through the form reached while
        // the language control followed a Lithuanian browser.
        const undo = await seedConcept({ name: 'sula', label: 'Sula', lang: 'lt', parent: 'cold-drinks' });
        try {
            await goto(page, pageFor('cold-drinks'));
            const narrower = viewBlock(page, NARROWER);

            await expect(rowFor(narrower, concept('sula'))).toHaveCount(1);
            await expect(rowLabel(rowFor(narrower, concept('sula')))).toHaveText('Sula');
            // Its English-labelled sibling is still there: this is about what the filter
            // excluded, not about swapping one exclusion for another.
            await expect(rowFor(narrower, concept('juice'))).toHaveCount(1);
            // One row per concept, which is what the label being an unprojected sort key
            // rather than a selector buys - and what the filter was mistaken for doing.
            await expect(rows(narrower)).toHaveCount(2);

            // And from its own page, the same link read from the other end.
            await goto(page, pageFor('sula'));
            await expect(rowFor(viewBlock(page, BROADER), concept('cold-drinks'))).toHaveCount(1);
        } finally {
            await undo();
        }
    });

    test('yields one row for a concept carrying labels in several languages', async ({ page }) => {
        // Two labels, two solutions before DISTINCT - and the sort key is not projected,
        // so the row must not split. This is what the removed filter was mistaken for
        // doing, and the reason removing it costs nothing here.
        const second = `<${concept('juice')}> <${PREF_LABEL}> "Sultys"@lt`;
        await addTriple(document('juice'), second);
        try {
            await goto(page, pageFor('cold-drinks'));

            const juice = rowFor(viewBlock(page, NARROWER), concept('juice'));
            await expect(juice).toHaveCount(1);
            // The reader asked for English, so the English label is the one shown.
            await expect(rowLabel(juice)).toHaveText(labelOf('juice'));
        } finally {
            await removeTriple(document('juice'), second);
        }
    });
});
