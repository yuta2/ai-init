#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT/lib.sh"

if git rev-parse --show-toplevel >/dev/null 2>&1; then
  PROJECT_ROOT="$(git rev-parse --show-toplevel)"
else
  PROJECT_ROOT="$PWD"
fi

mkdir -p "$PROJECT_ROOT/.ai"

if [ ! -f "$PROJECT_ROOT/.ai/PROJECT.md" ]; then
  cp "$ROOT/templates/PROJECT.md" "$PROJECT_ROOT/.ai/PROJECT.md"
  echo "Created: $PROJECT_ROOT/.ai/PROJECT.md"
else
  echo "Kept existing: $PROJECT_ROOT/.ai/PROJECT.md"
fi

merge_project_adapter() {
  name="$1"
  file="$2"
  marker="$3"

  target="$PROJECT_ROOT/$file"
  if [ -f "$target" ]; then
    cp "$target" "$target.ai-runtime-backup-$(date +%Y%m%d-%H%M%S)"
  fi

  begin="<!-- BEGIN AI-ENGINEERING-RUNTIME PROJECT:$marker -->"
  end="<!-- END AI-ENGINEERING-RUNTIME PROJECT:$marker -->"
  merge_managed_block "$target" "$begin" "$end" "$ROOT/adapters/$name/PROJECT_BLOCK.md"
  echo "Merged project adapter into: $target"
}

# Codex, Pi, and DSH all use AGENTS.md. Merge all three managed blocks into the same file.
merge_project_adapter "codex" "AGENTS.md" "CODEX"
merge_project_adapter "pi-agent" "AGENTS.md" "PI"
merge_project_adapter "deepseek-harness" "AGENTS.md" "DSH"

# Claude Code uses CLAUDE.md.
merge_project_adapter "claude-code" "CLAUDE.md" "CLAUDE"

echo
echo "Project initialized without overwriting existing project instructions."
echo "Shared project context:"
echo "  $PROJECT_ROOT/.ai/PROJECT.md"
