#!/usr/bin/env bash
set -euo pipefail

# Marker comparison ignores a trailing CR throughout. A file that picks up CRLF
# endings (a Windows editor, git core.autocrlf) would otherwise stop matching its
# own markers, so every merge would append a second block and remove could never
# take either one out.

# Print "<begin_count> <end_count> <markers_inside_a_code_fence>".
_scan_markers() {
  awk -v b="$2" -v e="$3" '
    function norm(s) { sub(/\r$/, "", s); return s }
    { line = norm($0) }
    line ~ /^```/ { fence = !fence }
    line == b { if (fence) fenced++; else bc++ }
    line == e { if (fence) fenced++; else ec++ }
    END { printf "%d %d %d\n", bc, ec, fenced }
  ' "$1"
}

# Print "absent", "ok", or "malformed" for a managed block in a file.
block_state_in() {
  target="$1"
  begin_marker="$2"
  end_marker="$3"

  if [ ! -f "$target" ]; then
    echo "absent"
    return 0
  fi

  counts="$(_scan_markers "$target" "$begin_marker" "$end_marker")"
  bc="${counts%% *}"
  rest="${counts#* }"
  ec="${rest%% *}"
  fenced="${rest##* }"

  if [ "$fenced" -gt 0 ] || [ "$bc" -ne "$ec" ] || [ "$bc" -gt 1 ]; then
    echo "malformed"
  elif [ "$bc" -eq 0 ]; then
    echo "absent"
  else
    echo "ok"
  fi
}

_explain_malformed() {
  target="$1"
  counts="$(_scan_markers "$target" "$2" "$3")"
  bc="${counts%% *}"
  rest="${counts#* }"
  ec="${rest%% *}"
  fenced="${rest##* }"

  if [ "$fenced" -gt 0 ]; then
    echo "ERROR: Managed block markers appear inside a fenced code block in $target"
    echo "Removing the block would delete the surrounding content, so nothing was changed."
  elif [ "$bc" -ne "$ec" ]; then
    echo "ERROR: Managed block markers are unbalanced in $target ($bc begin, $ec end)"
    echo "No changes were made to this file."
  else
    echo "ERROR: Multiple managed blocks were found in $target"
    echo "Resolve duplicates manually before re-running."
  fi
}

# Drop trailing blank lines from stdin.
_trim_trailing_blanks() {
  awk '
    { lines[NR] = $0 }
    END {
      last = NR
      while (last > 0 && lines[last] ~ /^[[:space:]]*$/) last--
      for (i = 1; i <= last; i++) print lines[i]
    }
  '
}

merge_managed_block() {
  target="$1"
  begin_marker="$2"
  end_marker="$3"
  block_file="$4"

  mkdir -p "$(dirname "$target")"

  if [ ! -f "$target" ]; then
    if ! cp "$block_file" "$target"; then
      echo "ERROR: Could not create $target"
      return 1
    fi
    return 0
  fi

  state="$(block_state_in "$target" "$begin_marker" "$end_marker")"
  if [ "$state" = "malformed" ]; then
    _explain_malformed "$target" "$begin_marker" "$end_marker"
    return 1
  fi

  tmp="$(mktemp)" || return 1
  out="$(mktemp)" || { rm -f "$tmp"; return 1; }

  if [ "$state" = "ok" ]; then
    awk -v b="$begin_marker" -v e="$end_marker" '
      function norm(s) { sub(/\r$/, "", s); return s }
      { line = norm($0) }
      line == b { skip = 1; next }
      line == e { skip = 0; next }
      !skip { print }
    ' "$target" | _trim_trailing_blanks > "$tmp"
  else
    _trim_trailing_blanks < "$target" > "$tmp"
  fi

  # Assemble the whole result first, then write once. Writing directly to the
  # target would truncate it before discovering the file is not writable.
  if [ -s "$tmp" ]; then
    { cat "$tmp"; printf '\n\n'; cat "$block_file"; } > "$out"
  else
    cat "$block_file" > "$out"
  fi

  if ! cat "$out" > "$target" 2>/dev/null; then
    echo "ERROR: Could not write $target (permission denied or read-only filesystem)"
    echo "The file was left unchanged."
    rm -f "$tmp" "$out"
    return 1
  fi

  rm -f "$tmp" "$out"
  return 0
}

remove_managed_block() {
  target="$1"
  begin_marker="$2"
  end_marker="$3"

  [ -f "$target" ] || return 0

  state="$(block_state_in "$target" "$begin_marker" "$end_marker")"
  case "$state" in
    absent)
      return 0
      ;;
    malformed)
      _explain_malformed "$target" "$begin_marker" "$end_marker"
      echo "File left unchanged."
      return 1
      ;;
  esac

  tmp="$(mktemp)" || return 1
  out="$(mktemp)" || { rm -f "$tmp"; return 1; }

  awk -v b="$begin_marker" -v e="$end_marker" '
    function norm(s) { sub(/\r$/, "", s); return s }
    { line = norm($0) }
    line == b { skip = 1; next }
    line == e { skip = 0; next }
    !skip { print }
  ' "$target" | _trim_trailing_blanks > "$tmp"

  if [ -s "$tmp" ]; then
    { cat "$tmp"; printf '\n'; } > "$out"
  else
    : > "$out"
  fi

  if ! cat "$out" > "$target" 2>/dev/null; then
    echo "ERROR: Could not write $target (permission denied or read-only filesystem)"
    echo "The file was left unchanged."
    rm -f "$tmp" "$out"
    return 1
  fi

  rm -f "$tmp" "$out"
  return 0
}

# Print the ai-runtime-version declared inside a managed block, or nothing when
# the block or the version line is absent.
block_version_in() {
  target="$1"
  begin_marker="$2"
  end_marker="$3"

  [ -f "$target" ] || return 0

  awk -v b="$begin_marker" -v e="$end_marker" '
    function norm(s) { sub(/\r$/, "", s); return s }
    { line = norm($0) }
    line == b { inblock = 1; next }
    line == e { exit }
    inblock && line ~ /^<!-- ai-runtime-version: [0-9]+ -->$/ {
      gsub(/[^0-9]/, "", line)
      print line
      exit
    }
  ' "$target"
}
