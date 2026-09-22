#!/usr/bin/env bash
set -euo pipefail

# Shared awk prelude. Every awk call below runs under LC_ALL=C: awk's string ==
# is a collation comparison in a UTF-8 locale, where a BOM or an ideographic
# space in front of a marker still compares equal to the bare marker. That made
# a plain line look like a managed marker, and made the verdict depend on the
# caller's locale.
#
# norm() also drops a trailing CR and leading blanks, so a file converted to
# CRLF, or a marker someone indented, still matches its own block instead of
# being ignored and silently duplicated.
#
# Markers inside a fenced code block are ignored rather than obeyed: a document
# that merely shows what a managed block looks like must not have its example
# deleted, and must not be locked out of merging either.
_AWK_PRELUDE='
  function strip_cr(s) { sub(/\r$/, "", s); return s }
  # At most three leading spaces are dropped, matching Markdown: four spaces or a
  # tab start an indented code block, so a marker there is an example and must
  # not be treated as a real one. Fence tracking is given the un-deindented line
  # so its own three-space limit still applies.
  function norm(s) {
    s = strip_cr(s)
    sub(/^ {0,3}/, "", s)
    return s
  }
  # Fence delimiters per CommonMark: ``` or ~~~, at most three spaces of indent.
  # A closing delimiter must use the same character, be at least as long as the
  # opener, and carry no info string.
  function fence_delim(s,   c, n, rest) {
    if (s !~ /^ {0,3}(`{3,}|~{3,})/) return ""
    sub(/^ {0,3}/, "", s)
    c = substr(s, 1, 1)
    n = 0
    while (substr(s, n + 1, 1) == c) n++
    rest = substr(s, n + 1)
    gsub(/[ \t]+$/, "", rest)
    # A backtick fence may not carry a backtick in its info string.
    if (c == "`" && index(rest, "`") > 0) return ""
    return c "\t" n "\t" rest
  }
  # Returns 1 when the line is a fence delimiter and updates the fence state.
  function track_fence(line,   d, c, n, rest) {
    d = fence_delim(line)
    if (d == "") return 0
    split(d, parts, "\t")
    c = parts[1]; n = parts[2] + 0; rest = parts[3]
    if (!in_fence) {
      in_fence = 1
      fence_char = c
      fence_len = n
      return 1
    }
    if (c == fence_char && n >= fence_len && rest == "") in_fence = 0
    return 1
  }
'

# Print "<begin_count> <end_count>", counting only markers outside a code fence.
_scan_markers() {
  LC_ALL=C awk -v b="$2" -v e="$3" "$_AWK_PRELUDE"'
    { raw = strip_cr($0); line = norm($0) }
    track_fence(raw) { next }
    in_fence { next }
    line == b { bc++ }
    line == e { ec++ }
    END { printf "%d %d\n", bc, ec }
  ' "$1"
}

# Print "absent", "ok", or "malformed" for a managed block in a file.
block_state_in() {
  local target="$1"
  local begin_marker="$2"
  local end_marker="$3"
  local counts bc ec

  if [ ! -f "$target" ]; then
    echo "absent"
    return 0
  fi

  counts="$(_scan_markers "$target" "$begin_marker" "$end_marker")"
  bc="${counts%% *}"
  ec="${counts##* }"

  if [ "$bc" -ne "$ec" ] || [ "$bc" -gt 1 ]; then
    echo "malformed"
  elif [ "$bc" -eq 0 ]; then
    echo "absent"
  else
    echo "ok"
  fi
}

_explain_malformed() {
  local counts bc ec
  counts="$(_scan_markers "$1" "$2" "$3")"
  bc="${counts%% *}"
  ec="${counts##* }"

  if [ "$bc" -ne "$ec" ]; then
    echo "ERROR: Managed block markers are unbalanced in $1 ($bc begin, $ec end)"
  else
    echo "ERROR: Multiple managed blocks were found in $1"
    echo "Resolve duplicates manually before re-running."
  fi
  echo "No changes were made to this file."
}

# Copy stdin to stdout with the managed block and trailing blank lines removed.
_strip_block() {
  LC_ALL=C awk -v b="$2" -v e="$3" "$_AWK_PRELUDE"'
    {
      line = norm($0)
      if (track_fence(strip_cr($0)) || in_fence) { keep(); next }
      if (line == b) { skip = 1; next }
      if (line == e) { skip = 0; next }
      if (!skip) keep()
    }
    function keep() { lines[++n] = $0 }
    END {
      while (n > 0 && lines[n] ~ /^[ \t\r]*$/) n--
      for (i = 1; i <= n; i++) print lines[i]
    }
  ' "$1"
}

# Replace $2 with the contents of $1, without ever truncating $2 on failure.
# Writing straight to the target with `cat > target` opens it O_TRUNC, so a
# write that fails partway (ENOSPC, RLIMIT_FSIZE) leaves the user with an empty
# config file. Build a sibling temp file, then rename it into place.
_write_file() {
  local source_file="$1"
  local dest="$2"
  local hops link dest_dir tmp

  # Replace what a symlink points at rather than the link itself.
  hops=0
  while [ -L "$dest" ] && [ "$hops" -lt 16 ]; do
    link="$(readlink "$dest")"
    case "$link" in
      /*) dest="$link" ;;
      *) dest="$(dirname "$dest")/$link" ;;
    esac
    hops=$((hops + 1))
  done

  dest_dir="$(dirname "$dest")"
  tmp="$(mktemp "$dest_dir/.ai-runtime-write.XXXXXX")" || return 1

  # cp -p carries the existing mode across, so the rename does not reset it.
  # Note: the rename gives the file a new inode, so any hard link to the old one
  # stops tracking it. That is the price of never truncating on a partial write.
  if [ -f "$dest" ]; then
    if ! cp -p "$dest" "$tmp" 2>/dev/null; then
      rm -f "$tmp"
      return 1
    fi
  else
    # mktemp creates 0600; a brand-new config file should get the umask mode
    # like any file the user would have created themselves.
    chmod "$(printf '%o' $((0666 & ~0$(umask))))" "$tmp"
  fi

  if ! cat "$source_file" > "$tmp" 2>/dev/null; then
    rm -f "$tmp"
    return 1
  fi

  if ! mv -f "$tmp" "$dest" 2>/dev/null; then
    rm -f "$tmp"
    return 1
  fi

  return 0
}

merge_managed_block() {
  local target="$1"
  local begin_marker="$2"
  local end_marker="$3"
  local block_file="$4"
  local state out body ok

  if [ ! -s "$block_file" ]; then
    echo "ERROR: Adapter block is missing or empty: $block_file"
    echo "No changes were made to $target."
    return 1
  fi

  mkdir -p "$(dirname "$target")"

  state="$(block_state_in "$target" "$begin_marker" "$end_marker")"
  if [ "$state" = "malformed" ]; then
    _explain_malformed "$target" "$begin_marker" "$end_marker"
    return 1
  fi

  out="$(mktemp)" || return 1

  if [ "$state" = "absent" ] && [ ! -f "$target" ]; then
    if ! cat "$block_file" > "$out" 2>/dev/null; then
      echo "ERROR: Could not assemble the new contents for $target"
      rm -f "$out"
      return 1
    fi
  else
    body="$(mktemp)" || { rm -f "$out"; return 1; }
    # A strip that dies partway would otherwise be written back as the file.
    if ! _strip_block "$target" "$begin_marker" "$end_marker" > "$body"; then
      echo "ERROR: Could not read $target"
      echo "The file was left unchanged."
      rm -f "$body" "$out"
      return 1
    fi
    ok=0
    if [ -s "$body" ]; then
      { cat "$body" && printf '\n\n' && cat "$block_file"; } > "$out" 2>/dev/null && ok=1
    else
      cat "$block_file" > "$out" 2>/dev/null && ok=1
    fi
    rm -f "$body"
    if [ "$ok" -ne 1 ]; then
      echo "ERROR: Could not assemble the new contents for $target"
      echo "The file was left unchanged."
      rm -f "$out"
      return 1
    fi
  fi

  if ! _write_file "$out" "$target"; then
    echo "ERROR: Could not write $target"
    echo "The file was left unchanged."
    rm -f "$out"
    return 1
  fi

  rm -f "$out"
  return 0
}

remove_managed_block() {
  local target="$1"
  local begin_marker="$2"
  local end_marker="$3"
  local state out body

  [ -f "$target" ] || return 0

  state="$(block_state_in "$target" "$begin_marker" "$end_marker")"
  case "$state" in
    absent)
      return 0
      ;;
    malformed)
      _explain_malformed "$target" "$begin_marker" "$end_marker"
      return 1
      ;;
  esac

  out="$(mktemp)" || return 1
  body="$(mktemp)" || { rm -f "$out"; return 1; }

  if ! _strip_block "$target" "$begin_marker" "$end_marker" > "$body"; then
    echo "ERROR: Could not read $target"
    echo "The file was left unchanged."
    rm -f "$body" "$out"
    return 1
  fi
  if [ -s "$body" ]; then
    { cat "$body"; printf '\n'; } > "$out"
  else
    : > "$out"
  fi
  rm -f "$body"

  if ! _write_file "$out" "$target"; then
    echo "ERROR: Could not write $target"
    echo "The file was left unchanged."
    rm -f "$out"
    return 1
  fi

  rm -f "$out"
  return 0
}

# Print the ai-runtime-version declared inside a managed block, or nothing when
# the block or the version line is absent.
block_version_in() {
  local target="$1"
  local begin_marker="$2"
  local end_marker="$3"

  [ -f "$target" ] || return 0

  LC_ALL=C awk -v b="$begin_marker" -v e="$end_marker" "$_AWK_PRELUDE"'
    { raw = strip_cr($0); line = norm($0) }
    track_fence(raw) { next }
    in_fence { next }
    line == b { inblock = 1; next }
    line == e { exit }
    inblock && line ~ /^<!-- ai-runtime-version: [0-9]+ -->$/ {
      gsub(/[^0-9]/, "", line)
      print line
      exit
    }
  ' "$target"
}
