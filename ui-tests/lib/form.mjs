// The write layer's vocabulary: the control group a property is edited in, the two inputs a value
// can arrive through, and the bar that ends a form.
//
// It is the same anatomy wherever the form is rendered - a dialog's constructor form, a block's
// inline row form, the document's own edit form - which is why it lives here rather than beside
// whichever surface a spec happens to open it from.

// One property's control group: the group whose hidden RDF/POST predicate input names it.
export const fieldFor = (form, property) =>
    form.locator(`div.ldh-prop-group:has(input[name="pu"][value="${property}"])`);

// A resource control is an `ou` input with a type-ahead attached, and the type-ahead only helps
// you FIND a URI - nothing validates or rewrites what is in the box, and focusout merely hides the
// panel. So a spec that already knows the URI fills it, and stays a spec about what the save
// produces rather than about the type-ahead.
export const fillResource = (form, property, uri) =>
    fieldFor(form, property).locator('input[name="ou"]').fill(uri);

export const fillText = (form, property, text) =>
    fieldFor(form, property).locator('input[name="ol"]').fill(text);

export const textValue = (form, property) => fieldFor(form, property).locator('input[name="ol"]').first();

// The bar that ends a form: Reset acts on the form as a whole, Save submits it. Both are native
// button types (`reset` and `submit`), which is what makes Reset work without a handler at all.
export const formBar = form => form.locator('.ldh-form-bar').first();
export const resetButton = form => form.locator('button.btn-reset').first();
export const save = form => form.locator('button.btn-save').click();
