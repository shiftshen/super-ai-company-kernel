#!/bin/bash
# Generic Claude -> Company Kernel task submission.
# This replaces one-off DISPATCH-*.command files. It only creates a ledger task;
# daemon/adapter workers will claim it automatically.
set -euo pipefail

cd "$(dirname "$0")"

FROM="claude"
TO="codex"
PRIORITY="P1"
TITLE=""
DESCRIPTION=""
DESCRIPTION_FILE=""
TASK_ID=""

usage() {
  cat <<'EOF'
Usage:
  ./CLAUDE-SUBMIT-TASK.command --to codex --title "..." --description "..."
  ./CLAUDE-SUBMIT-TASK.command --title "..." --description-file /tmp/task.md

Options:
  --from <employee>            default: claude
  --to <employee>              default: codex
  --priority <P0|P1|P2|P3>     default: P1
  --task-id <id>               optional; auto-generated if omitted
  --title <title>              required
  --description <text>         required unless --description-file is used
  --description-file <path>    read task description from file

Result:
  Creates a Company Kernel task in submitted state. The daemon will claim it.
  This script does NOT execute codex directly and does NOT change employee status.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --from) FROM="${2:-}"; shift 2 ;;
    --to) TO="${2:-}"; shift 2 ;;
    --priority) PRIORITY="${2:-}"; shift 2 ;;
    --task-id) TASK_ID="${2:-}"; shift 2 ;;
    --title) TITLE="${2:-}"; shift 2 ;;
    --description) DESCRIPTION="${2:-}"; shift 2 ;;
    --description-file) DESCRIPTION_FILE="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -n "$DESCRIPTION_FILE" ]]; then
  if [[ ! -f "$DESCRIPTION_FILE" ]]; then
    echo "description file not found: $DESCRIPTION_FILE" >&2
    exit 2
  fi
  DESCRIPTION="$(cat "$DESCRIPTION_FILE")"
fi

if [[ -z "$TITLE" || -z "$DESCRIPTION" ]]; then
  echo "missing --title or --description/--description-file" >&2
  usage >&2
  exit 2
fi

if [[ -z "$TASK_ID" ]]; then
  TASK_ID="task-${FROM}-to-${TO}-$(date +%Y%m%d-%H%M%S)"
fi

echo "== submit task =="
echo "from=$FROM"
echo "to=$TO"
echo "priority=$PRIORITY"
echo "task_id=$TASK_ID"

bin/companyctl task submit \
  --from "$FROM" \
  --to "$TO" \
  --task-id "$TASK_ID" \
  --title "$TITLE" \
  --description "$DESCRIPTION" \
  --priority "$PRIORITY"

echo
echo "== task detail =="
bin/companyctl task show --task-id "$TASK_ID"

echo
echo "== $TO queue tail =="
bin/companyctl task list --agent "$TO" | tail -40

echo
echo "Submitted. Do not run DISPATCH-BACKEND-P1.command unless owner explicitly asks for that fixed vdamo-cloud P1 batch."
