#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT/lib.sh"

SHARED_HOME="$HOME/.ai-dev-rules"
RUNTIME_HOME="$SHARED_HOME/runtime"
# PID keeps two runs inside the same second from overwriting each other's backup.
STAMP="$(date +%Y%m%d-%H%M%S)-$$"
FAILURES=""

mkdir -p "$SHARED_HOME" "$RUNTIME_HOME"

if [ "$(find "$SHARED_HOME" -maxdepth 1 -type f 2>/dev/null | head -n 1)" ]; then
  BACKUP="$SHARED_HOME/backups/shared-$STAMP"
  mkdir -p "$BACKUP"
  for f in CORE.md WORKFLOW.md UX.md RELIABILITY.md REVIEW.md; do
    if [ -f "$SHARED_HOME/$f" ]; then cp "$SHARED_HOME/$f" "$BACKUP/$f"; fi
  done
  echo "Backed up existing shared rules to: $BACKUP"
fi

for f in CORE.md WORKFLOW.md UX.md RELIABILITY.md REVIEW.md; do
  cp "$ROOT/shared/$f" "$SHARED_HOME/$f"
done

rm -rf "$RUNTIME_HOME/adapters" "$RUNTIME_HOME/templates"
cp "$ROOT/lib.sh" "$RUNTIME_HOME/lib.sh"
cp -R "$ROOT/adapters" "$RUNTIME_HOME/adapters"
cp -R "$ROOT/templates" "$RUNTIME_HOME/templates"

install_adapter() {
  name="$1"
  target_home="$2"
  target_file="$3"
  marker="$4"
  mkdir -p "$target_home"
  target="$target_home/$target_file"

  if [ -f "$target" ]; then
    backup_dir="$target_home/backups/ai-runtime-$STAMP"
    mkdir -p "$backup_dir"
    cp "$target" "$backup_dir/$target_file"
    echo "Backed up $target to: $backup_dir/$target_file"
  fi

  if merge_managed_block "$target" \
    "<!-- BEGIN AI-ENGINEERING-RUNTIME ADAPTER:$marker -->" \
    "<!-- END AI-ENGINEERING-RUNTIME ADAPTER:$marker -->" \
    "$ROOT/adapters/$name/GLOBAL_BLOCK.md"; then
    echo "Merged adapter into: $target"
  else
    FAILURES="$FAILURES$marker ($target)"$'\n'
  fi
}

install_adapter "codex" "${CODEX_HOME:-$HOME/.codex}" "AGENTS.md" "CODEX"
install_adapter "claude-code" "${CLAUDE_CONFIG_DIR:-$HOME/.claude}" "CLAUDE.md" "CLAUDE"
install_adapter "pi-agent" "${PI_AGENT_HOME:-$HOME/.pi/agent}" "AGENTS.md" "PI"
install_adapter "deepseek-harness" "${DSH_HOME:-$HOME/.dsh}" "AGENTS.md" "DSH"

if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
  BIN_DIR="$HOME/.local/bin"
elif [[ ":$PATH:" == *":$HOME/bin:"* ]]; then
  BIN_DIR="$HOME/bin"
elif [ -d "/usr/local/bin" ] && [ -w "/usr/local/bin" ]; then
  BIN_DIR="/usr/local/bin"
else
  BIN_DIR="$HOME/.local/bin"
fi

mkdir -p "$BIN_DIR"
cp "$ROOT/ai-init" "$BIN_DIR/ai-init"
chmod +x "$BIN_DIR/ai-init"

echo
echo "Installed command: $BIN_DIR/ai-init"

if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
  echo
  echo "NOTE: $BIN_DIR is not currently in PATH."
  echo "Add this once to your shell configuration:"
  echo "  export PATH=\"$BIN_DIR:\$PATH\""
fi

if [ -n "$FAILURES" ]; then
  echo
  echo "ERROR: the following global adapters were skipped:"
  printf '%s' "$FAILURES" | while IFS= read -r line; do
    if [ -n "$line" ]; then echo "  $line"; fi
  done
  echo
  echo "See the errors above (markers or file permissions), fix them, then re-run install-all.sh."
  echo "The shared rules and the ai-init command were installed, so the rest still works."
  exit 1
fi

echo
echo "Installation complete."
echo "No existing AGENTS.md or CLAUDE.md was overwritten."
echo
echo "For each project, run once:"
echo "  cd /path/to/project"
echo "  ai-init"
