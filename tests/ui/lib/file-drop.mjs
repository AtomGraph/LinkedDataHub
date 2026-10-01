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

// `bytes` for a file whose content matters, `text` for one where only its size does: a string crosses
// into the page as one value where a byte array crosses as one number per byte.
export async function fileTransfer(page, { name, type = '', bytes, text }) {
    return page.evaluateHandle(({ name, type, bytes, text }) => {
        const transfer = new DataTransfer();
        const content = text !== undefined ? text : Uint8Array.from(bytes);
        transfer.items.add(new File([content], name, { type }));
        return transfer;
    }, { name, type, bytes: bytes && [...bytes], text });
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

// A real external drag, for what the two synthetic events above cannot show: which element the browser
// fires dragleave on. Chromium's Input.dispatchDragEvent stands in for the OS - it hit-tests and moves its
// current target element itself, a drag tick at a time - and a dragOver outside the viewport is the drag
// leaving the window (dragCancel fires nothing at all). The file has to exist on disk; only its path
// crosses the protocol.
export async function externalDrag(page, path) {
    const cdp = await page.context().newCDPSession(page);
    const data = { items: [], files: [path], dragOperationsMask: 1 };
    const send = (type, x, y) => cdp.send('Input.dispatchDragEvent', { type, x, y, data });
    return {
        enter: (x, y) => send('dragEnter', x, y),
        over: (x, y) => send('dragOver', x, y),
        leaveWindow: () => send('dragOver', -20, -20),
    };
}
