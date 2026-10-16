---
name: dataspace
description: Provision a new LinkedDataHub dataspace on a self-hosted instance — an end-user app and its admin app on their own subdomain, each backed by its own Fuseki dataset. Use when the task is to add, rename or rewire a dataspace in config/dataspaces.trig, config/system.trig and config/fuseki/config.ttl. Not for adding data or UI to an existing dataspace (use ldh:dataset and ldh:app).
---

# Provision a LinkedDataHub dataspace

A **dataspace** is a pair of applications on one origin: the end-user app at `https://<name>.<host>/`
and its admin app at `https://admin.<name>.<host>/` (always the `admin.` subdomain prefix, never an
`/admin` path). Each app is backed by a SPARQL service, by default a TDB2 dataset in the instance's
single Fuseki server. The admin app holds the dataspace's ontologies and access control; the
end-user app holds its documents.

Dataspace configuration is **file-based and read at startup**. There is no `ldh` command and no
HTTP request that creates one. You need shell access to the deployment (the LinkedDataHub
checkout its `docker-compose.yml` runs from). On a hosted instance you cannot provision a dataspace;
ask its operator.

Reference: https://docs.linkeddatahub.com/user-guide/manage-dataspaces/ and
https://docs.linkeddatahub.com/reference/configuration/

## Ground rules shared with the other ldh skills

- Every document is a named graph whose name is the document URL; the default graph is empty.
- A document is not the thing it describes: the described resource is `<doc#this>`, linked with
  `foaf:primaryTopic`.
- `ldh` reads `LDH_BASE`, `LDH_CERT_FILE`, `LDH_CERT_PASSWORD` and `LDH_PROXY` from the
  environment. Commands that create a document print its URL as the only stdout line.
- **Use an `ldh` that matches the instance.** Build it from the same LinkedDataHub checkout or release
  as the running image (`ldh --version`). An instance whose end-user responses carry no
  `https://w3id.org/atomgraph/linkeddatahub/dataspaces#admin` `Link` (check with `ldh get --head --accept text/turtle "$LDH_BASE"`)
  predates the CLI's admin discovery. There, `ldh admin` commands answer `403` for the end-user base,
  and `import ontology --file` refuses it. Use the image built from the same checkout as the CLI.

## Steps

Pick a name, e.g. `inventory`. With the instance host `localhost` and port `4443`, the origins are
`https://inventory.localhost:4443` and `https://admin.inventory.localhost:4443`, and the Fuseki
datasets are named after the origin with the deployment host dropped and the role appended:
`inventory.end-user` and `inventory.admin`.

Read the existing entries in each file first and copy their shape exactly. The root dataspace and
any demo dataspace already present are the templates.

### 1. `config/dataspaces.trig` — public metadata

One named graph per app, identified by a `urn:` URI (never a blank node):

```trig
<urn:linkeddatahub:apps/inventory/admin>
{
    <urn:linkeddatahub:apps/inventory/admin> a lds:Dataspace ;
        dct:title "Inventory admin" ;
        lds:origin <https://admin.inventory.localhost:4443> ;
        lds:ontology <https://w3id.org/atomgraph/linkeddatahub/admin#> ;
        ac:stylesheet <https://admin.inventory.localhost:4443/static/xsl/admin/layout.xsl> .
}

<urn:linkeddatahub:apps/inventory/end-user>
{
    <urn:linkeddatahub:apps/inventory/end-user> a lds:Dataspace ;
        dct:title "Inventory" ;
        lds:origin <https://inventory.localhost:4443> ;
        lds:ontology <https://inventory.localhost:4443/ns#> ;
        ac:stylesheet <https://inventory.localhost:4443/static/xsl/layout.xsl> ;
        lds:public true .
}
```

- The end-user app's `lds:ontology` is its namespace ontology, `<origin>/ns#`. The admin app always
  uses the platform's admin ontology.
- `ac:stylesheet` must be an absolute URL on the app's own origin.
- `lds:public true` lists the dataspace publicly. It does not make documents readable; that is
  `ldh admin make-public` (see ldh:app).
- Admin/end-user pairing is inferred from the origins; there is nothing to declare.
- A package import can be made permanent here with `<urn:…/end-user> ldh:import <package#this>`.
  `ldh packages add` is the live route but does not survive a restart.

### 2. `config/fuseki/config.ttl` — the two datasets

