#!/usr/bin/env python3
"""Summarise XSpec test results from the surefire JUnit XML reports.

`make unit-tests` / `make test` print `BUILD SUCCESS` and exit 0 even when XSpec
assertions fail, so the authoritative source of truth is the per-`.xspec` JUnit
XML under target/surefire-reports/. This script parses those files and prints a
compact pass/fail summary, listing each failure with its module, scenario, case,
reason and the matching HTML report link.

Stale results are skipped by default: only reports modified within the last
--max-age-min minutes are considered (0 disables the filter).

Exit code: 0 when all considered tests passed (or there is nothing to report),
1 when any failure/error was found. The caller decides whether to gate on it.
"""
import argparse
import glob
import os
import sys
import time
import xml.etree.ElementTree as ET

SEP = "=" * 67
SUREFIRE_SUFFIX = "-junit.xml"
HTML_SUFFIX = "-result.html"


def module_name(report_path):
    """`…/test-checkers.xspec-junit.xml` -> `test-checkers.xspec`."""
    base = os.path.basename(report_path)
    if base.endswith(SUREFIRE_SUFFIX):
        return base[: -len(SUREFIRE_SUFFIX)]
    return base


def html_report_link(report_path, html_dir):
    """Map a surefire report to its XSpec HTML report path."""
    return os.path.join(html_dir, module_name(report_path) + HTML_SUFFIX)


def fresh_reports(reports_dir, max_age_min):
    """Return (all paths, fresh paths) where fresh = modified within the window.

    The window is measured against wall-clock now, so a previous run's reports
    that are older than the window are treated as stale and excluded.
    """
    paths = sorted(glob.glob(os.path.join(reports_dir, "*.xml")))
    if max_age_min <= 0:
        return paths, paths
    cutoff = time.time() - max_age_min * 60
    fresh = [p for p in paths if os.path.getmtime(p) >= cutoff]
    return paths, fresh


def collect(reports, html_dir):
    """Parse reports into totals and a list of failure dicts."""
    total = passed = failed = other = 0
    failures = []
    for path in reports:
        module = module_name(path)
        try:
            root = ET.parse(path).getroot()
        except ET.ParseError as exc:
            failed += 1
            total += 1
            failures.append(
                {
                    "module": module,
                    "scenario": "(could not parse report)",
                    "case": "",
                    "reason": str(exc),
                    "report": html_report_link(path, html_dir),
                }
            )
            continue
        for suite in root.iter("testsuite"):
            scenario = suite.get("name", "")
            for case in suite.iter("testcase"):
                total += 1
                status = case.get("status", "")
                if status == "passed":
                    passed += 1
                    continue
                if status != "failed":
                    other += 1
                    continue
                failed += 1
                detail = case.find("failure")
                if detail is None:
                    detail = case.find("error")
                message = detail.get("message", "") if detail is not None else ""
                text = (detail.text if detail is not None else "") or ""
                text = " ".join(text.split())
                reason = " — ".join(p for p in (message, text) if p) or "(no detail)"
                failures.append(
                    {
                        "module": module,
                        "scenario": scenario,
                        "case": case.get("name", ""),
                        "reason": reason,
                        "report": html_report_link(path, html_dir),
                    }
                )
    return {
        "total": total,
        "passed": passed,
        "failed": failed,
        "other": other,
        "failures": failures,
    }


def render(stats, n_reports, max_age_min):
    window = f"newer than {max_age_min} min" if max_age_min > 0 else "all (no age filter)"
    lines = [
        SEP,
        f" XSpec summary · {n_reports} report(s) {window}",
        SEP,
        f" Tests: {stats['total']}   Passed: {stats['passed']}   Failed: {stats['failed']}"
        + (f"   Other: {stats['other']}" if stats["other"] else ""),
    ]
    if stats["failed"] == 0:
        lines += [" ✓ ALL GREEN", SEP]
        return "\n".join(lines)
    lines.append(f" ✗ {stats['failed']} FAILED")
    last_module = None
    for f in stats["failures"]:
        if f["module"] != last_module:
            lines.append("")
            lines.append(f" [{f['module']}]")
            last_module = f["module"]
        lines.append(f"   scenario : {f['scenario']}")
        if f["case"]:
            lines.append(f"   case     : {f['case']}")
        lines.append(f"   reason   : {f['reason']}")
        lines.append(f"   report   : {f['report']}")
    lines.append(SEP)
    return "\n".join(lines)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--reports-dir",
        default="target/surefire-reports",
        help="Directory holding the surefire JUnit XML files.",
    )
    parser.add_argument(
        "--html-dir",
        default="target/xspec-reports",
        help="Directory holding the XSpec HTML result reports.",
    )
    parser.add_argument(
        "--max-age-min",
        type=int,
        default=15,
        help="Only consider reports modified within this many minutes (0 = no filter).",
    )
    args = parser.parse_args(argv)

    all_paths, reports = fresh_reports(args.reports_dir, args.max_age_min)
    if not all_paths:
        print(f"No surefire reports found under {args.reports_dir} — run `make unit-tests` first.")
        return 0
    if not reports:
        print(f" No surefire reports modified in the last {args.max_age_min} min.")
        print(
            " Run `make unit-tests` first, or widen with "
            "`make test-summary TEST_SUMMARY_MAX_AGE_MIN=0` (0 = no filter)."
        )
        return 0

    stats = collect(reports, args.html_dir)
    print(render(stats, len(reports), args.max_age_min))
    return 1 if stats["failed"] else 0


if __name__ == "__main__":
    sys.exit(main())
