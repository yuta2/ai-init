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
before="$(cat target.md)"
merge_managed_block target.md "$B" "$E" block.md >/dev/null 2>&1
check "unbalanced markers: non-zero exit" "$?" "1"
check "unbalanced markers: file untouched" "$(cat target.md)" "$before"
teardown

# --- refuses to touch a file with duplicate blocks ---------------------------
setup
cat block.md block.md > target.md
before="$(cat target.md)"
merge_managed_block target.md "$B" "$E" block.md >/dev/null 2>&1
check "duplicate blocks: non-zero exit" "$?" "1"
check "duplicate blocks: file untouched" "$(cat target.md)" "$before"
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

echo
echo "passed: $PASS   failed: $FAIL"
[ "$FAIL" -eq 0 ]