Add a `fuseki:Service` and a `tdb2:DatasetTDB2` per role, copying an existing pair (keep the
`arq:queryTimeout` context on the query endpoint):

```turtle
<#inventory.end-user> a fuseki:Service ;
    fuseki:name "inventory.end-user" ;
    fuseki:endpoint [ fuseki:operation fuseki:query ; ja:context [ ja:cxtName "arq:queryTimeout" ; ja:cxtValue "60000" ] ] ;
    fuseki:endpoint [ fuseki:operation fuseki:update ] ;
    fuseki:endpoint [ fuseki:operation fuseki:gsp-rw ] ;
    fuseki:dataset <#inventory.end-user-dataset> .

<#inventory.end-user-dataset> a tdb2:DatasetTDB2 ;
    tdb2:location "/fuseki/databases/inventory.end-user/DB2" .
```

and the same for `inventory.admin`.

### 3. `config/system.trig` — internal wiring

Type each app and bind it to an `sd:Service` pointing at its dataset. This file is internal; never
publish it.

```trig
<urn:linkeddatahub:apps/inventory/end-user>
{
    <urn:linkeddatahub:apps/inventory/end-user> a lds:EndUserDataspace ;
        lds:service <urn:linkeddatahub:services/inventory/end-user> .
}

<urn:linkeddatahub:services/inventory/end-user>
{
    <urn:linkeddatahub:services/inventory/end-user> a sd:Service ;
        dct:title "Inventory service" ;
        sd:supportedLanguage sd:SPARQL11Query, sd:SPARQL11Update ;
        sd:endpoint <http://fuseki:3030/inventory.end-user/> ;
        a:graphStore <http://fuseki:3030/inventory.end-user/> ;
        a:quadStore <http://fuseki:3030/inventory.end-user/> .
}
```

and the same pair for the admin app with `lds:AdminDataspace` and `inventory.admin`.

Several dataspaces may share one service, but then they share one dataset and see each other's
documents. Give each dataspace its own pair unless that is the point.

### 4. Validate, then restart

```bash
riot --validate config/dataspaces.trig config/system.trig config/fuseki/config.ttl
```

A syntax error, or a dataspace with no matching service, stops the platform at startup.

The new datasets and apps only take effect after `fuseki` and `linkeddatahub` restart
(`docker compose restart fuseki linkeddatahub` from the checkout). **Restarting is the
operator's decision — ask before doing it**: it interrupts every dataspace on the instance, and it
drops package imports that were added live with `ldh packages add` rather than declared in
`dataspaces.trig`.

On first start the entrypoint seeds the new datasets: the root document, the namespace ontology, the
owner's and secretary's agent metadata and their authorizations. It does so only for an app whose
`/var/linkeddatahub/based-datasets/<origin-folder>` does not exist yet, so an existing dataspace is
never reseeded.

### 5. Verify

Wait for Tomcat's startup to finish (the root URL can answer from cache before it does), then:

```bash
export LDH_BASE=https://inventory.localhost:4443/
ldh get --accept text/turtle "$LDH_BASE"                          # the seeded root document
ldh get --accept text/turtle https://admin.inventory.localhost:4443/ontologies/namespace/
ldh get --accept text/turtle "${LDH_BASE}context"                 # every dataspace, public
```

All three answer `200` with RDF. `/context` lists every dataspace of the instance: its type, title,
origin and ontology, and `lds:admin` on each end-user dataspace, the admin base the server pairs it
with. If the new dataspace is missing there, the config was not loaded. If it has no `lds:admin`, its
admin origin is not the `admin.` subdomain of its end-user origin. The services and credentials from
`system.trig` and `secrets/` never appear in it. `*.localhost` resolves to the loopback address without a hosts entry;
any other host needs DNS (or `/etc/hosts`) for both subdomains. nginx routes every subdomain of the
host, so it needs no change.

## Pitfalls

- The configured origins must match `PROTOCOL`, `HOST` and `HTTPS_PORT` in `.env`. Changing the port
  in `.env` alone makes the platform exit with "Root end-user app with origin … not found".
- Use `urn:` URIs for apps and services. A blank node breaks the lookup.
- The server certificate from `bin/server-cert-gen.sh` names the base host only, so browsers warn on
  the new subdomains. `ldh` does not validate server certificates, so the CLI is unaffected.

## Next

The dataspace is empty apart from its root document. Model and load data with **ldh:dataset**,
then build the UI with **ldh:app**.
