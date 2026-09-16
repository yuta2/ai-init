#!/usr/bin/env bash
# Checks for lib.sh. These functions write to the user's global ~/.claude/CLAUDE.md
# and ~/.codex/AGENTS.md, so a regression here eats real configuration.
#
# Run: bash test-lib.sh
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT/lib.sh"
set +e

PASS=0
FAIL=0
WORK=""

setup() {
  WORK="$(mktemp -d)"
  cd "$WORK" || exit 1
  B='<!-- BEGIN X:ONE -->'
  E='<!-- END X:ONE -->'
  printf '%s\n<!-- ai-runtime-version: 1 -->\nblock body v1\n%s\n' "$B" "$E" > block.md
  printf '%s\n<!-- ai-runtime-version: 2 -->\nblock body v2\n%s\n' "$B" "$E" > block-v2.md
}

teardown() {
  cd /
  [ -n "$WORK" ] && rm -rf "$WORK"
}

# Compare two files byte for byte. "$(cat f)" strips trailing newlines, which
# would hide exactly the kind of damage these checks exist to catch.
check_file() {
  if cmp -s "$2" "$3"; then
    PASS=$((PASS + 1))
    printf 'ok   %s\n' "$1"
  else
    FAIL=$((FAIL + 1))
    printf 'FAIL %s\n' "$1"
    diff "$3" "$2" | head -5 | sed 's/^/       /'
  fi
}

check() {
  if [ "$2" = "$3" ]; then
    PASS=$((PASS + 1))
    printf 'ok   %s\n' "$1"
  else
    FAIL=$((FAIL + 1))
    printf 'FAIL %s\n       expected: %s\n       actual:   %s\n' "$1" "$3" "$2"
  fi
}

# --- creates the file when the target does not exist -------------------------
setup
merge_managed_block target.md "$B" "$E" block.md >/dev/null
check "creates target when missing" "$(cat target.md)" "$(cat block.md)"
teardown

# --- preserves user content and is idempotent --------------------------------
setup
printf '# My rules\n\nkeep this line\n' > target.md
for _ in 1 2 3; do
  merge_managed_block target.md "$B" "$E" block.md >/dev/null
done
check "idempotent: one block after 3 merges" "$(grep -c "$B" target.md)" "1"
check "idempotent: user content survives" "$(grep -c '^keep this line$' target.md)" "1"
check "idempotent: user heading survives" "$(grep -c '^# My rules$' target.md)" "1"
teardown

# --- replaces the block body instead of appending a second copy ---------------
setup
printf '# My rules\n' > target.md
merge_managed_block target.md "$B" "$E" block.md >/dev/null
merge_managed_block target.md "$B" "$E" block-v2.md >/dev/null
check "upgrade: single block" "$(grep -c "$B" target.md)" "1"
check "upgrade: new body present" "$(grep -c 'block body v2' target.md)" "1"
check "upgrade: old body gone" "$(grep -c 'block body v1' target.md)" "0"
teardown

# --- refuses to touch a file with unbalanced markers -------------------------
setup
printf '# My rules\n\n%s\norphan\n' "$B" > target.md
cp target.md before.md
merge_managed_block target.md "$B" "$E" block.md >/dev/null 2>&1
check "unbalanced markers: non-zero exit" "$?" "1"
check_file "unbalanced markers: file untouched" target.md before.md
teardown

# --- refuses to touch a file with duplicate blocks ---------------------------
setup
cat block.md block.md > target.md
cp target.md before.md
merge_managed_block target.md "$B" "$E" block.md >/dev/null 2>&1
check "duplicate blocks: non-zero exit" "$?" "1"
check_file "duplicate blocks: file untouched" target.md before.md
teardown

# --- remove takes the block out and leaves user content ----------------------
setup
printf '# My rules\n\nkeep this line\n' > target.md
merge_managed_block target.md "$B" "$E" block.md >/dev/null
remove_managed_block target.md "$B" "$E"
check "remove: block gone" "$(grep -c "$B" target.md)" "0"
check "remove: user content survives" "$(grep -c '^keep this line$' target.md)" "1"
check "remove: heading survives" "$(grep -c '^# My rules$' target.md)" "1"
teardown

