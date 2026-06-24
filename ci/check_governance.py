#!/usr/bin/env python3
"""
Governance policy gate (policy-as-code) for the CI lint stage.

Reads a dbt manifest.json and enforces, for every published mart data product:
  • a non-empty description (discoverability / catalog readiness), and
  • an owning dbt group (accountable owner).

Exits non-zero (fails the PR) on any violation.

Usage:  python ci/check_governance.py path/to/manifest.json
"""
import json
import sys


def main(manifest_path: str) -> int:
    with open(manifest_path, encoding="utf-8") as fh:
        manifest = json.load(fh)

    groups = manifest.get("groups", {})
    group_names = {g["name"] for g in groups.values()} if isinstance(groups, dict) else set()

    violations = []
    checked = 0

    for node in manifest["nodes"].values():
        if node.get("resource_type") != "model":
            continue
        # Only enforce on the published product layer.
        path = node.get("original_file_path", node.get("path", ""))
        if "03_mart" not in path.replace("\\", "/"):
            continue

        checked += 1
        name = node["name"]

        if not (node.get("description") or "").strip():
            violations.append(f"{name}: missing description")

        if not node.get("group"):
            violations.append(f"{name}: not assigned to an owning group")

    print(f"Governance gate: checked {checked} mart data products.")
    if violations:
        print(f"\n FAILED with {len(violations)} violation(s):")
        for v in violations:
            print(f"   - {v}")
        return 1

    print(" PASSED: every mart product is documented and owned.")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("usage: check_governance.py <manifest.json>", file=sys.stderr)
        sys.exit(2)
    sys.exit(main(sys.argv[1]))
