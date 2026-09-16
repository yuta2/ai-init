#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT/lib.sh"

CODEX_HOME_RESOLVED="${CODEX_HOME:-$HOME/.codex}"
CLAUDE_HOME_RESOLVED="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
PI_HOME_RESOLVED="${PI_AGENT_HOME:-$HOME/.pi/agent}"
DSH_HOME_RESOLVED="${DSH_HOME:-$HOME/.dsh}"

remove_managed_block "$CODEX_HOME_RESOLVED/AGENTS.md" \
  "<!-- BEGIN AI-ENGINEERING-RUNTIME ADAPTER:CODEX -->" \
  "<!-- END AI-ENGINEERING-RUNTIME ADAPTER:CODEX -->"

remove_managed_block "$CLAUDE_HOME_RESOLVED/CLAUDE.md" \
  "<!-- BEGIN AI-ENGINEERING-RUNTIME ADAPTER:CLAUDE -->" \
  "<!-- END AI-ENGINEERING-RUNTIME ADAPTER:CLAUDE -->"

remove_managed_block "$PI_HOME_RESOLVED/AGENTS.md" \
  "<!-- BEGIN AI-ENGINEERING-RUNTIME ADAPTER:PI -->" \
  "<!-- END AI-ENGINEERING-RUNTIME ADAPTER:PI -->"

remove_managed_block "$DSH_HOME_RESOLVED/AGENTS.md" \
  "<!-- BEGIN AI-ENGINEERING-RUNTIME ADAPTER:DSH -->" \
  "<!-- END AI-ENGINEERING-RUNTIME ADAPTER:DSH -->"

echo "Removed only AI Engineering Runtime managed adapter blocks."
echo "Existing user instructions and shared rule backups were preserved."
