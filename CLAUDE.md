# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Project Is

**model2owl** is an XSLT 3.0-based transformation tool that converts UML conceptual models (exported as XMI 2.5.1 from Enterprise Architect) into formal semantic web artifacts: OWL 2 ontologies, SHACL data shapes, HTML glossaries, and compliance/convention reports. Its primary use case is the eProcurement Ontology (ePO) project by the Publications Office of the European Union.

**The core is not a Python project.** The transformation logic is XSLT; the global Meaningfy coding prompt's Python conventions (poetry, FastAPI, layered architecture, importlinter) do not apply to it. Python appears only in support scripts and the **functional test tier** (pytest-bdd — see Testing). Disregard Python *architecture* guidance for the transformation code.

## Critical: Do Not Read Large Files

Several file types are large data files that will overwhelm context. **Never read these in full:**
- `.xmi`, `.xml` — UML model exports (can be hundreds of MB)
- `.rdf`, `.ttl` — RDF ontology output files
- `.xlsx` — spreadsheet data

To enumerate files safely, use `git ls-files`. Many large files are untracked and not in `.gitignore`.

## Tech Stack

| Tool | Role |
|------|------|
| **XSLT 3.0** | Core transformation language — all business logic lives here |
| **XSpec 2.0** | XSLT unit testing framework |
| **Saxon HE 10.6** | XSLT 3.0 processor (downloaded by `make install`) |
| **Apache Maven** | Test orchestration via xspec-maven-plugin |
| **GNU Make** | Primary CLI for build, install, and all transformations |
| **Apache Jena / RIOT** | RDF validation and format conversion |
| **ROBOT** | OWL API wrapper for ontology format conversions |
| **Python / rdflib** | Support scripts for RDF serialization |

## Setup & Key Commands

```bash
make install          # One-time: downloads Saxon, ROBOT, Widoco, Jena, rdflib
make unit-tests       # Run all XSpec tests via Maven; JUnit XML → target/surefire-reports/
```

`make install` only fetches jars/tools — it assumes **Java 11+, Maven, Python 3, curl, and unzip** are already on PATH.

**Single test module** (there is no standalone `xspec` CLI installed here — runs go through Maven):
```bash
make unit-test-one MODULE=test-elements-owl-core   # bare name, no path/extension; prints a summary
make unit-tests INCLUDE='**/test-checkers.xspec,**/test-fetchers.xspec'   # a few modules
```
A selective run only refreshes its own reports, so `make test-summary` (run automatically after `make test` / `make unit-test-one`) scopes its 15-minute freshness window to just what you ran. See the `running-xspec-tests` skill.

**Transformations** (all require `config-proxy.xsl` to point to a valid config):
```bash
make owl-core XMI_INPUT_FILE_PATH=<path.xmi> OUTPUT_FOLDER_PATH=<output/>
make owl-restrictions XMI_INPUT_FILE_PATH=<path.xmi> OUTPUT_FOLDER_PATH=<output/>
make shacl XMI_INPUT_FILE_PATH=<path.xmi> OUTPUT_FOLDER_PATH=<output/>
make generate-convention-report XMI_INPUT_FILE_PATH=<path.xmi> OUTPUT_CONVENTION_REPORT_PATH=<output/>
make generate-glossary XMI_INPUT_FILE_PATH=<path.xmi> OUTPUT_GLOSSARY_PATH=<output/>
```

The Makefile has many more targets than shown above — JSON-LD context (`make generate-jsonld-context`), ReSpec (`make generate-respec`), RDF format conversions, `merge-owl-shacl`, and rdf-differ services. Treat the `Makefile` as the authoritative target list.

## Source Architecture

All transformation logic is in `src/`. The pattern is: **entry-point stylesheet → library modules → common utilities**.

