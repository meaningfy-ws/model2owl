---
name: syncing-editorial-text-with-docs
description: Use when changing any human-facing/editorial text in the model2owl XSLT code — convention-check messages or severities, rule IDs, the unsupported-UML-constructs warnings, embedded documentation URLs, or transformation-rule codes — since these are mirrored in the ted-model2owl-docs repo and the two must not drift. Covers both impact analysis (which docs entry a change touches) and making the matching docs edit.
---

# Syncing editorial text with the docs repo

## Overview

Some human-facing strings are **duplicated** between this XSLT codebase and the
published documentation (`ted-model2owl-docs`, fork
`github.com/meaningfy-ws/ted-model2owl-docs`). The docs are the published source of
truth, so a stale string there is a real defect. When you touch editorial text in the
code, you have two jobs: **(1) impact analysis** — find which docs entry it maps to;
**(2) the sync edit** — update that entry in the same change.

Set up paths once (run from the code repo):

```bash
CODE=$(git rev-parse --show-toplevel)
DOCS=<path to your ted-model2owl-docs checkout>   # not under this repo
```

## Linked editorial places (the map)

| # | Category | Code side | Docs side | Join key |
|---|----------|-----------|-----------|----------|
| 1 | Convention-check **message + severity** | `src/html-conventions-lib/**/*.xsl` (`f:generate{,Formatted}{Error,Warning,Info}Message`) | `modules/ROOT/pages/checkers/model2owl-checkers.adoc` (one table row) | rule ID `cat-subcat-N` (arg 3) |
| 2 | **Unsupported-UML-constructs** warnings + embedded doc URL | `src/html-conventions-lib/general-html-conventions.xsl` | `modules/ROOT/pages/uml/unsupported-uml-constructs.adoc` | anchor `#sec:unsupported-uml-constructs` |
| 3 | **Transformation-rule codes** (`C.0n/D.0n/R.0n/T.0n`) | `xd:desc` comments in `src/owl-core-lib/**`, `reasoning-layer-lib/**`, `shacl-shape-lib/**`, `jsonld-context-lib/**` | `modules/ROOT/pages/transformation/transf-rules{1..4}.adoc` | rule code (counter seed) |
| 4 | Conventions-report "described elsewhere" link | `src/html-conventions-lib/fragments/introduction.xsl` | `modules/ROOT/pages/uml/conceptual-model-conventions.adoc` | URL literal |
| 5 | Config-flag descriptions | `test/ePO-default-config/config-parameters.xsl` | `modules/ROOT/pages/user-guide/configuration-file.adoc` | flag name |
| 6 | Make-target descriptions | root `Makefile` | `modules/ROOT/pages/user-guide/how-to-use.adoc` | target name |

Not linked (output-only, no docs mirror): report header/footer/title strings, glossary
term labels. SEMIC Style-Guide links (`generate*Message` args 4–5) point to an **external**
site (`semiceu.github.io/style-guide/1.0.0/…`), version-pinned — not this docs repo.

## Category 1 is the common case — message + severity

A `generate*Message(...)` call encodes:
- **arg 1** = message text (often `fn:concat('…', $var, '…')` — ignore the `$var` parts)
- **arg 3** = the rule ID (the join key)
- the **function name** encodes severity: `…Error…` → error, `…Warning…` → warning, `…Info…` → info.

Each rule ID maps to one row in `model2owl-checkers.adoc`:
`| `rule-id` | severity | checker name | message | pseudo-code`.

### Sync rule
- Reword the message → update the **Message** column (ignore `$placeholder$` / injected names).
- Switch `Error`/`Warning`/`Info` family → update the **Severity** column.
- Add / rename / remove a rule ID → add / rename / remove the row.
- Rows ending `…--0` (e.g. `class->common--0`) are "inherits from <table>" markers, not emissions — do not treat as missing code.

### Impact analysis for one change
```bash
# message + severity for a given rule ID
grep -rn -B6 "'class-name-2'" "$CODE/src/html-conventions-lib/" \
  | grep -E "generate(Formatted)?(Error|Warning|Info)Message|class-name-2"
grep -n "class-name-2" "$DOCS/modules/ROOT/pages/checkers/model2owl-checkers.adoc"
# compare the Message column, ignoring $placeholder$ and concat-injected names
```

### Full coverage check (run after any rule-ID change)
```bash
grep -rhoE "'[a-z][a-z0-9-]+-[0-9]+'" "$CODE/src/html-conventions-lib/" | tr -d "'" | sort -u > /tmp/code_ids.txt
grep -oE "[a-z][a-z0-9-]+-[0-9]+" "$DOCS/modules/ROOT/pages/checkers/model2owl-checkers.adoc" | sort -u > /tmp/docs_ids.txt
comm -23 /tmp/code_ids.txt /tmp/docs_ids.txt   # emitted in code, missing from docs  → ADD a row
comm -13 /tmp/code_ids.txt /tmp/docs_ids.txt   # in docs, never emitted (or --0 markers) → verify
```

## Category 2 — verify the embedded doc URL anchor still resolves
```bash
grep -oE "unsupported-uml-constructs\.html#[a-z:-]+" "$CODE/src/html-conventions-lib/general-html-conventions.xsl"
grep -n "\[\[sec:unsupported-uml-constructs\]\]" "$DOCS/modules/ROOT/pages/uml/unsupported-uml-constructs.adoc"
grep -nE "Model2owl supports" "$CODE/src/html-conventions-lib/general-html-conventions.xsl"  # supported-type list must match the docs page
```

## Making the edit

1. Identify the category and join key for the changed string.
2. Run the impact-analysis grep to locate the exact docs line(s).
3. Edit the docs file in your `ted-model2owl-docs` checkout — match wording, severity, and
   placeholders. Use `$placeholder$` style for dynamic parts (the docs convention), not the
   code's `fn:concat` variable names.
4. For category 1, re-run the coverage check to confirm no new drift.
5. Commit the docs change in the docs repo (its own git history) and reference the code change.

## Known drift surfaced by the coverage check (reconcile when you touch these)

- `common-tag-14]` — code emits a **stray trailing `]`** in the rule ID
  (`common-elements-html-conventions.xsl`), so it never matches the docs key `common-tag-14`. Code bug.
- `class-attributes-3` (code, warning) vs `class-attribute-3` (docs, info) — ID plural/singular **and**
  severity mismatch.
- Published-host inconsistency — `model2owl-docs-gh-pages` (general-html-conventions.xsl) vs
  `model2owl-docs` (introduction.xsl). One base URL is stale.
- Transformation codes mix `D.01`/`D.1` padding across docs; code uses `D.01`.

## Common mistakes

- Treating a docs message as a free paraphrase — for category 1 it must match the emitted string
  (minus dynamic values). A reviewer reads the docs, not the XSLT.
- Forgetting **severity** — switching `generateWarningMessage`→`generateErrorMessage` is a docs change too.
- Editing only the code message but not the rule's row, or vice-versa.
- Hardcoding your local docs path into committed files — refer to the repo by name; pass `DOCS=` at runtime.
- Assuming `…--0` rows or a documented-but-unemitted rule (e.g. a `-N` folded into another rule's message) are bugs — confirm against the row's note first.
