# ldh — Claude Code plugin for LinkedDataHub

Skills that teach Claude Code to build on [LinkedDataHub](https://github.com/AtomGraph/LinkedDataHub) with the
`ldh` command line interface: provision a dataspace, model and load data, build an app, and write a reusable
package.

## Install

In Claude Code:

```
/plugin marketplace add AtomGraph/LinkedDataHub
/plugin install ldh@linkeddatahub
```

You need a LinkedDataHub instance (or a checkout to run one from), the owner's WebID certificate, and the `ldh`
CLI (`make cli` in this repository).

## Data handling

The plugin runs no service of its own and sends nothing to AtomGraph. Its skills have the agent run the `ldh`
CLI, which sends requests only to:

- the LinkedDataHub instance named in `LDH_BASE`, authenticated with the user's WebID client certificate
  (`LDH_CERT_FILE`, `LDH_CERT_PASSWORD`);
- a package registry the user names, when publishing or importing a package (`ldh:package`).

What is sent is the data the user asks the agent to load: documents, ontologies, imported CSV and RDF. It stays on
those instances, under their operators' control. See also [PRIVACY.md](PRIVACY.md).

## Skills

Claude loads a skill on its own when your request matches what the skill covers, so you don't need to name it.
To call one explicitly, use `/ldh:<name>`.

| Skill | Covers |
|---|---|
| `ldh:dataspace` | Provisioning a new dataspace on a self-hosted instance: the configuration files, the restart, and checking that it is up |
| `ldh:dataset` | The namespace ontology (classes, constructors, constraints, property views) and its install; CSV and RDF imports; federation with remote SPARQL endpoints; building a large dataset standalone from CSV, JSON or XML and bulk-loading it |
| `ldh:app` | Documents, blocks, views and charts, and an app kept as a directory and installed with `ldh push` |
| `ldh:package` | A reusable package: an ontology plus an XSLT stylesheet that customises rendering, published to a registry and imported with `ldh packages add` |

## Example requests

Ask the way you would ask a colleague. A request can span several skills, and Claude uses them in turn.

**Dataspace**

> Add a dataspace called inventory to my local LinkedDataHub.

**Dataset**

> Here are products.csv and categories.csv. Model them with schema.org, import them into the inventory dataspace,
> and make each category's page list its products.

> This 2 GB XML dump of the company register is too big to import through the API. Turn it into a dataset that
> follows LinkedDataHub's conventions and bulk-load it.

**App**

> In this folder, set up a local LinkedDataHub and make a "library" dataspace for a book catalogue from the CSVs
> in ./data (books reference authors by authorId): a page with the books as a table, a page with the authors, a
> chart of books per author, and each author's page showing their books.

**Package**

> Write a reusable package that renders schema:ratingValue values as stars, publish it to a package registry
> hosted on my instance, and import it into the inventory dataspace.

## Versioning

The plugin's version follows the platform's: `release.sh` and `make cli-version` set
`.claude-plugin/plugin.json` along with the `rdf/` and `cli/` poms. A change to the CLI's options or to the
configuration the skills quote updates the skills in the same commit.
