// The rendering mode a document is asked for in.
//
// The URL is the source of truth: the client reads `?mode=` on every navigation and renders
// accordingly, so a spec that needs a document in a given mode asks for it in the address rather
// than by pressing the switcher and hoping. Six specs wrote this out for themselves before it
// lived here, each with its own copy of the URI.
// Read and Edit are Web-Client's, Content is LinkedDataHub's own - a document laid out as content
// blocks is a platform idea and its mode URI says so. The two namespaces are one character apart
// in prose and not at all alike as identifiers, which is the reason they are named here once.
export const READ_MODE = 'https://w3id.org/atomgraph/client#ReadMode';
export const EDIT_MODE = 'https://w3id.org/atomgraph/client#EditMode';
export const CONTENT_MODE = 'https://w3id.org/atomgraph/linkeddatahub#ContentMode';
export const MAP_MODE = 'https://w3id.org/atomgraph/client#MapMode';
export const CHART_MODE = 'https://w3id.org/atomgraph/client#ChartMode';
export const GRAPH_MODE = 'https://w3id.org/atomgraph/client#GraphMode';

export const inMode = (uri, mode) => `${uri}?mode=${encodeURIComponent(mode)}`;