```
src/
├── owl-core.xsl                   Entry: lightweight OWL ontology
├── owl-restrictions.xsl           Entry: heavyweight OWL + reasoning axioms
├── shacl-shapes.xsl               Entry: SHACL data shapes
├── html-conventions-report.xsl    Entry: HTML compliance report
├── svrl-conventions-report.xsl    Entry: SVRL compliance report
├── html-model-glossary.xsl        Entry: HTML glossary
├── jsonld-context.xsl             Entry: JSON-LD @context
├── rspec-json-generate.xsl        Entry: ReSpec JSON (+ rspec-cfg-json-generate.xsl)
│
├── common/                        Shared utilities imported by everything
│   ├── selectors.xsl              XPath selectors for UML element traversal
│   ├── checkers.xsl               Boolean validation predicates
│   ├── fetchers.xsl               Data extraction helpers
│   ├── formatters.xsl             Output formatting
│   └── functx-1.0.1-doc.xsl      Bundled third-party FunctX library — do not modify
│
├── owl-core-lib/                  Classes, datatypes, enumerations, connectors → OWL declarations
├── shacl-shape-lib/               Classes, connectors → SHACL NodeShapes/PropertyShapes
├── reasoning-layer-lib/           OWL restrictions and axioms
├── html-conventions-lib/          150+ convention checking templates
└── xml/                           Preprocessing: namespace enrichment, XMI merging, OWL catalog gen
```

`src/common/selectors.xsl` and `src/common/checkers.xsl` are imported by nearly every library module — they are the most central files in the codebase.

Other top-level dirs: `respec-resources/` & `glossary-resources/` (Jinja2 `.j2` templates for ReSpec/AsciiDoc output), `scripts/` (coverage + namespace helpers), `sync-repos.sh` (fork sync to GitHub/EC Bitbucket).

## Configuration System

**`config-proxy.xsl`** (repo root) is the configuration indirection layer. It imports the actual config file. Check its import path before running any transformation:

```xml
<!-- config-proxy.xsl -->
<xsl:import href="test/ePO-default-config/config-parameters.xsl"/>
```

The default config in `test/ePO-default-config/` contains:
- `config-parameters.xsl` — 100+ variables: base URIs, generation flags, filtering options
- `namespaces.xml` — all namespace prefix → URI mappings
- `umlToXsdDataTypes.xml` — UML type to XSD type mapping
- `xsdAndRdfDataTypes.xml` — XSD/RDF datatype catalog
- `metadata.json` — ontology header / report metadata

