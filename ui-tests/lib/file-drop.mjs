// Driving a file drop without a desktop to drag from.
//
// Playwright has no gesture for an external file drag: nothing outside the page can be picked up.
// What the page sees of one is a DragEvent whose DataTransfer lists "Files" among its types, and
// that can be built in the page - a DataTransfer with a File added through its items reports
// exactly that, and carries the File where the drop handler reads it (client.xsl, `dataTransfer.files`).
//
// The gesture is two events, where a real drag is many: `dragenter` on the body mounts the overlay
// (the rule matches any element, gated on the Files type and on being allowed to write), and the
// `drop` lands on the overlay itself, which is where a real drop lands too - it is the topmost hit
// target for the whole drag, by design.

export async function fileTransfer(page, { name, type = '', bytes }) {
    return page.evaluateHandle(({ name, type, bytes }) => {
        const transfer = new DataTransfer();
        transfer.items.add(new File([Uint8Array.from(bytes)], name, { type }));
        return transfer;
    }, { name, type, bytes: [...bytes] });
}

// Mount the overlay for a drag carrying this transfer, and return the overlay's locator.
export async function dragIn(page, dataTransfer) {
    await page.dispatchEvent('body', 'dragenter', { dataTransfer });
    const overlay = page.locator('#file-drop');
    await overlay.waitFor();
    return overlay;
}

export async function dropFile(page, file) {
    const dataTransfer = await fileTransfer(page, file);
    await dragIn(page, dataTransfer);
    await page.dispatchEvent('#file-drop', 'drop', { dataTransfer });
}
