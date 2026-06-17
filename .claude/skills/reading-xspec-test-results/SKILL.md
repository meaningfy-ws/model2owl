---
name: reading-xspec-test-results
description: >-
  Use after running model2owl XSpec tests (`make unit-tests` / `make test` /
  a single `xspec ...` run) to determine the REAL pass/fail outcome by parsing
  the surefire JUnit XML. Needed because `make unit-tests` prints
  `[INFO] BUILD SUCCESS` and returns exit code 0 even when XSpec assertions
  fail — so the exit code and BUILD line are unreliable. Invoke whenever you
  need to confirm whether XSpec tests actually passed.
---

# Reading model2owl XSpec test results

## Why this skill exists

`make unit-tests` and `make test` run XSpec via the xspec-maven-plugin. Maven
reports the *build* as successful (`[INFO] BUILD SUCCESS`, exit code `0`) as
long as the tests ran — **assertion failures do not fail the build**. Judging
pass/fail from the exit code or the `BUILD SUCCESS` line is therefore wrong.

The authoritative source of truth is the JUnit XML written to
`target/surefire-reports/*.xml` — one file per `.xspec` file.

## Report structure

```xml
<testsuites name="file:/…/test-checkers.xspec">
  <testsuite name="Some scenario" tests="1" failures="0">
    <testcase name="is valid" status="passed"/>
  </testsuite>
  <testsuite name="Another scenario" tests="1" failures="1">
    <testcase name="boolean-false" status="failed">
      <failure message="expect assertion failed">Expected: xs:boolean('false')</failure>
    </testcase>
  </testsuite>
</testsuites>
```

A test is RED when a `<testsuite>` has `failures="N"` with **N>0**, and it
contains a `<testcase … status="failed">` with a `<failure>` child.

Caveats that make naive grepping fragile:
- the root element is `<testsuites>` (plural) wrapping per-scenario `<testsuite>`;
- attributes (`name`, `tests`, `failures`, `status`) may wrap across lines;
- file names can contain spaces (e.g. `... copy.xspec-junit.xml`).

So parse the XML — do not grep a single line.

## Step by step

1. Make sure the tests have run and the reports exist:
   `ls target/surefire-reports/*.xml`
   (No files means tests were never run — run `make unit-tests` first.)
2. Run the command below from the repo root.
3. If it prints `ALL GREEN`, every scenario passed. Otherwise it lists each
   failing report file and, under it, each failed testcase with its message.

## Ready-to-run command

Copy-paste this from the repository root:

```bash
python3 - <<'PY'
import glob, sys, xml.etree.ElementTree as ET

reports = sorted(glob.glob("target/surefire-reports/*.xml"))
if not reports:
    sys.exit("No surefire reports found — run `make unit-tests` first.")

any_fail = False
for path in reports:
    try:
        root = ET.parse(path).getroot()
    except ET.ParseError as e:
        any_fail = True
        print(f"PARSE ERROR: {path}: {e}")
        continue
    # (a) report files containing at least one suite with failures>0
    if not any(int(s.get("failures", "0")) > 0 for s in root.iter("testsuite")):
        continue
    any_fail = True
    print(f"\nFAIL FILE: {path}")
    # (b) each failed testcase: name + failure message + expected text
    for tc in root.iter("testcase"):
        if tc.get("status") == "failed":
            f = tc.find("failure")
            msg = (f.get("message") if f is not None else "") or "(no message)"
            exp = ((f.text if f is not None else "") or "").strip().replace("\n", " ")
            print(f"  - {tc.get('name')} :: {msg} :: {exp[:120]}")

print("\n" + ("FAILURES FOUND — see above." if any_fail else "ALL GREEN"))
sys.exit(1 if any_fail else 0)
PY
```

Unlike `make unit-tests`, this command exits non-zero when any XSpec assertion
failed, so it is safe to use in scripts and CI gating.

### Quick grep fallback (no Python)

Less precise, but fast for a yes/no check on whether anything failed:

```bash
grep -rl 'status="failed"' target/surefire-reports/*.xml
```

Each printed file contains at least one failed scenario; an empty result means
all green.
