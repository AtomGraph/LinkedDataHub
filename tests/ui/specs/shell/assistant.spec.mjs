// The assistant: a request in words becomes a plan, and the plan runs only when the reader says so.
//
// A conversation is a block. An ldh:Chat resource is placed in a document by an object block, like a
// view or a chart, and its turns are ldh:ChatTurn resources, its rdf:_N members. So a page holds as
// many conversations as it has chat blocks, a conversation is there when the reader comes back, and
// each chat block ends in its own composer. The create bar's Assistant button starts a new chat
// block before the bar; nothing is written until its first question, which writes the chat and the
// block that places it. Every turn is written when it ends, and the block draws its turns from the
// store whenever it is rendered.
//
// Most of what follows needs no model: a chat is seeded with the CLI, and the plan service is
// answered by the spec where only the exchange matters - a reply that declines in words is a whole
// turn, and the request carries the history the conversation sends. The last specs need the
// web-algebra service and a model key behind it; what they assert is the shape of the exchange, not
// the model's wording, and their requests are ones the ldh-* family answers with one operation.
import { randomUUID } from 'node:crypto';
import { test, expect } from '../../lib/console.mjs';
import { goto } from '../../lib/settle.mjs';
import { ldh } from '../../lib/fixtures.mjs';
import { adminBase, endUserBase } from '../../lib/stack.mjs';
import { CONTENT_MODE, inMode } from '../../lib/mode.mjs';

const WA = 'https://w3id.org/atomgraph/web-algebra';
const SEEDED_QUESTION = 'Which titles are in the seeded chat?';
const SEEDED_ANSWER = 'Two titles: Seeded alpha and Seeded beta.';
const DECLINED = 'Declined by the spec.';

// A container of this spec's own under the root: the plans create documents, and nothing counts the
// root's children. The spec removes what it made.
const scratch = { container: null, written: [], authorization: null };

test.beforeEach(async () => {
    const slug = `assistant-${randomUUID().slice(0, 8)}`;
    scratch.container = (await ldh(['create', 'container', '--parent', endUserBase, '--title', 'Assistant spec', '--slug', slug])).stdout;
    scratch.written = [];
    scratch.authorization = null;
});

test.afterEach(async () => {
    for (const uri of scratch.written) await ldh(['delete', uri], { allowFailure: true });
    if (scratch.container) await ldh(['delete', scratch.container], { allowFailure: true });
    if (scratch.authorization) await ldh(['delete', scratch.authorization], { allowFailure: true });
});

// A stored chat with one read-only turn that returned two rows: placed by an object block, which the
// CLI appends as the document's next rdf:_N, and described by one POST of the chat and its turn
async function seedChat(doc, name = 'seeded') {
    const chat = `${doc}#${name}-chat`;
    const turn = `${doc}#${name}-turn-1`;
    await ldh(['add', 'object-block', '--title', `${name} block`, '--uri', `#${name}-block`, '--value', chat, doc]);
    const plan = `<wa:plan xmlns:wa="${WA}"><wa:summary>Lists the titles</wa:summary><SELECT xmlns="${WA}"><endpoint>${endUserBase}sparql</endpoint><query>SELECT ?title WHERE { GRAPH ?g { ?s &lt;http://purl.org/dc/terms/title&gt; ?title } } LIMIT 2</query></SELECT></wa:plan>`;
    const execution = `<wa:execution xmlns:wa="${WA}"><wa:status>complete</wa:status><wa:steps><wa:step operation="SELECT" depth="0" outcome="complete" elapsed="120"/></wa:steps><wa:result><sparql xmlns="http://www.w3.org/2005/sparql-results#"><head><variable name="title"/></head><results><result><binding name="title"><literal>Seeded alpha</literal></binding></result><result><binding name="title"><literal>Seeded beta</literal></binding></result></results></sparql></wa:result></wa:execution>`;
    const turtle = `@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix ldh: <https://w3id.org/atomgraph/linkeddatahub#> .
@prefix dct: <http://purl.org/dc/terms/> .
<${chat}> a ldh:Chat ; dct:title "Seeded chat" ; rdf:_1 <${turn}> .
<${turn}> a ldh:ChatTurn ;
    ldh:question "${SEEDED_QUESTION}" ;
    ldh:answer "${SEEDED_ANSWER}" ;
    ldh:plan """${plan}"""^^rdf:XMLLiteral ;
    ldh:execution """${execution}"""^^rdf:XMLLiteral ;
    ldh:outcome "2 rows" .
`;
    await ldh(['post', '--content-type', 'text/turtle', doc], { stdin: turtle });
    return chat;
}

