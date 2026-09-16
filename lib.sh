#!/usr/bin/env bash
set -euo pipefail

merge_managed_block() {
  target="$1"
  begin_marker="$2"
  end_marker="$3"
  block_file="$4"

  mkdir -p "$(dirname "$target")"

  if [ ! -f "$target" ]; then
    cp "$block_file" "$target"
    return 0
  fi

  begin_count="$(grep -Fxc "$begin_marker" "$target" 2>/dev/null || true)"
  end_count="$(grep -Fxc "$end_marker" "$target" 2>/dev/null || true)"

  if [ "$begin_count" -ne "$end_count" ]; then
    echo "ERROR: Managed block markers are malformed in $target"
    echo "No changes were made to this file."
    return 1
  fi

  if [ "$begin_count" -gt 1 ]; then
    echo "ERROR: Multiple managed blocks were found in $target"
    echo "Resolve duplicates manually before re-running."
    return 1
  fi

  tmp="$(mktemp)"

  if [ "$begin_count" -eq 1 ]; then
    awk -v b="$begin_marker" -v e="$end_marker" '
      $0 == b { skip=1; next }
      $0 == e { skip=0; next }
      !skip { print }
    ' "$target" > "$tmp"
  else
    cp "$target" "$tmp"
  fi

  # Keep user content intact; only normalize trailing blank lines.
  awk '
    { lines[NR]=$0 }
    END {
      last=NR
      while (last > 0 && lines[last] ~ /^[[:space:]]*$/) last--
      for (i=1; i<=last; i++) print lines[i]
    }
  ' "$tmp" > "${tmp}.trim"

  if [ -s "${tmp}.trim" ]; then
    cat "${tmp}.trim" > "$target"
    printf "\n\n" >> "$target"
  else
    : > "$target"
  fi

  cat "$block_file" >> "$target"
  rm -f "$tmp" "${tmp}.trim"
}

remove_managed_block() {
  target="$1"
  begin_marker="$2"
  end_marker="$3"

  [ -f "$target" ] || return 0

  begin_count="$(grep -Fxc "$begin_marker" "$target" 2>/dev/null || true)"
  end_count="$(grep -Fxc "$end_marker" "$target" 2>/dev/null || true)"

  if [ "$begin_count" -eq 0 ] && [ "$end_count" -eq 0 ]; then
    return 0
  fi

  if [ "$begin_count" -ne 1 ] || [ "$end_count" -ne 1 ]; then
    echo "ERROR: Managed block markers are malformed in $target"
    echo "File left unchanged."
    return 1
  fi

  tmp="$(mktemp)"
  awk -v b="$begin_marker" -v e="$end_marker" '
    $0 == b { skip=1; next }
    $0 == e { skip=0; next }
    !skip { print }
  ' "$target" > "$tmp"

  awk '
    { lines[NR]=$0 }
    END {
      last=NR
      while (last > 0 && lines[last] ~ /^[[:space:]]*$/) last--
      for (i=1; i<=last; i++) print lines[i]
    }
  ' "$tmp" > "${tmp}.trim"

  if [ -s "${tmp}.trim" ]; then
    cat "${tmp}.trim" > "$target"
    printf "\n" >> "$target"
  else
    : > "$target"
  fi

  rm -f "$tmp" "${tmp}.trim"
}

# Print the ai-runtime-version declared inside a managed block, or nothing when
# the block or the version line is absent.
block_version_in() {
  target="$1"
  begin_marker="$2"
  end_marker="$3"

  [ -f "$target" ] || return 0

  awk -v b="$begin_marker" -v e="$end_marker" '
    $0 == b { inblock = 1; next }
    $0 == e { exit }
    inblock && /^<!-- ai-runtime-version: [0-9]+ -->$/ {
      v = $0
      gsub(/[^0-9]/, "", v)
      print v
      exit
    }
  ' "$target"
}
