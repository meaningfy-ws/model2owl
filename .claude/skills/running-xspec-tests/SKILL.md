---
name: running-xspec-tests
description: Use when running model2owl XSpec tests and you want to run one or a few .xspec modules instead of the whole suite (e.g. after editing a single .xsl or .xspec file), or want a stdout pass/fail summary instead of opening HTML reports. Covers selective runs, the test summary, and reading results quickly.
---

# Running XSpec tests efficiently

## Overview

The full XSpec suite (`make unit-tests`) runs ~40 modules and takes minutes. When
you changed one library file or one test, run **only the affected module(s)** —
a single module finishes in ~10s. Then read results from the **stdout summary**,
not by opening 40 HTML pages.

There is no standalone `xspec` CLI installed here (only `saxon/saxon.jar`), so all
runs go through Maven via `make`. Selective runs work because the pom binds the
plugin's `includes` to the `xspec.includes` property (default `**/*.xspec`).

## Quick reference

| Goal | Command |
|------|---------|
| One module by bare name (+ summary) | `make unit-test-one MODULE=test-checkers` |
| One module (glob) | `make unit-tests INCLUDE='**/test-checkers.xspec'` |
| Several modules | `make unit-tests INCLUDE='**/test-checkers.xspec,**/test-fetchers.xspec'` |
| Whole suite | `make unit-tests` |
| Summary of recent runs | `make test-summary` |
| Summary, ignore age filter | `make test-summary TEST_SUMMARY_MAX_AGE_MIN=0` |

`MODULE` is the bare file name (no path, no `.xspec`). `INCLUDE` is an Ant glob,
comma-separated for several modules. Module names mirror `src/` — see the dirs
under `test/unitTests/` (e.g. `test-checkers`, `test-fetchers`,
`test-elements-owl-core`, `test-connectors-shacl-shape`).

## Why this is fast and self-scoping

A selective run only regenerates the surefire/HTML reports for the modules it
ran; the other ~39 keep their old mtime. `make test-summary` defaults to a
**15-minute freshness window**, so right after a selective run it shows **only
the module(s) you just ran**. You get a focused pass/fail summary for free.

## Reading the results

Never trust the Maven exit code or `BUILD SUCCESS` line — XSpec assertion
failures do not fail the Maven build. The summary printed by `make test-summary`
(and automatically at the end of `make test` / `make unit-test-one`) is the
quick read: it prints totals and, per failure, the module, scenario, case,
reason, and the `target/xspec-reports/<module>.xspec-result.html` link.

For deeper inspection of the raw JUnit XML, use the
**reading-xspec-test-results** skill.

## Common mistakes

- **Editing `pom.xml` to add `<excludes>`/`<testDir>` per run.** Not needed —
  use `INCLUDE`. The pom is already wired for command-line selection.
- **Passing a path or extension to `MODULE`.** Use the bare name
  (`test-checkers`), not `test/unitTests/.../test-checkers.xspec`.
- **Running `make test-summary` long after the run** and seeing "No reports
  modified in the last 15 min" — widen with `TEST_SUMMARY_MAX_AGE_MIN=0`.
- **Forgetting `test-prerequisites`.** `make unit-tests` runs it automatically
  (generates `.temp/enriched-namespaces.xml`); don't invoke `mvn` by hand.
