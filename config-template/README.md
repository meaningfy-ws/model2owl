# config-template — model2owl configuration template

This folder is a **template** for configuring a model2owl transformation. Copy it, edit the
values to match your ontology, and point `config-proxy.xsl` (at the repo root) at the copied
`config-parameters.xsl` — or pass the individual files to the `make` targets via their
override variables (e.g. `NAMESPACES_USER_XML_FILE_PATH`, `IMPORTS_XML_FILE_PATH`,
`METADATA_JSON_PATH`). The default ePO configuration in `test/ePO-default-config/` is a
filled-in example of the same file set.

## Placeholders to replace

The files come pre-filled with dummy values for demonstration purposes. These act as
placeholders: replace each with the real value for your ontology. The table below lists
the recurring placeholder values and what each one stands for.

| Placeholder | Meaning |
|---|---|
| `http://example.org/ontology` | your ontology's base URI (terms become `…/ontology#YourClass`) |
| `myprefix` | the namespace prefix of your ontology's own concepts |
| `my-org/my-ontology`, `https://example.org/…` | your GitHub repo / project URLs |
| `My Ontology`, `My Organisation`, `My Model` | human-readable names shown in the artefacts/report |

Keep the empty (`""`) and `myprefix` entries in `namespaces.xml` aligned with
`base-ontology-uri` in `config-parameters.xsl`.

## The files

| File | What it configures |
|---|---|
| `config-parameters.xsl` | all transformation parameters (see groups below) |
| `metadata.json` | ontology header metadata + report/ReSpec presentation (see groups below) |
| `namespaces.xml` | prefix → namespace-URI mappings used to build and resolve term URIs |
| `imports.xml` | `owl:imports` added to the generated artefacts |
| `umlToXsdDataTypes.xml` | UML attribute type → XSD datatype mapping |
| `xsdAndRdfDataTypes.xml` | catalogue of XSD/RDF datatypes accepted in the output |

## `config-parameters.xsl` parameter groups

1. **Config-file references** — pointers to the sibling files above, including the overridable
   `metadataJsonPath` param (make targets: `METADATA_JSON_PATH`).
2. **Namespaces & URI construction** — base URIs, delimiter, `moduleReference`, derived artefact URIs.
3. **Scope / reused-concepts filtering** — `includedPrefixesList` (which concepts are "yours") and the `generateReusedConcepts*` toggles.
4. **Attribute → property typing** — which attribute types yield object vs datatype properties.
5. **Accepted UML stereotypes** — per element kind.
6. **Enumerations → SKOS** — whether enumeration items become `skos:Concept`/`ConceptScheme`.
7. **Tags, comments, references, status & `rdfs:isDefinedBy`** — tag keys for comments/notes/usage/status, ReSpec reference labels, status filtering, and the two `annotate…WithOntology` flags that switch `rdfs:isDefinedBy` on/off (OWL and SHACL).
8. **Output toggles & misc** — object/realisation generation, SHACL PlainLiteral handling, supported UML versions, issued date.

## `metadata.json` field groups

1. **Ontology identity & versioning** — titles/labels/descriptions, version, status, dates, preferred namespace, publisher, license.
2. **People** — `contributors`, `owners`.
3. **Links & resources** — see-also/changelog/feedback/repository links, `dependencies`, `localBiblio`, `projectLocalResources`.
4. **Convention report** — the `conventionReport*` fields shown on the convention report.
5. **Doc / ReSpec presentation** — `documentConfig`, `navigation`, `openGithubIssue`, `logo`.

All metadata fields are optional: a field left blank or removed is simply omitted from
the output (it does not fail the build).
