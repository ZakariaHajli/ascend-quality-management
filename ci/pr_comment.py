#!/usr/bin/env python3
"""
Render a Slim CI summary (markdown) from dbt's run_results.json, for posting as a PR comment.

Usage:  python ci/pr_comment.py target/run_results.json <target>
"""
import json
import os
import sys

OK = {"success", "pass"}
FAIL = {"error", "fail"}


def main() -> int:
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # emojis render on any platform
    except Exception:
        pass
    path = sys.argv[1] if len(sys.argv) > 1 else "target/run_results.json"
    target = sys.argv[2] if len(sys.argv) > 2 else "dev"

    if not os.path.exists(path):
        print(f"### Slim CI — `{target}`\n\nNo run results were produced (the build did not run).")
        return 0

    with open(path, encoding="utf-8") as fh:
        results = json.load(fh).get("results", [])

    labels = {"model": "Models", "test": "Data tests", "unit_test": "Unit tests",
              "snapshot": "Snapshots", "seed": "Seeds", "operation": "Hooks"}
    buckets, models_built, failures = {}, [], []

    for r in results:
        rtype = r["unique_id"].split(".")[0]
        name = r["unique_id"].split(".")[-1]
        status = r["status"]
        b = buckets.setdefault(rtype, {"ok": 0, "fail": 0, "skip": 0, "warn": 0})
        if status in OK:
            b["ok"] += 1
            if rtype == "model":
                models_built.append(name)
        elif status in FAIL:
            b["fail"] += 1
            failures.append((name, (r.get("message") or "").splitlines()[:1]))
        elif status == "skipped":
            b["skip"] += 1
        else:
            b["warn"] += 1

    total_fail = sum(b["fail"] for b in buckets.values())
    icon = "✅ **success**" if total_fail == 0 else "❌ **failure**"

    out = [
        f"### 🧪 Slim CI results — `{target}`",
        "",
        f"{icon} · selection `state:modified+` · deferred to prod state",
        "",
        "| Resource | ✓ | ✗ | skipped |",
        "|---|--:|--:|--:|",
    ]
    for rtype in ("model", "test", "unit_test", "snapshot", "seed"):
        if rtype in buckets:
            b = buckets[rtype]
            out.append(f"| {labels.get(rtype, rtype)} | {b['ok']} | {b['fail']} | {b['skip']} |")

    if models_built:
        out += ["", f"**Models built ({len(models_built)}):** "
                + ", ".join(f"`{m}`" for m in sorted(models_built))]
    if failures:
        out += ["", "**Failures:**"]
        out += [f"- `{n}` — {(m[0] if m else '')}" for n, m in failures[:10]]

    out += ["", "<sub>Only modified models + their children were built (Slim CI).</sub>"]
    print("\n".join(out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
