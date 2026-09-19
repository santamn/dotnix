#!/usr/bin/env bash
# lint-md.sh の入出力の約束を固定するテスト。
# markdownlint だけがあればよく、textlint が無い環境でも通る。
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script="$here/lint-md.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fail=0
check() { # check <名前> <期待終了コード> <実際の終了コード>
  if [[ "$2" == "$3" ]]; then
    echo "ok   - $1"
  else
    echo "FAIL - $1: expected exit $2, got $3"
    fail=1
  fi
}

# 1. 問題のない Markdown は成功すること
printf '# Title\n\nBody.\n' > "$tmp/clean.md"
"$script" "$tmp/clean.md" >/dev/null 2>&1
check "clean markdown passes" 0 $?

# 2. markdownlint 違反 (末尾改行なし) は exit 2 になること
printf '# Title\n\nBody.' > "$tmp/dirty.md"
"$script" "$tmp/dirty.md" >/dev/null 2>&1
check "markdownlint violation exits 2" 2 $?

# 3. .md でないファイルは何もせず成功すること
printf 'x\n' > "$tmp/not-markdown.txt"
"$script" "$tmp/not-markdown.txt" >/dev/null 2>&1
check "non-markdown is ignored" 0 $?

# 4. 存在しないファイルは何もせず成功すること
"$script" "$tmp/missing.md" >/dev/null 2>&1
check "missing file is ignored" 0 $?

# 5. hook の JSON を stdin から受け取れること
printf '# Title\n\nBody.' > "$tmp/from-hook.md"
printf '{"tool_input":{"file_path":"%s"}}' "$tmp/from-hook.md" | "$script" >/dev/null 2>&1
check "reads file path from hook json" 2 $?

# 6. 指摘の本文に「内容を消すな」の指示が入ること
printf '# Title\n\nBody.' > "$tmp/msg.md"
msg=$("$script" "$tmp/msg.md" 2>&1 >/dev/null)
if [[ "$msg" == *"Do not delete content"* ]]; then
  echo "ok   - stderr carries the do-not-delete instruction"
else
  echo "FAIL - stderr missing the do-not-delete instruction: $msg"
  fail=1
fi

exit "$fail"
