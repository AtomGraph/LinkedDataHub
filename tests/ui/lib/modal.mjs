import { expect } from '@playwright/test';

// Every dialog in the product is one anatomy: a `.ac-backdrop.modal` holding a `.ac-modal` card.
// The backdrop is the dismissal surface and the card is what must survive a press, so a spec that
// means one of them must never address the other.
export const modals = page => page.locator('div.ac-backdrop.modal');
export const cardOf = modal => modal.locator('.ac-modal').first();

// The document's own edit form. It is a modal rather than an inline form because the resource it
// edits is the one the document is about - form placement follows document membership - and it is
// reached through the action bar's overflow menu, which is two presses rather than one.
export async function openDocumentForm(page) {
    await page.locator('div.ldh-of-wrap button.drop-toggle').first().click();
    await page.locator('div.ldh-of-menu button.btn-edit').first().click();

    const modal = page.locator('div.modal').filter({ has: page.locator('form') }).first();
    await expect(modal).toBeVisible({ timeout: 30_000 });
    return modal;
}

// The constructor modal a view's Create button opens: addressed by @about (the resource being
// created) and @data-instance (the container it will be stored in), which is what tells it apart
// from the document edit modal that shares its markup.
export const constructorModal = page => page.locator('div.modal.modal-constructor');
