#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT/lib.sh"

# home|file|marker
TARGETS="${CODEX_HOME:-$HOME/.codex}|AGENTS.md|CODEX
${CLAUDE_CONFIG_DIR:-$HOME/.claude}|CLAUDE.md|CLAUDE
${PI_AGENT_HOME:-$HOME/.pi/agent}|AGENTS.md|PI
${DSH_HOME:-$HOME/.dsh}|AGENTS.md|DSH"

FAILURES=""

while IFS='|' read -r home file marker; do
  if [ -z "$home" ]; then
    continue
  fi
  target="$home/$file"
  if ! remove_managed_block "$target" \
    "<!-- BEGIN AI-ENGINEERING-RUNTIME ADAPTER:$marker -->" \
    "<!-- END AI-ENGINEERING-RUNTIME ADAPTER:$marker -->"; then
    FAILURES="$FAILURES$marker ($target)"$'\n'
  fi
done <<< "$TARGETS"

if [ -n "$FAILURES" ]; then
  echo
  echo "ERROR: the following global adapters were left in place:"
  printf '%s' "$FAILURES" | while IFS= read -r line; do
    if [ -n "$line" ]; then echo "  $line"; fi
  done
  echo
  echo "Fix the managed block markers in the files above, then re-run."
  exit 1
fi

echo "Removed only AI Engineering Runtime managed adapter blocks."
echo "Existing user instructions and shared rule backups were preserved."