# --- remove on a file without the block is a no-op ----------------------------
setup
printf '# My rules\n' > target.md
remove_managed_block target.md "$B" "$E"
check "remove: no-op exit 0" "$?" "0"
check "remove: no-op content" "$(cat target.md)" "# My rules"
teardown

# --- remove on a missing file is a no-op -------------------------------------
setup
remove_managed_block absent.md "$B" "$E"
check "remove: missing file exit 0" "$?" "0"
teardown

# --- version is read from inside the block -----------------------------------
setup
printf '# My rules\n' > target.md
merge_managed_block target.md "$B" "$E" block.md >/dev/null
check "version: reads v1" "$(block_version_in target.md "$B" "$E")" "1"
merge_managed_block target.md "$B" "$E" block-v2.md >/dev/null
check "version: reads v2 after upgrade" "$(block_version_in target.md "$B" "$E")" "2"
check "version: empty when no block" "$(block_version_in block-absent.md "$B" "$E")" ""
teardown

# --- a version-like line outside the block is not picked up ------------------
setup
printf '<!-- ai-runtime-version: 99 -->\n# My rules\n' > target.md
merge_managed_block target.md "$B" "$E" block.md >/dev/null
check "version: ignores line outside block" "$(block_version_in target.md "$B" "$E")" "1"
teardown

# --- CRLF line endings still match their own markers ------------------------
setup
printf '# My rules\n\nkeep this line\n' > target.md
merge_managed_block target.md "$B" "$E" block.md >/dev/null
perl -pi -e 's/\n/\r\n/' target.md
merge_managed_block target.md "$B" "$E" block.md >/dev/null
check "crlf: no duplicate block" "$(grep -cF "$B" target.md)" "1"
check "crlf: version still readable" "$(block_version_in target.md "$B" "$E")" "1"
remove_managed_block target.md "$B" "$E" >/dev/null 2>&1
check "crlf: remove clears the block" "$(grep -cF "$B" target.md)" "0"
check "crlf: user content survives" "$(grep -c 'keep this line' target.md)" "1"
teardown

# --- markers inside a fenced code block are refused, not obeyed --------------
setup
printf '# My rules\n\n```\n%s\nSECRET USER TEXT\n%s\n```\n\ntail line\n' "$B" "$E" > target.md
cp target.md before.md
merge_managed_block target.md "$B" "$E" block.md >/dev/null 2>&1
check "fenced markers: non-zero exit" "$?" "1"
check_file "fenced markers: file untouched" target.md before.md
remove_managed_block target.md "$B" "$E" >/dev/null 2>&1
check "fenced markers: remove refuses too" "$?" "1"
check_file "fenced markers: remove left file alone" target.md before.md
teardown

# --- an unwritable target reports failure instead of claiming success -------
setup
printf '# My rules\n' > target.md
cp target.md before.md
chmod 444 target.md
merge_managed_block target.md "$B" "$E" block.md >/dev/null 2>&1
check "unwritable: non-zero exit" "$?" "1"
check_file "unwritable: file not truncated" target.md before.md
chmod 644 target.md
teardown

# --- a block in the middle keeps the content that follows it ----------------
setup
printf '# Top\n\n%s\nold body\n%s\n\n# Bottom\n\nbottom line\n' "$B" "$E" > target.md
merge_managed_block target.md "$B" "$E" block.md >/dev/null
check "mid-file block: bottom heading survives" "$(grep -c '^# Bottom$' target.md)" "1"
check "mid-file block: bottom line survives" "$(grep -c '^bottom line$' target.md)" "1"
check "mid-file block: single block" "$(grep -cF "$B" target.md)" "1"
check "mid-file block: old body gone" "$(grep -c '^old body$' target.md)" "0"
teardown

# --- a file with no trailing newline keeps its last line --------------------
setup
printf '# My rules\nlast line without newline' > target.md
merge_managed_block target.md "$B" "$E" block.md >/dev/null
check "no trailing newline: last line survives" "$(grep -c 'last line without newline' target.md)" "1"
check "no trailing newline: block merged" "$(grep -cF "$B" target.md)" "1"
teardown

