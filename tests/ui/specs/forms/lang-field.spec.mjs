// The language of a value, while the value is being edited.
//
// Everything else in a form row's annotation strip is chrome - the term kind, the datatype - and
// the row hides its chrome until you reach for it. The language is not chrome. "Denmark"@en and
// "Denmark"@da are two different literals, so the tag is half of the value the field holds, and a
// concept carrying five skos:prefLabels is told apart by nothing else on the row. Hidden, the form
// showed five identical-looking rows and "one prefLabel per language" could not be checked by eye.
//
// So the fade sits on the strip's children rather than on the strip, and a language field that HAS
// a language is exempt. Both halves are asserted here, because the exemption is only right if it
// IS an exemption: a spec that only checked the language would still pass if the whole strip had
// simply been un-hidden, which is the change this one is guarding against.
//
// opacity is what the assertions read, and it has to be the EFFECTIVE one - the product of the
// element's own opacity and every ancestor's. Two traps sit here. toBeVisible() is no help: an
// element at opacity 0 has a box and passes it, which is exactly how the strip was hiding itself.
// And getComputedStyle(el).opacity reports only el's OWN value, so reading it off the language
// field returns 1 whether or not the strip above it is faded to nothing - a spec written that way
// passes against the very code it is meant to reject. Ask for what the reader sees instead.
import { test, expect } from '../../lib/console.mjs';
import { goto } from '../../lib/settle.mjs';
import { fieldFor } from '../../lib/form.mjs';
import { conceptBlock, conceptPage } from '../../lib/taxonomy.mjs';
import { NARROWER, createButton, viewBlock } from '../../lib/view.mjs';
import { constructorModal } from '../../lib/modal.mjs';

const PREF_LABEL = 'http://www.w3.org/2004/02/skos/core#prefLabel';

test.beforeEach(({}, testInfo) => {
    test.skip(testInfo.project.name !== 'owner', 'a form is only offered to an agent who may write');
});

const painted = locator => locator.evaluate(el => {
    let value = 1;
    for (let node = el; node && node !== document.body; node = node.parentElement) {
        value *= Number(getComputedStyle(node).opacity);
    }
    return value;
});
const fill = locator => locator.evaluate(el => getComputedStyle(el).backgroundColor);

// The row the concept's English prefLabel is edited in, with the pointer parked in the corner and
// nothing in the row focused. Both are preconditions rather than incidentals: :hover and
// :focus-within are the two things that reveal the strip, so a spec that did not establish their
// absence would pass on a page where the row happened to be live.
async function restingLabelRow(page) {
    await goto(page, conceptPage('coffee'));

    const block = conceptBlock(page, 'coffee');
    await block.locator('button.btn-edit').first().click();
    await expect(block.locator('form').first()).toBeVisible({ timeout: 30_000 });

    const row = fieldFor(block.locator('form').first(), PREF_LABEL).locator('.ldh-prop-row').first();
    await expect(row).toBeVisible();

    await page.mouse.move(0, 0);
    await row.evaluate(el => el.querySelector(':focus')?.blur());
    expect(await row.evaluate(el => el.matches(':hover') || el.matches(':focus-within'))).toBe(false);

    return row;
}

test('shows the language of a stored value without being asked', { tag: '@owner' }, async ({ page }) => {
    const row = await restingLabelRow(page);

    // The tag the fixture seeded, in the field that edits it.
    await expect(row.locator('.ldh-lang input[name="ll"]')).toHaveValue('en');
    expect(await painted(row.locator('.ldh-lang').first())).toBe(1);
});

test('and still hides the datatype chip beside it', { tag: '@owner' }, async ({ page }) => {
    const row = await restingLabelRow(page);

    // rdf:langString - it follows from the value having a language at all, so it stays chrome.
    const chip = row.locator('.ldh-annot > .ac-tag').first();
    expect(await painted(chip)).toBe(0);

    await row.hover();
    await expect.poll(() => painted(chip)).toBe(1);
});

test('wears a tag at rest and a field once the row is live', { tag: '@owner' }, async ({ page }) => {
    const row = await restingLabelRow(page);
    const box = row.locator('.ldh-lang .ac-field-box').first();

    // Filled, not transparent: at rest the field reads as the tag the read view renders rather
    // than as loose text next to the value. The colours themselves are tokens and are not asserted
    // - what is asserted is that the two states are different fills, and that the resting one is
    // painted at all.
    const atRest = await fill(box);
    expect(atRest).not.toBe('rgba(0, 0, 0, 0)');

    await row.hover();
    await expect.poll(() => fill(box)).not.toBe(atRest);
});

// The strip beside a control clips what does not fit on its line (overflow hidden, by design: a strip that
// wrapped made every form row twice as tall), and a modal's column is narrower than a page's. In the Create
// dialog a row left the strip less room than its two chips need, and the language field, the one annotation the
// row shows at rest, was the one cut: it sat after the datatype chip, which is laid out at full width even while
// hidden, and lost its last 29px past the strip's edge in every engine. So this is asserted where the strip is
// short, and the precondition is asserted too - a strip wide enough for both would pass against the very layout
// this guards against.
test('stays whole in a modal, where the strip is short', { tag: '@owner' }, async ({ page }) => {
    await goto(page, conceptPage('cold-drinks'));
    const create = createButton(viewBlock(page, NARROWER));
    await expect(create).toBeVisible({ timeout: 60_000 });
    await create.click();
    const modal = constructorModal(page);
    await expect(modal).toBeVisible();

    const row = fieldFor(modal, PREF_LABEL).locator('.ldh-prop-row').first();
    const strip = row.locator('.ldh-annot').first();
    const pill = row.locator('.ldh-lang').first();
    await expect(pill).toBeVisible();

    const edges = locator => locator.evaluate(el => {
        const { left, right, width } = el.getBoundingClientRect();
        return { left, right, width };
    });
    // the chip's own width, however much of it the strip lets it keep: its label plus the tag's padding and border
    const chipNaturalWidth = await row.locator('.ldh-annot > .ac-tag').first().evaluate(el => {
        const style = getComputedStyle(el);
        return el.querySelector('.ac-tag-lbl').scrollWidth
            + parseFloat(style.paddingLeft) + parseFloat(style.paddingRight)
            + parseFloat(style.borderLeftWidth) + parseFloat(style.borderRightWidth);
    });
    const [stripBox, pillBox] = await Promise.all([edges(strip), edges(pill)]);

    expect(stripBox.width, 'the strip is too short for both chips, else this row proves nothing')
        .toBeLessThan(pillBox.width + chipNaturalWidth);
    expect(pillBox.width, 'the language field keeps its width').toBeGreaterThan(0);
    expect(pillBox.right, 'and all of it is inside the strip').toBeLessThanOrEqual(stripBox.right + 0.5);
});
