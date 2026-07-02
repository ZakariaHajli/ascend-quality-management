#!/usr/bin/env python3
"""
Data-diff of modified mart products for a PR comment.

Runs from the dbt project dir (working-directory: dbt). It:
  1. lists the modified mart models (`dbt ls`, intersected with the prod/uat defer state),
  2. runs the `audit_data_products` macro to compare each one (current build vs UAT baseline),
  3. renders a markdown table to stdout (the workflow redirects it into the PR comment).

Non-fatal by design: on any problem it prints nothing (no data-diff section) and exits 0.

Usage:  python ../ci/data_diff.py <target>        # e.g. dev
"""
import json
import re
import subprocess
import sys
import tempfile

ANSI = re.compile(r"\x1b\[[0-9;]*m")
MARKER = re.compile(r"ASCEND_DATA_DIFF_JSON_BEGIN(.*?)ASCEND_DATA_DIFF_JSON_END", re.S)

# Write this script's dbt artifacts to a throwaway path so `dbt ls` / `run-operation`
# don't overwrite the build's target/run_results.json (which the Slim CI comment reads).
_TP = tempfile.mkdtemp(prefix="dbt-diff-")


def dbt(*args: str) -> subprocess.CompletedProcess:
    return subprocess.run(["dbt", *args, "--target-path", _TP], capture_output=True, text=True)


def num(v):
    return "—" if v is None else f"{v:,}"


def main() -> int:
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass
    target = sys.argv[1] if len(sys.argv) > 1 else "dev"

    # 1. modified mart products (needs the defer state manifest under prod-state/)
    ls = dbt("ls", "--quiet", "--resource-type", "model",
             "--select", "state:modified,path:models/03_mart",
             "--state", "prod-state", "--target", target, "--profiles-dir", ".",
             "--output", "name")
    if ls.returncode != 0:
        sys.stderr.write("data_diff: dbt ls failed (no state baseline yet?)\n" + ls.stdout + ls.stderr)
        return 0
    models = [ln.strip() for ln in ANSI.sub("", ls.stdout).splitlines()
              if ln.strip() and "." not in ln and " " not in ln]
    if not models:
        return 0  # nothing changed in the product layer → no section

    # 2. compare each against its UAT baseline
    op = dbt("run-operation", "audit_data_products",
             "--args", json.dumps({"models": models}),
             "--target", target, "--profiles-dir", ".")
    m = MARKER.search(ANSI.sub("", op.stdout))
    if not m:
        sys.stderr.write("data_diff: no diff payload returned\n" + op.stdout + op.stderr)
        return 0
    try:
        rows = json.loads(m.group(1))
    except json.JSONDecodeError:
        return 0

    # 3. render
    out = [
        "",
        "### 🔬 Data diff — modified products (vs `uat` baseline)",
        "",
        "| Product | Rows before | Rows after | Δ rows | Added/changed | Removed/changed |",
        "|---|--:|--:|--:|--:|--:|",
    ]
    for r in rows:
        before, after = r.get("rows_before"), r.get("rows_after")
        delta = "—"
        if isinstance(before, int) and isinstance(after, int):
            d = after - before
            delta = f"+{d:,}" if d > 0 else f"{d:,}"
        tag = " 🆕" if r.get("status") == "new" else ""
        out.append(
            f"| `{r['model']}`{tag} | {num(before)} | {num(after)} | {delta} "
            f"| {num(r.get('added_or_changed'))} | {num(r.get('removed_or_changed'))} |"
        )
    out += [
        "",
        "<sub>Full-row `HASH(*)` comparison — no primary key needed. A changed value counts in "
        "both *added/changed* and *removed/changed*. 🆕 = new product (no baseline).</sub>",
    ]
    print("\n".join(out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
