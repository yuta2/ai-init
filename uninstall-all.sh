#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT/lib.sh"

FAILURES=""

# Explicit calls, like install-all.sh: a |-separated table would split a home
# path that itself contains a |, and silently skip that file.
remove_adapter() {
  target="$1/$2"
  marker="$3"
  if ! remove_managed_block "$target" \
    "<!-- BEGIN AI-ENGINEERING-RUNTIME ADAPTER:$marker -->" \
    "<!-- END AI-ENGINEERING-RUNTIME ADAPTER:$marker -->"; then
    FAILURES="$FAILURES$marker ($target)"$'\n'
  fi
}

remove_adapter "${CODEX_HOME:-$HOME/.codex}" "AGENTS.md" "CODEX"
remove_adapter "${CLAUDE_CONFIG_DIR:-$HOME/.claude}" "CLAUDE.md" "CLAUDE"
remove_adapter "${PI_AGENT_HOME:-$HOME/.pi/agent}" "AGENTS.md" "PI"
remove_adapter "${DSH_HOME:-$HOME/.dsh}" "AGENTS.md" "DSH"

if [ -n "$FAILURES" ]; then
  echo
  echo "ERROR: the following global adapters were left in place:"
  printf '%s' "$FAILURES" | while IFS= read -r line; do
    if [ -n "$line" ]; then echo "  $line"; fi
  done
  echo
  echo "See the errors above (markers or file permissions), fix them, then re-run."
  exit 1
fi

echo "Removed only AI Engineering Runtime managed adapter blocks."
echo "Existing user instructions and shared rule backups were preserved."