**metadata.json path — overridable via `METADATA_JSON_PATH`.** `config-parameters.xsl`
binds `$metadataJson` with `fn:json-doc($metadataJsonPath)`, where the `metadataJsonPath`
stylesheet param defaults to `'metadata.json'` (relative to the active config dir — so by
default `owl-core`, `owl-restrictions`, `shacl`, `generate-jsonld-context`, the convention
report, the glossary **and** ReSpec all read the active config's `metadata.json`). The
Makefile exposes a single `METADATA_JSON_PATH` variable that drives **all** of those
targets, so you can point them at a different metadata file without swapping the config
file: `make owl-core … METADATA_JSON_PATH=/abs/other-metadata.json`. When unset, behaviour
is unchanged (RDF/SHACL/etc. resolve metadata relative to the config; ReSpec falls back to
the ePO file). Pass an **absolute** path. (Historical note: this used to be hardcoded, with
only ReSpec overridable via the now-removed `RESPEC_METADATA_JSON_PATH`.)

This default config relates to e-Procurement ontology that is the main use case for this tool.

For a different project, create a new config directory and update the import in `config-proxy.xsl`. Never hardcode namespace URIs inside library XSLT files — all namespaces flow from config.

**A custom `namespaces.xml` must be wired in two places.** Pointing the config's
`$namespacePrefixes` (`fn:doc('namespaces.xml')`) at your file is **not enough**: generated
**term URIs** are resolved through the *enriched-namespaces* file, which `gen-enriched-ns-file`
builds from `NAMESPACES_USER_XML_FILE_PATH` (default = the ePO `namespaces.xml`). If you only
swap the config, the ontology IRI/`base-ontology-uri` uses your namespace but every class/property
URI still resolves via the **empty-prefix entry (`name=""`) of the default `namespaces.xml`**. So
pass `NAMESPACES_USER_XML_FILE_PATH=<your-namespaces.xml>` to the `make` targets too (the empty
prefix is what unprefixed model names resolve to). Related: `generate-respec` only regenerates
`*_respec.json` when it is **absent** (Makefile), so delete a stale one before re-running with a
changed config, or ReSpec will reuse the old URIs.

## Testing

Tests are in `test/unitTests/` and mirror `src/`:
- `test-common/` ↔ `src/common/`
- `test-owl-core-lib/` ↔ `src/owl-core-lib/`
- `test-shacl-shape-lib/` ↔ `src/shacl-shape-lib/`
- `test-reasoning-layer-lib/` ↔ `src/reasoning-layer-lib/`
- `test-html-conventions-lib/` ↔ `src/html-conventions-lib/`

XSpec tests reference real UML fixture models from `test/testData/*.xmi`. Each test calls XSLT templates with a selected UML node as context and asserts on generated XML output.

### Selecting fixture nodes: by label, not by position or idref

When pointing a test at a fixture node, select it by a **stable, human-readable label** — this is the convention for all new and edited tests.

RECOMMENDED — select by name:
- A class by its **name**: `…/elements/element[@name='epo:Buyer']`
  (real example: `test/unitTests/test-common/test-fetchers.xspec:350`, `element[@name='epo:Technique']`).
- A connector by the **names of the classes it relates** — match on `source/model/@name`, `target/model/@name`, or a `source/role/@name` / `target/role/@name` role name. The cleanest real example is the scenario *"association generalisation with identical source and target classes …"* in `test/unitTests/test-common/test-checkers.xspec:570-582`: it resolves the connector through `f:getSourceConnectorFromGeneralisation` / `f:getTargetConnectorFromGeneralisation` and predicates on `…/source/model/@name = 'epo:SubmissionStatisticalInformation'` etc., never on an idref.

ANTI-PATTERNS — do not introduce these (many existing tests still use them; treat that as legacy, not a model to copy):
- Positional indices, e.g. `…/connectors[1]/connector[27]` or `connector[453]` (real examples: `test/unitTests/test-common/test-checkers.xspec:238,248`). They break the moment a connector is added/removed or the export reorders nodes, and a reviewer cannot tell which model element is meant.
- Opaque EA identifiers, e.g. `xmi:idref="EAID_…"`. They are unreadable and are **not** guaranteed to survive a re-export of the UML model, making the test silently point at the wrong node — or nothing — after a model refresh.

Why labels win: a name-based selector is self-documenting (the reviewer sees `epo:Buyer`, not `connector[453]`), survives re-exports and reordering, and fails loudly (selects empty) rather than silently shifting to a different node.

### Reading test outcomes: trust the JUnit XML, not the exit code

`make unit-tests` (and `make test`) print `[INFO] BUILD SUCCESS` and return **exit code 0 even when XSpec assertions fail**. The Maven build "succeeds" as long as it ran the tests; assertion failures do not fail the build. **Never** judge pass/fail from the exit code or the `BUILD SUCCESS` line.

The authoritative result is the JUnit XML under `target/surefire-reports/*.xml` (one file per `.xspec`). Structure: a `<testsuites>` root wraps one `<testsuite name="…" tests="…" failures="N">` per scenario; each `<x:expect>` becomes a `<testcase name="…" status="passed|failed">`. A red test is:
- a `<testsuite … failures="N">` with **N>0**, and
- inside it a `<testcase name="…" status="failed">` containing `<failure message="expect assertion failed">Expected: …</failure>`.

Note attributes may wrap across lines and the wrapper is `<testsuites>`, so parse the XML rather than grepping a single line. Use the `reading-xspec-test-results` skill (`.claude/skills/reading-xspec-test-results/SKILL.md`) for a copy-paste command that lists every failing report file and each failed testcase with its message.

Worked example — a test that is RED while `make unit-tests` exited 0:
```xml
<testcase name="… valid (single boolean, no FORG0006) boolean-false" status="failed">
  <failure message="expect assertion failed">Expected: xs:boolean('false')</failure>
</testcase>
```
The build printed `BUILD SUCCESS` and returned 0, but this scenario failed — only the surefire XML reveals it.

`make unit-tests` automatically calls `make test-prerequisites` first, which generates `enriched-namespaces.xml` — a required preprocessing artifact. Never skip this step when running tests manually.

**Two test tiers.** `make test` runs both:
- `make unit-tests` — XSpec tests in `test/unitTests/` (above).
- `make functional-tests` — Python **pytest-bdd** in `test/functionalTests/` (glossary, jsonld-context), invoked via `mvn exec:exec@run-pytest`. Deps in `requirements-test.txt`. Coverage tooling lives in `scripts/coverage/`.

`test/` also holds large investigation/fixture trees (`reasoning-investigation/` ~940 files, `external-concepts-filters-testing/`) that are **not** unitTests — do not read these in bulk.

## Transformation Pipeline (Multi-Step)

Transformations are not single-pass:

1. **Namespace enrichment** — `src/xml/enriched-namespaces.xsl` augments the namespace registry
2. **XMI merging** (optional) — `src/xml/merge-multi-xmi.xsl` combines multiple UML model files
3. **Main transformation** — one of the six entry-point stylesheets
4. **Format conversion** — output passes through ROBOT/rdflib for RDF normalization


The `.tmp.rdf` file is the raw output of step 3 (the XSLT transformation) and the *input* to step 4; step 4 converts/normalizes it into the final `.rdf`/`.ttl`/`.owl`/`.jsonld`, then deletes the `.tmp.rdf`. So a leftover `.tmp.rdf` means step 4 did not complete.

**Invoking Saxon directly?** The `enrichedNamespacesPath` (and `importsPath`) stylesheet
params must be **absolute paths**. They are resolved relative to the *importing
stylesheet* (e.g. `src/common/utils.xsl`), not the repo root or the input file, so a
relative value like `.temp/enriched-namespaces.xml` fails with `FODC0002 ... No such file`
(Saxon looks under `src/common/.temp/...`). The `make` targets already pass absolute
paths; only hand-rolled `java -jar saxon.jar` calls hit this.

## Non-Obvious Design Decisions

- **Config-proxy indirection**: A single codebase serves multiple projects with different namespace configurations. All namespace and URI customization happens in project-specific config files, never in library XSLT.
- **Reused-concepts filtering**: Config flags like `$generateReusedConceptsOWLcore` filter out elements not in the project's own namespace. This is intentional — one combined multi-namespace UML model can produce scoped per-module artifacts.
- **OWL catalog workaround**: Some ePO/ADMS ontologies have broken `owl:imports` URIs. `robot-catalog.xsl` generates a ROBOT-compatible catalog file so ROBOT can still resolve and validate imports.

## Editorial content is mirrored in the docs repo — keep it in sync

Some **editorial / user-facing text is duplicated** between this codebase and the
documentation repo (`ted-model2owl-docs`, see Related Repositories). The clearest
example: every convention-check message and severity emitted from
`src/html-conventions-lib/**` (via `f:generateErrorMessage` / `…InfoMessage` /
`…WarningMessage`, each tagged with a rule ID) is mirrored, keyed by that rule ID, in
the docs table `modules/ROOT/pages/checkers/model2owl-checkers.adoc`. The
"unsupported UML constructs" warnings and the transformation-rule descriptions are
mirrored similarly. **Whenever you change such editorial text in the code (message
wording, severity, rule ID, short description), the corresponding docs entry must be
updated in the same change** — the two must never drift. The docs repo is the
published source of truth for these strings, so a stale message there is a real
defect, not a cosmetic one.

For any change that may touch this editorial code, use the
**`syncing-editorial-text-with-docs`** skill
(`.claude/skills/syncing-editorial-text-with-docs/SKILL.md`): it maps every linked
code↔docs place, and supports both the impact analysis (which docs entry a change
touches) and making the matching docs edit.

## The Makefile is a public interface consumed by the boilerplate CI

This repo's **`Makefile` is a contract**, not just local tooling. The
**model2owl-boilerplate** repo (see Related Repositories) clones model2owl in CI and
invokes its `make` targets — see `.github/workflows/transform_with_model2owl.yml`
(plus `diff-combined.yml`), which call targets like `owl-core`, `owl-restrictions`,
`shacl`, `gen-enriched-ns-file`, `generate-jsonld-context`, `generate-convention-report`,
`generate-glossary`, `respec-json`, `generate-respec`, `merge-xmi`, `merge-owl-shacl`,
`run-rdf-diff`, and pass arguments as `KEY=VALUE` overrides (e.g. `XMI_INPUT_FILE_PATH`,
`OUTPUT_FOLDER_PATH`, `NAMESPACES_USER_XML_FILE_PATH`, `IMPORTS_XML_FILE_PATH`,
`METADATA_JSON_PATH`, `RESPEC_OUTPUT_DIR`).

**So renaming/removing a target or an overridable `?=` variable is a BREAKING change to
that interface.** Worse, it fails **silently**: `make` ignores an unknown `KEY=VALUE`
argument, so the boilerplate CI keeps running but the affected step quietly reverts to a
default (this is exactly what happened when `RESPEC_METADATA_JSON_PATH` was replaced by
`METADATA_JSON_PATH` — the CI line set a dead variable and ReSpec fell back to the default
metadata). **Whenever you rename/remove/repurpose a target or a public variable, grep the
boilerplate workflows for the old name and update the callers in the same change** (the
boilerplate has no Makefile of its own; CI is the only caller).

The make targets and their parameters are also documented (keep these in sync too):
model2owl `README.md`, and the docs repo's `modules/ROOT/pages/user-guide/how-to-use.adoc`
(target list) and `configuration-file.adoc` (config parameters).

## Related Repositories

**Forking workflow:** the canonical upstreams live under the **`OP-TED`** org; the
**`meaningfy-ws`** org holds the forks where this work happens. This repo's
`origin` is the `meaningfy-ws` fork and `upstream` points at `OP-TED` — sync
fork ← upstream via the `upstream` remote.

- **model2owl** (this repo) — fork <https://github.com/meaningfy-ws/model2owl>, upstream <https://github.com/OP-TED/model2owl>.
- **ted-model2owl-docs** — fork <https://github.com/meaningfy-ws/ted-model2owl-docs>, upstream <https://github.com/OP-TED/ted-model2owl-docs>. AsciiDoc/Antora documentation; useful for transformation rules and UML modeling conventions. Treat as authoritative for current behavior, but it may be incomplete — cross-check against XSLT source.
- **model2owl-boilerplate** — fork <https://github.com/meaningfy-ws/model2owl-boilerplate>, upstream <https://github.com/OP-TED/model2owl-boilerplate>. User-facing GitHub Actions template that wraps model2owl; shows the intended end-user workflow and how projects configure and invoke the tool.

## Local developer overrides

An optional, git-ignored third tier of instructions is imported below. If the
file does not exist, the import is skipped. Anything it (or any git-ignored
path) contains is local-only and must never surface in commits, PRs, code,
comments, or docs — see the provenance rule inside it.

@.claude/CLAUDE.local.md