const content = page => page.locator('.ldh-pane.is-active .content-body');
const dock = page => content(page).locator('> .ldh-create-dock');
const button = page => dock(page).locator('.ldh-chat-open');
const chatOf = (page, uri) => page.locator(`.ldh-chat[data-chat="${uri}"]`);
const ephemeral = page => content(page).locator('> .ldh-chat-ephemeral');
const composer = chat => chat.locator('> form.ldh-chat-composer textarea');
const cards = chat => chat.locator('.ldh-chat-log > .ldh-chat-plan');

// the plan service answered by the spec: it declines in words, which is a whole turn, and the request
// is kept so the history it carried can be read
async function declinePlans(page) {
    const requests = [];
    await page.route(/\/webalgebra\/plans$/, async route => {
        requests.push(route.request().postDataJSON());
        await route.fulfill({ status: 200, contentType: 'application/xml', body: `<wa:plan xmlns:wa="${WA}"><wa:message>${DECLINED}</wa:message></wa:plan>` });
    });
    return requests;
}

const stored = async doc => (await ldh(['get', '--accept', 'text/turtle', doc])).stdout;

test('the Assistant button starts a chat block with its own composer, and nothing is written until a question', { tag: '@owner' }, async ({ page }) => {
    await goto(page, inMode(scratch.container, CONTENT_MODE));

    // the bar holds the button and nothing else of the assistant's
    await expect(dock(page).locator('form')).toHaveCount(0);
    await button(page).click();

    // a chat block before the bar, headed as a block is, ending in its own composer, which takes the focus
    await expect(ephemeral(page)).toHaveCount(1);
    await expect(content(page).locator('> .ldh-chat-ephemeral + .ldh-create-dock')).toHaveCount(1);
    const first = ephemeral(page).nth(0).locator('.ldh-chat');
    await expect(first.locator('> form.ldh-chat-composer')).toBeVisible();
    await expect(composer(first)).toBeFocused();
    await expect(ephemeral(page).locator('.ldh-block-head .ttl')).toHaveText(/\S/);

    // every press starts another
    await button(page).click();
    await expect(ephemeral(page)).toHaveCount(2);
    const second = ephemeral(page).nth(1).locator('.ldh-chat');
    await expect(composer(second)).toBeFocused();
    expect(await first.getAttribute('data-chat')).not.toBe(await second.getAttribute('data-chat'));

    // one nothing was asked in goes with Escape from its composer, or with its x
    await composer(second).press('Escape');
    await expect(ephemeral(page)).toHaveCount(1);
    await ephemeral(page).locator('.ldh-chat-close').click();
    await expect(ephemeral(page)).toHaveCount(0);

    // and none of it reached the document
    expect(await stored(scratch.container)).not.toContain('linkeddatahub#Chat');
});

