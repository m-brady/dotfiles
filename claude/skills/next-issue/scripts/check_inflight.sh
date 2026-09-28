#!/usr/bin/env bash
# Compatibility wrapper; --snapshot avoids a second GitHub collection.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ ${1:-} == "--snapshot" ]]; then
  [[ $# -eq 2 ]] || { echo "usage: check_inflight.sh --snapshot FILE" >&2; exit 2; }
  python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(json.dumps({"meta":d["meta"], **d["inflight"], "issuesReferencedByLandedWork":d["landedLeads"]}, indent=2))' "$2"
else
  "$SCRIPT_DIR/backlog_snapshot.sh" collect "$@" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(json.dumps({"meta":d["meta"], **d["inflight"], "issuesReferencedByLandedWork":d["landedLeads"]}, indent=2))'
fi
