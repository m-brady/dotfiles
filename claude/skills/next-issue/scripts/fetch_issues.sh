#!/usr/bin/env bash
# Compatibility wrapper. New callers should collect and reuse one snapshot file.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/backlog_snapshot.sh" collect "$@" | python3 -c 'import json,sys; d=json.load(sys.stdin); keep=set(d["eligibleIssueNumbers"]); fields=("number","title","url","createdAt","updatedAt","labels","milestone","assignees","body"); print(json.dumps([{**{k:i.get(k) for k in fields},"comments":i["commentCount"]} for i in d["issues"] if i["number"] in keep], indent=2))'