test('a stored chat draws its turns, continues with its own history, and stores the new turn', { tag: '@owner' }, async ({ page }) => {
    const chatUri = await seedChat(scratch.container);
    const requests = await declinePlans(page);
    await goto(page, inMode(scratch.container, CONTENT_MODE));

    // the turn as it was stored: the question, the answer first on its card, the trace folded under its count and
    // gone green, and the rows it returned in a well
    const chat = chatOf(page, chatUri);
    await expect(chat.locator('.ldh-chat-turn')).toHaveText([SEEDED_QUESTION], { timeout: 30_000 });
    const card = cards(chat).first();
    await expect(card.locator('> :first-child')).toHaveClass(/ldh-chat-answer/);
    await expect(card.locator('.ldh-chat-answer')).toHaveText(SEEDED_ANSWER);
    const trace = card.locator('details.ldh-chat-trace');
    await expect(trace).not.toHaveAttribute('open', '');
    await expect(trace.locator('> summary')).toContainText(/1 steps/);
    await expect(trace.locator('> summary > .st.is-done')).toBeVisible();
    await expect(card.locator('.ldh-chat-result-block table')).toContainText('Seeded alpha');
    await expect(card.locator('.ldh-chat-result-block table')).toContainText('Seeded beta');
    // the trace's row folds out the stored plan's XML
    await trace.locator('> summary').click();
    const step = card.locator('.ldh-chat-step.is-done').first();
    await step.locator('summary').click();
    await expect(step.locator('pre')).toContainText(WA);

    // the block ends in its own composer
    await expect(composer(chat)).toBeEnabled();

    // a follow-up is sent with the stored turn as its history: the question, the plan it became and its rows
    await composer(chat).fill('And how many are there?');
    await composer(chat).press('Enter');
    await expect(cards(chat).last().locator('.ldh-chat-answer')).toHaveText(DECLINED, { timeout: 30_000 });
    expect(requests).toHaveLength(1);
    expect(requests[0].history.map(turn => turn.question)).toEqual([SEEDED_QUESTION]);
    expect(requests[0].history[0].plan).toContain('SELECT');
    expect(requests[0].history[0].result).toContain('Seeded alpha');

    // and the new turn is written to the chat as its second member
    await expect.poll(() => stored(scratch.container), { timeout: 30_000 }).toContain(DECLINED);
    await expect(cards(chat).last()).toHaveAttribute('data-turn', /#turn-/);

    // leave the page and come back: the conversation is there, both turns, and it continues
    await goto(page, endUserBase);
    await page.goBack();
    const back = chatOf(page, chatUri);
    await expect(back.locator('.ldh-chat-turn')).toHaveText([SEEDED_QUESTION, 'And how many are there?'], { timeout: 30_000 });
    await expect(cards(back).last().locator('.ldh-chat-answer')).toHaveText(DECLINED);
    await expect(composer(back)).toBeEnabled();
});

test('a step shows the value it resolved to, and the operation around it shows the call resolved', { tag: '@owner' }, async ({ page }) => {
    // a SELECT whose query a SPARQLString wrote, and the step reports carrying what it wrote
    const chat = `${scratch.container}#resolved-chat`;
    const turn = `${scratch.container}#resolved-turn-1`;
    const generated = 'SELECT ?title WHERE { GRAPH ?g { ?s <http://purl.org/dc/terms/title> ?title } }';
    await ldh(['add', 'object-block', '--title', 'resolved block', '--uri', '#resolved-block', '--value', chat, scratch.container]);
    const plan = `<wa:plan xmlns:wa="${WA}"><wa:summary>Lists the titles</wa:summary><SELECT xmlns="${WA}"><endpoint>${endUserBase}sparql</endpoint><query><SPARQLString><endpoint>${endUserBase}sparql</endpoint><question>Which titles are there?</question></SPARQLString></query></SELECT></wa:plan>`;
    const escaped = generated.replace(/</g, '&lt;').replace(/>/g, '&gt;');
    const execution = `<wa:execution xmlns:wa="${WA}"><wa:status>complete</wa:status><wa:steps><wa:step operation="SELECT" depth="0" outcome="complete" elapsed="900"/><wa:step operation="SPARQLString" depth="1" outcome="complete" elapsed="800"><wa:value>${escaped}</wa:value></wa:step></wa:steps></wa:execution>`;
    await ldh(['post', '--content-type', 'text/turtle', scratch.container], { stdin: `@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix ldh: <https://w3id.org/atomgraph/linkeddatahub#> .
<${chat}> a ldh:Chat ; rdf:_1 <${turn}> .
<${turn}> a ldh:ChatTurn ; ldh:question "Which titles are there?" ; ldh:outcome "executed" ;
    ldh:plan """${plan}"""^^rdf:XMLLiteral ;
    ldh:execution """${execution}"""^^rdf:XMLLiteral .
` });
    await goto(page, inMode(scratch.container, CONTENT_MODE));

    const card = cards(chatOf(page, chat)).first();
    await card.locator('details.ldh-chat-trace > summary').click();
    const [select, sparqlString] = [card.locator('.ldh-chat-step').nth(0), card.locator('.ldh-chat-step').nth(1)];
    await expect(select.locator('.op')).toHaveText('SELECT');
    await expect(sparqlString.locator('.op')).toHaveText('SPARQLString');

    // the SELECT as it ran: the query it executed where the call was
    await select.locator('> summary').click();
    // (as XML, so the query's angle brackets are escaped), declaring no namespace the plan did not use
    await expect(select.locator('> .ac-codefield pre')).toContainText(escaped);
    await expect(select.locator('> .ac-codefield pre')).not.toContainText('SPARQLString');
    await expect(select.locator('> .ac-codefield pre')).not.toContainText('xmlns:j.');

    // the SPARQLString as written, and what it resolved to
    await sparqlString.locator('> summary').click();
    await expect(sparqlString.locator('> .ac-codefield pre').first()).toContainText('<question>Which titles are there?</question>');
    await expect(sparqlString.locator('> .ldh-chat-plan-meta')).toHaveText(/\S/);
    await expect(sparqlString.locator('> .ac-codefield pre').last()).toHaveText(generated);
});

test('a plan that shows a grid draws its graph as cards with their images, also from the store', { tag: '@owner' }, async ({ page }) => {
    // the plan service answered by the spec: a CONSTRUCT shown as a grid, and its graph of two depicted resources
    const AC = 'https://w3id.org/atomgraph/client#';
    const plan = `<wa:plan xmlns:wa="${WA}"><wa:summary>Shows two presidents with their portraits.</wa:summary><wa:present xmlns:ac="${AC}" ac:mode="${AC}GridMode"/><wa:operations><wa:operation name="CONSTRUCT"/></wa:operations><CONSTRUCT xmlns="${WA}"><endpoint>https://query.wikidata.org/sparql</endpoint><query>CONSTRUCT { ?p &lt;http://xmlns.com/foaf/0.1/depiction&gt; ?image } WHERE { ?p &lt;http://www.wikidata.org/prop/direct/P18&gt; ?image } LIMIT 2</query></CONSTRUCT></wa:plan>`;
    const people = [['Q76', 'Barack Obama'], ['Q207', 'George W. Bush']];
    const graph = `<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:foaf="http://xmlns.com/foaf/0.1/">${people.map(([q, name]) =>
        `<rdf:Description rdf:about="http://www.wikidata.org/entity/${q}"><rdfs:label>${name}</rdfs:label><foaf:depiction rdf:resource="https://images.example/${q}.svg"/></rdf:Description>`).join('')}</rdf:RDF>`;
    const execution = `<wa:execution xmlns:wa="${WA}"><wa:id>grid</wa:id><wa:status>complete</wa:status><wa:steps><wa:step operation="CONSTRUCT" depth="0" outcome="complete" elapsed="300"/></wa:steps><wa:result>${graph}</wa:result></wa:execution>`;
    await page.route(/\/webalgebra\/plans$/, route => route.fulfill({ status: 200, contentType: 'application/xml', body: plan }));
    await page.route(/\/webalgebra$/, route => route.fulfill({ status: 202, contentType: 'application/xml', body: `<wa:execution xmlns:wa="${WA}"><wa:id>grid</wa:id></wa:execution>` }));
    await page.route(/\/webalgebra\/grid\/result$/, route => route.fulfill({ status: 200, contentType: 'application/xml', body: execution }));
    await page.route(/\/webalgebra\/answers$/, route => route.fulfill({ status: 200, contentType: 'application/xml', body: `<wa:answer xmlns:wa="${WA}">Two presidents, with their portraits.</wa:answer>` }));
    await page.route(/^https:\/\/images\.example\//, route => route.fulfill({ status: 200, contentType: 'image/svg+xml', body: '<svg xmlns="http://www.w3.org/2000/svg" width="4" height="4"/>' }));
    // the cards' labels: the view's metadata lookups against Wikidata, answered empty
    await page.route(/query\.wikidata\.org/, route => route.fulfill({ status: 200, contentType: 'application/rdf+xml', body: '<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"/>' }));

    await goto(page, inMode(scratch.container, CONTENT_MODE));
    await button(page).click();
    const chatUri = await ephemeral(page).locator('.ldh-chat').getAttribute('data-chat');
    await composer(chatOf(page, chatUri)).fill('Show the latest presidents with images');
    await composer(chatOf(page, chatUri)).press('Enter');

    const grid = card => card.locator(`.ldh-chat-result-block[data-mode="${AC}GridMode"] ul.ldh-grid-block`);
    const assertCards = async card => {
        await expect(grid(card).locator('a.card')).toHaveCount(2, { timeout: 30_000 });
        for (const [q, name] of people)
            await expect(grid(card).locator(`a.card[title="http://www.wikidata.org/entity/${q}"] .img img`)).toHaveAttribute('src', `https://images.example/${q}.svg`);
        await expect(card.locator('.ldh-chat-result-block .ldh-block-head .ttl')).toHaveText(/\S/);
    };
    await assertCards(cards(chatOf(page, chatUri)).last());
    await expect(cards(chatOf(page, chatUri)).last()).toHaveAttribute('data-turn', /#turn-/, { timeout: 30_000 });

    // stored with its plan, the hint included, the turn draws the same grid again
    await page.reload();
    await assertCards(cards(chatOf(page, chatUri)).last());
});

test('a plan that shows a timeline draws each row as a span, the one still under way included', { tag: '@owner' }, async ({ page }) => {
    const AC = 'https://w3id.org/atomgraph/client#';
    const LDH = 'https://w3id.org/atomgraph/linkeddatahub#';
    const XSD = 'http://www.w3.org/2001/XMLSchema#';
    const plan = `<wa:plan xmlns:wa="${WA}"><wa:summary>Shows the latest presidents' terms.</wa:summary><wa:present xmlns:ac="${AC}" xmlns:ldh="${LDH}" ac:mode="${AC}ChartMode" ldh:chartType="${AC}Timeline" ldh:categoryVarName="name" ldh:seriesVarName="start until"/><wa:operations><wa:operation name="SELECT"/></wa:operations><SELECT xmlns="${WA}"><endpoint>https://query.wikidata.org/sparql</endpoint><query>SELECT ?name ?start (COALESCE(?end, NOW()) AS ?until) WHERE { ?p &lt;http://example.org/name&gt; ?name ; &lt;http://example.org/start&gt; ?start . OPTIONAL { ?p &lt;http://example.org/end&gt; ?end } } ORDER BY ?start</query></SELECT></wa:plan>`;
    // the last term has no end of its own: COALESCE gave it the time of the query
    const terms = [['Barack Obama', '2009-01-20T00:00:00Z', '2017-01-20T00:00:00Z'], ['Joe Biden', '2021-01-20T00:00:00Z', '2025-01-20T00:00:00Z'], ['Donald Trump', '2025-01-20T00:00:00Z', '2026-10-04T12:00:00.000Z']];
    const literal = value => `<literal datatype="${XSD}dateTime">${value}</literal>`;
    const rows = terms.map(([name, start, until]) => `<result><binding name="name"><literal xml:lang="en">${name}</literal></binding><binding name="start">${literal(start)}</binding><binding name="until">${literal(until)}</binding></result>`).join('');
    const results = `<sparql xmlns="http://www.w3.org/2005/sparql-results#"><head><variable name="name"/><variable name="start"/><variable name="until"/></head><results>${rows}</results></sparql>`;
    const execution = `<wa:execution xmlns:wa="${WA}"><wa:id>timeline</wa:id><wa:status>complete</wa:status><wa:steps><wa:step operation="SELECT" depth="0" outcome="complete" elapsed="300"/></wa:steps><wa:result>${results}</wa:result></wa:execution>`;
    await page.route(/\/webalgebra\/plans$/, route => route.fulfill({ status: 200, contentType: 'application/xml', body: plan }));
    await page.route(/\/webalgebra$/, route => route.fulfill({ status: 202, contentType: 'application/xml', body: `<wa:execution xmlns:wa="${WA}"><wa:id>timeline</wa:id></wa:execution>` }));
    await page.route(/\/webalgebra\/timeline\/result$/, route => route.fulfill({ status: 200, contentType: 'application/xml', body: execution }));
    await page.route(/\/webalgebra\/answers$/, route => route.fulfill({ status: 200, contentType: 'application/xml', body: `<wa:answer xmlns:wa="${WA}">Three terms.</wa:answer>` }));

    await goto(page, inMode(scratch.container, CONTENT_MODE));
    await button(page).click();
    const chatUri = await ephemeral(page).locator('.ldh-chat').getAttribute('data-chat');
    await composer(chatOf(page, chatUri)).fill('Who were the latest presidents, and when?');
    await composer(chatOf(page, chatUri)).press('Enter');

    // a chart well, and in its canvas Google's timeline: one labelled row per term, each with its bar
    const card = cards(chatOf(page, chatUri)).last();
    const canvas = card.locator(`.ldh-chat-result-block[data-mode="${AC}ChartMode"] .ldh-chat-chart`);
    await expect(canvas.locator('svg')).toBeVisible({ timeout: 30_000 });
    for (const [name] of terms) await expect(canvas.locator('svg text', { hasText: name })).toHaveCount(1);
    await expect(canvas.locator('svg rect[stroke]')).not.toHaveCount(0);
});

test('two chat blocks on one page are independent, and the first question writes a new one', { tag: '@owner' }, async ({ page }) => {
    const seeded = await seedChat(scratch.container);
    const requests = await declinePlans(page);
    await goto(page, inMode(scratch.container, CONTENT_MODE));
    await expect(chatOf(page, seeded).locator('.ldh-chat-turn')).toHaveCount(1, { timeout: 30_000 });

    await button(page).click();
    // addressed by its chat: the draft's class goes once the first question writes it
    const chatUri = await ephemeral(page).locator('.ldh-chat').getAttribute('data-chat');
    const chat = chatOf(page, chatUri);
    await composer(chat).fill('A question for the new chat');
    await composer(chat).press('Enter');

    // the turn lands in the block it was asked in, and only there
    await expect(cards(chat).last().locator('.ldh-chat-answer')).toHaveText(DECLINED, { timeout: 30_000 });
    await expect(chat.locator('.ldh-chat-turn')).toHaveText(['A question for the new chat']);
    await expect(chatOf(page, seeded).locator('.ldh-chat-turn')).toHaveText([SEEDED_QUESTION]);
    // with a history of its own, which is none
    expect(requests).toHaveLength(1);
    expect(requests[0].history).toEqual([]);

    // asking made the block the document's: written, a member of the document, no longer closable as a draft
    const block = content(page).locator('> .ldh-block-row').filter({ has: chatOf(page, chatUri) });
    await expect(block).toHaveAttribute('about', /#block-/);
    await expect(block).not.toHaveClass(/ldh-chat-ephemeral/);
    await expect(block.locator('.ldh-chat-close')).toHaveCount(0);
    await expect.poll(() => stored(scratch.container), { timeout: 30_000 }).toContain('A question for the new chat');

    // drawn again from the store, the page has both conversations, each with its own turns and composer
    await page.reload();
    await expect(chatOf(page, chatUri).locator('.ldh-chat-turn')).toHaveText(['A question for the new chat'], { timeout: 30_000 });
    await expect(chatOf(page, seeded).locator('.ldh-chat-turn')).toHaveText([SEEDED_QUESTION]);
    await expect(page.locator('.ldh-chat > form.ldh-chat-composer')).toHaveCount(2);
});

test('a reader who may not append sees the transcript and nothing to type into', async ({ page }, testInfo) => {
    test.skip(testInfo.project.name !== 'anonymous', 'the claim is about holding no certificate');
    const chatUri = await seedChat(scratch.container);
    const slug = `assistant-public-${randomUUID().slice(0, 8)}`;
    await ldh(['admin', 'create', 'authorization', '--label', 'Assistant spec public chat', '--slug', slug,
        '--agent-class', 'http://xmlns.com/foaf/0.1/Agent', '--to', scratch.container, '--read', adminBase]);
    scratch.authorization = `${adminBase}acl/authorizations/${slug}/`;

    await goto(page, inMode(scratch.container, CONTENT_MODE));
    const chat = chatOf(page, chatUri);
    await expect(chat.locator('.ldh-chat-turn')).toHaveText([SEEDED_QUESTION], { timeout: 30_000 });
    await expect(chat.locator('.ldh-chat-answer')).toHaveText(SEEDED_ANSWER);
    await expect(chat.locator('form.ldh-chat-composer')).toHaveCount(0);
    await expect(page.locator('.ldh-chat-open')).toHaveCount(0);
});

test('a question becomes a plan that waits for Execute, and Cancel takes it away', { tag: '@owner' }, async ({ page }) => {
    test.setTimeout(120_000);
    await goto(page, inMode(scratch.container, CONTENT_MODE));
    await button(page).click();
    const chat = chatOf(page, await ephemeral(page).locator('.ldh-chat').getAttribute('data-chat'));

    await composer(chat).fill('Create a child container titled Assistant test under this document');
    await composer(chat).press('Enter');
    await expect(chat.locator('.ldh-chat-turn').last()).toHaveText('Create a child container titled Assistant test under this document');

    // Execute by default is on, and this plan writes - a write waits for Execute whatever the checkbox says
    const card = cards(chat).last();
    await expect(chat.locator('.ldh-chat-run input')).toBeChecked();
    await expect(card.locator('.ldh-chat-execute')).toBeVisible({ timeout: 90_000 });
    await expect(card.locator('.ldh-chat-cancel')).toBeVisible();
    await expect(card.locator('details.ldh-chat-trace')).toHaveAttribute('open', '');
    const first = card.locator('.ldh-chat-steps .ldh-chat-step.is-planned').first();
    await first.locator('summary').click();
    await expect(first.locator('pre')).toContainText(WA);
    await expect(composer(chat)).toBeEnabled();

    // the card keeps its own plan; nothing ran
    const id = await card.getAttribute('id');
    expect(await page.evaluate(id => !!window.LinkedDataHub.chat[id], id)).toBe(true);
    await expect(card.locator('.ldh-chat-step.is-done, .ldh-chat-step.is-failed, .ldh-chat-step.is-running')).toHaveCount(0);

    // Cancel takes the card and its plan away
    await card.locator('.ldh-chat-cancel').click();
    await expect(cards(chat)).toHaveCount(0);
    expect(await page.evaluate(id => id in window.LinkedDataHub.chat, id)).toBe(false);
});

test('Execute runs the plan, reports what it wrote, and the stored turn comes back with the block', { tag: '@owner' }, async ({ page }) => {
    test.setTimeout(240_000);
    await goto(page, inMode(scratch.container, CONTENT_MODE));
    await button(page).click();
    const chatUri = await ephemeral(page).locator('.ldh-chat').getAttribute('data-chat');
    const chat = chatOf(page, chatUri);

    await composer(chat).fill('Create a child container titled Assistant run under this document');
    await composer(chat).press('Enter');
    await expect(cards(chat).last().locator('.ldh-chat-execute')).toBeVisible({ timeout: 90_000 });
    await cards(chat).last().locator('.ldh-chat-execute').click();

    // the steps end one way or the other; this one wrote one document under this container
    const rows = cards(chat).last().locator('.ldh-chat-step');
    await expect(rows.first()).toHaveClass(/is-done|is-failed/, { timeout: 120_000 });
    await expect(cards(chat).last().locator('.ldh-chat-step.is-failed')).toHaveCount(0);
    const written = cards(chat).last().locator('.ldh-chat-docs a.iri');
    await expect(written).toHaveCount(1);
    const href = await written.getAttribute('href');
    scratch.written.push(href);
    expect(href.startsWith(scratch.container)).toBe(true);

    // once answered, the turn is stored and the page catches up with the write: the new child is listed, and the
    // chat block, drawn again from the store, holds the turn with its answer and the document it wrote
    await expect(page.locator(`.document-body a[href="${href}"]`).first()).toBeVisible({ timeout: 90_000 });
    const card = cards(chatOf(page, chatUri)).last();
    await expect(card).toHaveAttribute('data-turn', /#turn-/, { timeout: 30_000 });
    await expect(card.locator('.ldh-chat-answer')).not.toBeEmpty();
    await expect(card.locator('.ldh-chat-docs a.iri')).toHaveAttribute('href', href);
    await expect(card.locator('.ldh-chat-result-block')).toHaveCount(0);
    await expect(composer(chatOf(page, chatUri))).toBeEnabled();
});

test('a question is answered in words, with its result as a block in the card, also after a reload', { tag: '@owner' }, async ({ page }) => {
    test.setTimeout(300_000);
    for (const title of ['Answer alpha', 'Answer beta'])
        scratch.written.push((await ldh(['create', 'item', '--container', scratch.container, '--title', title, '--slug', title.toLowerCase().replace(' ', '-')])).stdout);
    await goto(page, inMode(scratch.container, CONTENT_MODE));
    await button(page).click();
    const chatUri = await ephemeral(page).locator('.ldh-chat').getAttribute('data-chat');
    const chat = chatOf(page, chatUri);

    await composer(chat).fill('List the titles of the documents in this container');
    await composer(chat).press('Enter');

    // a read-only plan runs on arrival; it ends in an answer, and its result sits in a well headed like a block
    await expect(cards(chat).last().locator('.ldh-chat-answer')).not.toBeEmpty({ timeout: 180_000 });
    await expect(cards(chat).last().locator('.ldh-chat-result-block').first()).toBeVisible();
    await expect(cards(chat).last()).toHaveAttribute('data-turn', /#turn-/, { timeout: 30_000 });

    // the same turn, drawn from the store
    await page.reload();
    const card = cards(chatOf(page, chatUri)).last();
    await expect(card.locator('.ldh-chat-answer')).not.toBeEmpty({ timeout: 30_000 });
    await expect(card.locator('.ldh-chat-result-block .ldh-block-head .ttl').first()).not.toBeEmpty();
});