# --- block_state_in classifies the three cases ------------------------------
setup
printf '# My rules\n' > target.md
check "state: absent" "$(block_state_in target.md "$B" "$E")" "absent"
merge_managed_block target.md "$B" "$E" block.md >/dev/null
check "state: ok" "$(block_state_in target.md "$B" "$E")" "ok"
printf '%s\n' "$B" >> target.md
check "state: malformed" "$(block_state_in target.md "$B" "$E")" "malformed"
check "state: missing file is absent" "$(block_state_in nope.md "$B" "$E")" "absent"
teardown

echo
# --- fence variants: tilde, indented, nested, mismatched close ---------------
setup
fence_case() {
  printf "$2" "$B" "$E" > target.md
  cp target.md before.md
  merge_managed_block target.md "$B" "$E" block.md >/dev/null 2>&1
  check "fence variant ($1): refused" "$?" "1"
  check_file "fence variant ($1): file untouched" target.md before.md
}
fence_case "tilde"    '# M\n\n~~~\n%s\nSECRET\n%s\n~~~\n'
fence_case "indented" '# M\n\n  ```\n%s\nSECRET\n%s\n  ```\n'
fence_case "nested"   '# M\n\n````\n```\n%s\nSECRET\n%s\n```\n````\n'
fence_case "mismatched close" '# M\n\n```\n%s\nSECRET\n%s\n~~~\n'
teardown

# --- an ordinary code block must not be mistaken for a fenced marker ---------
setup
printf '# M\n\n```bash\necho hi\n```\n\n%s\nold\n%s\n' "$B" "$E" > target.md
check "ordinary code block: state ok" "$(block_state_in target.md "$B" "$E")" "ok"
merge_managed_block target.md "$B" "$E" block.md >/dev/null
check "ordinary code block: exit 0" "$?" "0"
check "ordinary code block: content kept" "$(grep -c '^echo hi$' target.md)" "1"
check "ordinary code block: fences kept" "$(grep -c '^```$' target.md)" "1"
check "ordinary code block: single block" "$(grep -cF "$B" target.md)" "1"
teardown

echo
# --- a wrong-character fence line before the markers must not close the fence -
# The markers must still count as fenced, otherwise merging deletes SECRET.
setup
printf '# M\n\n```\ncode\n~~~\n%s\nSECRET\n%s\n```\n' "$B" "$E" > target.md
cp target.md before.md
check "fence char: markers still fenced" "$(block_state_in target.md "$B" "$E")" "malformed"
merge_managed_block target.md "$B" "$E" block.md >/dev/null 2>&1
check "fence char: refused" "$?" "1"
check_file "fence char: file untouched" target.md before.md
teardown

# --- repeated merges must be byte-identical, not grow blank lines ------------
setup
printf '# My rules\n\nkeep this line\n' > target.md
merge_managed_block target.md "$B" "$E" block.md >/dev/null
merge_managed_block target.md "$B" "$E" block.md >/dev/null
cp target.md twice.md
merge_managed_block target.md "$B" "$E" block.md >/dev/null
check_file "byte idempotent: 3rd merge equals 2nd" target.md twice.md
check "byte idempotent: exactly one blank run before block" \
  "$(awk -v b="$B" 'NR>1 && $0==b { print blanks } /^[[:space:]]*$/ { blanks++; next } { blanks=0 }' target.md)" "2"
teardown

# --- trailing blank lines in user content are normalized away ---------------
# However many blank lines the user file ends with, the merged result must be
# the same; otherwise every re-run grows the gap before the block.
setup
printf '# My rules\n\nkeep this line\n' > none.md
printf '# My rules\n\nkeep this line\n\n\n\n\n' > many.md
merge_managed_block none.md "$B" "$E" block.md >/dev/null
merge_managed_block many.md "$B" "$E" block.md >/dev/null
check_file "trailing blanks: normalized away" many.md none.md
teardown

echo
echo "passed: $PASS   failed: $FAIL"
[ "$FAIL" -eq 0 ]
