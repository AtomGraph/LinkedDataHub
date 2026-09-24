// The rendering mode a document is asked for in.
//
// The URL is the source of truth: the client reads `?mode=` on every navigation and renders
// accordingly, so a spec that needs a document in a given mode asks for it in the address rather
// than by pressing the switcher and hoping. Six specs wrote this out for themselves before it
// lived here, each with its own copy of the URI.
export const READ_MODE = 'https://w3id.org/atomgraph/client#ReadMode';
export const EDIT_MODE = 'https://w3id.org/atomgraph/client#EditMode';
export const CONTENT_MODE = 'https://w3id.org/atomgraph/client#ContentMode';

export const inMode = (uri, mode) => `${uri}?mode=${encodeURIComponent(mode)}`;
