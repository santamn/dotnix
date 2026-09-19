#!/usr/bin/env bash
# Markdown を書いたあとに走らせる lint。
#
# 呼ばれ方は3つある。
#   1. Claude Code の PostToolUse hook (stdin に JSON)
#   2. Codex の PostToolUse hook (同じ JSON スキーマ)
#   3. AGENTS.md を読んだエージェントが手で叩く (第1引数にパス)
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 対象ファイルの決定: 引数が最優先、無ければ stdin の hook JSON から拾う
file="${1:-}"
if [[ -z "$file" && ! -t 0 ]]; then
  file=$(jq -r '.tool_input.file_path // empty' 2>/dev/null)
fi
[[ "$file" == *.md && -f "$file" ]] || exit 0

# markdownlint の設定: プロジェクト固有のものがあればそちらを優先する
config="$here/markdownlint.jsonc"
for name in .markdownlint.jsonc .markdownlint.json .markdownlint.yaml .markdownlint.yml; do
  candidate="${CLAUDE_PROJECT_DIR:-$PWD}/$name"
  [[ -f "$candidate" ]] && { config="$candidate"; break; }
done

findings=""

# markdownlint: Markdown の構造を見る
if command -v markdownlint >/dev/null 2>&1; then
  out=$(markdownlint --config "$config" "$file" 2>&1)
  [[ -n "$out" ]] && findings+="$out"$'\n'
fi

# textlint: 日本語の言い回しを見る。
# 日本語を含まないファイルに日本語ルールを当てても雑音しか出ないので、含むときだけ走らせる
if command -v textlint >/dev/null 2>&1 && grep -q '[ぁ-んァ-ヶ一-龠]' "$file"; then
  out=$(textlint --config "$here/../textlintrc.json" --format compact "$file" 2>&1)
  [[ -n "$out" ]] && findings+="$out"$'\n'
fi

findings="${findings%$'\n'}"
[[ -z "$findings" ]] && exit 0

total=$(wc -l <<<"$findings" | tr -d ' ')
{
  echo "lint reported $total issue(s) in $file."
  echo "Fix them without changing what the document says. Do not delete content to satisfy the linter."
  head -n 30 <<<"$findings"
  ((total > 30)) && echo "... and $((total - 30)) more"
} >&2
exit 2
