# AI エージェント開発環境 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Claude Code 専用に組んである AI エージェント環境を、Claude Code と Codex と DeepSeek Harness のどれからでも同じものが見える形に組み直し、NixOS 上で宣言的に再現できるようにする。

**Architecture:** `dotnix/ai/` を唯一の実体とし、各エージェントの探索パスからリンクを張る。判断の要るロジック (プラグイン定義の変換、lint のディスパッチ、vq) は Python と bash のスクリプトに閉じ込めてテスト可能にし、Nix は配置と依存の宣言だけを担う。

**Tech Stack:** Nix (flake, Home Manager), Python 3, bash, textlint, markdownlint-cli

**Spec:** [docs/specs/2026-09-19-ai-agent-env.md](../specs/2026-09-19-ai-agent-env.md)

## Global Constraints

- 作業機は macOS。**`nix flake check` と `nixos-rebuild` は絶対にこのマシンで実行しない。** NixOS マシンでの実行はユーザに依頼する (AGENTS.md の規約)
- このマシンで実行できる検証は `python3`、`bash`、`jq`、`markdownlint`、`alejandra`、`node`、`nix flake prefetch` のみ。`textlint`、`statix`、`shellcheck`、`bats` は入っていない
- 自作の skill と `AGENTS.md` は `config.lib.file.mkOutOfStoreSymlink` で張る。編集が rebuild なしに効くこと
- 外部由来のものは store path で張る
- hook の設定ファイルに store path を書かない。`~/.agents/plugins/<name>` を安定パスとして挟む
- 関数、構造体、その他意味のまとまりには**日本語のコメント**を必ず付ける
- 後方互換を残さない。古い経路は削除する
- `.md` を書いたら `markdownlint --config ~/.claude/hooks/markdownlint/markdownlint.jsonc <file>` を通す
- Nix ファイルは `alejandra` でフォーマットする
- `sem` は nixpkgs のものを使わない (semaphoreci/cli で別物)

## ファイル構成

| パス | 責務 |
| --- | --- |
| `ai/AGENTS.md` | 全エージェント共通の規約。3ハーネスから参照される唯一の実体 |
| `ai/skills/japanese-writing/` | 日本語ライティングの統合 skill |
| `ai/skills/rust-guidelines/` | microsoft/rust-guidelines への索引ラッパ |
| `ai/tools/md2skill.py` | agents/commands 定義を SKILL.md へ変換 |
| `ai/tools/test_md2skill.py` | 上のテスト |
| `ai/hooks/lint-md.sh` | markdownlint と textlint のディスパッチャ |
| `ai/hooks/markdownlint.jsonc` | markdownlint の設定 |
| `ai/hooks/test_lint_md.sh` | 上のテスト |
| `ai/textlintrc.json` | textlint の設定 |
| `ai/claude/settings.json` | Claude Code の設定。Claude Code 自身が書き換える |
| `ai/codex/config.toml` | Codex の設定 |
| `ai/codex/hooks.json` | Codex の hook 設定 |
| `ai/vq/vq.py` | Vim コマンド提案 CLI |
| `ai/vq/test_vq.py` | 上のテスト |
| `ai/vq/config-summary.md` | nvim 設定の要約 |
| `ai/vq/README.md` | 要約の作り直し手順 |
| `pkgs/textlint-rule-preset-ai-words-ja.nix` | textlint プリセット |
| `pkgs/textlint-rule-preset-ai-writing.nix` | textlint プリセット |
| `pkgs/go-modern-guidelines.nix` | Go ガイドライン CLI |
| `pkgs/vq.nix` | vq のパッケージ |
| `modules/home/programs/ai-agents.nix` | パッケージと配線 |

`pkgs/` はこのリポジトリに無い新しいディレクトリ。`modules/nixos/overlays.nix` から `callPackage` で読む。

---

### Task 1: ai/AGENTS.md を書く

全エージェント共通の規約。以降のタスクが張るリンクの実体になる。

#### Files

- Create: `ai/AGENTS.md`

#### Interfaces

- Consumes: なし
- Produces: `ai/AGENTS.md` (Task 8 が3箇所へ張る)

- [ ] **Step 1: ファイルを作る**

`ai/AGENTS.md` に次を書く。既存の `~/.claude/CLAUDE.md` の3節はそのまま残し、振り分け表を足す。

````markdown
# AGENTS.md

Conventions shared by every project. A project's own AGENTS.md wins over this file.

## Routing

Before you start, find your situation here.

| Situation | Do this |
| --- | --- |
| Writing or editing Japanese prose | Use the `japanese-writing` skill. Decide the genre first: it changes which rules apply |
| You wrote or edited a `.md` file | Run `~/.agents/hooks/lint-md.sh <file>` and fix what it reports |
| Writing Go | Use the `use-modern-go` skill. It detects the project's Go version through the `go-modern-guidelines` CLI |
| Writing Python | Read the `modern-python` skill |
| Writing Rust | Use the `rust-guidelines` skill and read only the categories its index points you to |
| About to read a large source file | Get its structure first with `ast-grep outline <path>` or `zat <path>` |
| About to change or remove a function signature | Check the blast radius with `sem impact` first |
| Reporting how much changed | Do not count `+`/`-` lines from `git diff`. Use the entity counts from `sem diff` |
| Working with HTML or an API | Reach for `ax` before writing a Python or Node script |
| A regex code search is getting fragile | Switch to `ast-grep`. See the `ast-grep` skill for rule syntax |
| Looking for a file or directory | `fd`, not `find` |
| Searching text | `rg`, not `grep -r` |

## Writing

- Do not hard wrap prose. Insert line breaks only between paragraphs — never mid-paragraph to constrain visual line width. Let the display handle soft wrapping.
- When writing Japanese, follow the `japanese-writing` skill. Technical documentation and personal writing take different rules, so settle the genre before you write.
- Fix every lint finding without changing what the document says. Do not delete content to satisfy the linter.

## Coding

- Do not preserve backward compatibility. Remove obsolete paths instead of adding compatibility layers, fallbacks, or migrations.
- Follow functional programming style.
  - Prefer to make data immutable.
  - Specify three components: Actions, Calculation, Data (This principle is written in the book "Grokking Simplicity"). Specifically, carefully isolate Actions.
- Always attach comments **in Japanese** explaining the meaning of functions, structs, and any other semantically cohesive pieces of code

## Not for you

These are for the human, not for you. Do not invoke them.

- `hunk` — a diff viewer the human reads changes in
- `vq` — a CLI the human asks about their own vim keybindings
````

- [ ] **Step 2: lint を通す**

Run: `markdownlint --config ~/.claude/hooks/markdownlint/markdownlint.jsonc ai/AGENTS.md`
Expected: 出力なし (終了コード 0)

- [ ] **Step 3: Commit**

```bash
git add ai/AGENTS.md
git commit -m "feat(ai): 全エージェント共通の AGENTS.md を追加"
```

---

### Task 2: md2skill.py

Claude Code の `agents/*.md` と `commands/*.md` を Agent Skills 形式の `SKILL.md` に変換する。Codex と DeepSeek は SKILL.md しか読まないため、これが無いとサブエージェントとスラッシュコマンドが他エージェントへ届かない。

#### Files

- Create: `ai/tools/md2skill.py`
- Test: `ai/tools/test_md2skill.py`

#### Interfaces

- Consumes: なし
- Produces:
  - `split_frontmatter(text: str) -> tuple[dict[str, str], str]`
  - `to_skill(text: str, name: str, kind: str) -> str` (`kind` は `"agent"` か `"command"`)
  - CLI: `md2skill.py --kind {agent,command} --name NAME SRC DST`

- [ ] **Step 1: 失敗するテストを書く**

`ai/tools/test_md2skill.py`:

```python
"""md2skill の変換規則を固定するテスト。"""

import unittest

from md2skill import split_frontmatter, to_skill


class TestSplitFrontmatter(unittest.TestCase):
    # frontmatter と本文を分けられること
    def test_splits_keys_and_body(self):
        meta, body = split_frontmatter(
            "---\nname: foo\ndescription: does a thing\n---\n\nBody line.\n"
        )
        self.assertEqual(meta, {"name": "foo", "description": "does a thing"})
        self.assertEqual(body, "Body line.\n")

    # frontmatter が無い入力は空の辞書と全文を返すこと
    def test_no_frontmatter(self):
        meta, body = split_frontmatter("Just a body.\n")
        self.assertEqual(meta, {})
        self.assertEqual(body, "Just a body.\n")

    # 値に含まれるコロンで切らないこと
    def test_value_containing_colon(self):
        meta, _ = split_frontmatter("---\ndescription: a: b: c\n---\nx\n")
        self.assertEqual(meta["description"], "a: b: c")


class TestToSkill(unittest.TestCase):
    AGENT = (
        "---\n"
        "name: code-simplifier\n"
        "description: Simplifies code.\n"
        "model: opus\n"
        "---\n"
        "\n"
        "Follow the standards in CLAUDE.md.\n"
    )

    # agent は名前をそのまま使い、Claude 固有のキーを落とすこと
    def test_agent_drops_claude_only_keys(self):
        out = to_skill(self.AGENT, "code-simplifier", "agent")
        self.assertIn("name: code-simplifier\n", out)
        self.assertIn("description: Simplifies code.\n", out)
        self.assertNotIn("model:", out)

    # CLAUDE.md を AGENTS.md に置換すること
    def test_rewrites_doc_name(self):
        out = to_skill(self.AGENT, "code-simplifier", "agent")
        self.assertIn("Follow the standards in AGENTS.md.", out)
        self.assertNotIn("CLAUDE.md", out)

    # command は Codex に合わせて source-command- を前置すること
    def test_command_name_prefix(self):
        src = "---\ndescription: Revise it.\n---\n\nDo the thing.\n"
        out = to_skill(src, "revise-claude-md", "command")
        self.assertIn("name: source-command-revise-claude-md\n", out)

    # description が無い入力は拒否すること (Codex が必須にしている)
    def test_missing_description_is_error(self):
        with self.assertRaises(ValueError):
            to_skill("---\nname: x\n---\n\nbody\n", "x", "agent")


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: テストが失敗することを確認する**

Run: `cd ai/tools && python3 -m unittest test_md2skill -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'md2skill'`

- [ ] **Step 3: 実装を書く**

`ai/tools/md2skill.py`:

```python
#!/usr/bin/env python3
"""Claude Code の agents/commands 定義を Agent Skills 形式の SKILL.md へ変換する。

Codex と DeepSeek Harness は SKILL.md しか読まない。サブエージェント定義も
スラッシュコマンド定義も「frontmatter + 本文」という SKILL.md と同じ形なので、
Claude 固有のキーを落とせば skill として通る。
"""

from __future__ import annotations

import argparse
import re
import sys

# skill の frontmatter に残すキー。これ以外はハーネス固有なので落とす
KEPT_KEYS = ("name", "description")

# Codex がプラグインのコマンドを移行するときに付ける接頭辞に合わせる
COMMAND_PREFIX = "source-command-"


def split_frontmatter(text: str) -> tuple[dict[str, str], str]:
    """先頭の YAML frontmatter を辞書に、残りを本文として返す。

    対象ファイルの frontmatter はすべて1行1キーの平坦な形なので、
    YAML パーサは使わず最初のコロンだけで切る。
    """
    if not text.startswith("---\n"):
        return {}, text
    end = text.find("\n---\n", 3)
    if end == -1:
        return {}, text
    meta: dict[str, str] = {}
    for line in text[4:end].splitlines():
        key, sep, value = line.partition(":")
        if sep and not key.startswith(" "):
            meta[key.strip()] = value.strip()
    return meta, text[end + 5 :].lstrip("\n")


def _rewrite(body: str) -> str:
    """ハーネス固有の文書名を共通の名前に直す。

    Codex 自身のコマンド移行も同じ置換だけを行う。
    """
    return re.sub(r"\bCLAUDE\.md\b", "AGENTS.md", body)


def to_skill(text: str, name: str, kind: str) -> str:
    """定義ファイルの中身を SKILL.md の中身に変換する。"""
    meta, body = split_frontmatter(text)
    description = meta.get("description", "").strip()
    if not description:
        raise ValueError(f"{name}: description がないため skill にできない")

    skill_name = COMMAND_PREFIX + name if kind == "command" else meta.get("name", name)
    kept = {"name": skill_name, "description": description}
    front = "".join(f"{k}: {kept[k]}\n" for k in KEPT_KEYS)
    return f"---\n{front}---\n\n{_rewrite(body)}"


def main() -> int:
    """CLI 入口。1ファイルを変換して書き出す。"""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--kind", choices=("agent", "command"), required=True)
    parser.add_argument("--name", required=True)
    parser.add_argument("src")
    parser.add_argument("dst")
    args = parser.parse_args()

    with open(args.src, encoding="utf-8") as f:
        text = f.read()
    try:
        out = to_skill(text, args.name, args.kind)
    except ValueError as exc:
        print(f"md2skill: skip: {exc}", file=sys.stderr)
        return 1
    with open(args.dst, "w", encoding="utf-8") as f:
        f.write(out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

- [ ] **Step 4: テストが通ることを確認する**

Run: `cd ai/tools && python3 -m unittest test_md2skill -v`
Expected: `Ran 7 tests` / `OK`

- [ ] **Step 5: 実物で動かす**

Run:

```bash
cd ai/tools
src=$(ls -d ~/.claude/plugins/cache/claude-plugins-official/code-simplifier/*/ | tail -1)
python3 md2skill.py --kind agent --name code-simplifier "${src}agents/code-simplifier.md" /tmp/SKILL.md
head -5 /tmp/SKILL.md
```

Expected: `---` / `name: code-simplifier` / `description: Simplifies and refines code...` / `---` の4行が出て、`model: opus` が無いこと

- [ ] **Step 6: Commit**

```bash
git add ai/tools/md2skill.py ai/tools/test_md2skill.py
git commit -m "feat(ai): agents/commands 定義を SKILL.md へ変換する md2skill を追加"
```

---

### Task 3: lint-md.sh

markdownlint と textlint をまとめて走らせるディスパッチャ。Claude Code と Codex の `PostToolUse` hook から呼ばれるほか、hook を持たないエージェントが `AGENTS.md` の指示に従って手で呼ぶ。

#### Files

- Create: `ai/hooks/lint-md.sh`
- Create: `ai/hooks/markdownlint.jsonc`
- Create: `ai/textlintrc.json`
- Test: `ai/hooks/test_lint_md.sh`

#### Interfaces

- Consumes: なし
- Produces: `ai/hooks/lint-md.sh`。引数1個 (ファイルパス) か、stdin の hook JSON を受け取る。指摘があれば exit 2 で stderr に出す

- [ ] **Step 1: 設定ファイルを2つ作る**

`ai/hooks/markdownlint.jsonc` は現在 `~/.claude/hooks/markdownlint/markdownlint.jsonc` にあるものをそのまま写す。

```jsonc
{
  "default": false,

  // 見出しの意味構造
  "MD001": true,                          // ## の次に #### と飛ばさない
  "MD003": { "style": "atx" },            // === や --- の下線見出しを禁止
  "MD022": true,                          // 見出しの前後に空行
  "MD024": { "siblings_only": true },     // 同一階層内での見出し名の重複を禁止
  "MD025": true,                          // H1 は文書に一つ
  "MD036": { "punctuation": "" },         // 太字の見出し代用を禁止

  // 描画が壊れる書き方
  "MD029": { "style": "ordered" },        // 番号付きリストは 1. 2. 3.
  "MD031": true,                          // コードフェンスの前後に空行
  "MD032": true,                          // リストの前後に空行
  "MD040": true,                          // コードフェンスに言語指定
  "MD042": true,                          // 空リンクを禁止
  "MD051": true,                          // #アンカー のリンク先が実在するか検証
  "MD047": true                           // ファイル末尾に改行
}
```

`ai/textlintrc.json`:

```json
{
  "rules": {
    "preset-ai-words-ja": true,
    "preset-ai-writing": true,
    "preset-ja-technical-writing": {
      "sentence-length": { "max": 120 },
      "max-comma": false,
      "no-exclamation-question-mark": false,
      "ja-no-mixed-period": false
    }
  }
}
```

- [ ] **Step 2: 失敗するテストを書く**

`ai/hooks/test_lint_md.sh`:

```bash
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
```

- [ ] **Step 3: テストが失敗することを確認する**

Run: `chmod +x ai/hooks/test_lint_md.sh && ./ai/hooks/test_lint_md.sh`
Expected: `FAIL` 行が出て終了コード 1 (`lint-md.sh` がまだ無い)

- [ ] **Step 4: 実装を書く**

`ai/hooks/lint-md.sh`:

```bash
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
```

- [ ] **Step 5: テストが通ることを確認する**

Run: `chmod +x ai/hooks/lint-md.sh && ./ai/hooks/test_lint_md.sh`
Expected: 6行すべて `ok   -` で終了コード 0

- [ ] **Step 6: Commit**

```bash
git add ai/hooks/lint-md.sh ai/hooks/test_lint_md.sh ai/hooks/markdownlint.jsonc ai/textlintrc.json
git commit -m "feat(ai): markdownlint と textlint をまとめる lint-md.sh を追加"
```

---

### Task 4: vq.py

Vim のコマンドを Haiku に聞く薄い CLI。エージェントのハーネスを経由しないことが目的なので、skill にはしない。

#### Files

- Create: `ai/vq/vq.py`
- Create: `ai/vq/config-summary.md`
- Create: `ai/vq/README.md`
- Test: `ai/vq/test_vq.py`

#### Interfaces

- Consumes: なし
- Produces:
  - `normalize(query: str) -> str`
  - `load_api_key(env: dict[str, str], read_file) -> str | None`
  - `build_system(summary: str) -> str`
  - `ask(query: str, cache: dict[str, str], send) -> tuple[str, bool]` (返り値は本文とキャッシュ命中か)

- [ ] **Step 1: 失敗するテストを書く**

`ai/vq/test_vq.py`:

```python
"""vq のキャッシュキーと鍵の読み出しを固定するテスト。API は呼ばない。"""

import unittest

from vq import ask, build_system, load_api_key, normalize


class TestNormalize(unittest.TestCase):
    # 前後の空白と連続空白を潰すこと
    def test_collapses_whitespace(self):
        self.assertEqual(normalize("  delete   inside quotes "), "delete inside quotes")

    # 全角英数を半角に揃えること (NFKC)
    def test_nfkc(self):
        self.assertEqual(normalize("ｄｅｌｅｔｅ"), "delete")

    # 表記が同じなら同じキーになること
    def test_same_key(self):
        self.assertEqual(normalize("a  b"), normalize(" a b "))


class TestLoadApiKey(unittest.TestCase):
    # 環境変数があればそれを使うこと
    def test_prefers_env(self):
        key = load_api_key({"ANTHROPIC_API_KEY": "from-env"}, lambda _: "from-file")
        self.assertEqual(key, "from-env")

    # 環境変数が無ければファイルを読むこと
    def test_falls_back_to_file(self):
        key = load_api_key({}, lambda _: "from-file\n")
        self.assertEqual(key, "from-file")

    # どちらも無ければ None を返すこと
    def test_returns_none(self):
        def missing(_):
            raise FileNotFoundError

        self.assertIsNone(load_api_key({}, missing))


class TestBuildSystem(unittest.TestCase):
    # 設定要約を埋め込むこと
    def test_embeds_summary(self):
        self.assertIn("LEADER=space", build_system("LEADER=space"))

    # 出力形式の指示を含むこと
    def test_states_output_format(self):
        self.assertIn("---", build_system("x"))


class TestAsk(unittest.TestCase):
    # キャッシュにあれば send を呼ばないこと
    def test_cache_hit_skips_send(self):
        def boom(_):
            raise AssertionError("send should not be called")

        text, cached = ask("a b", {"a b": "ci\"i"}, boom)
        self.assertEqual(text, "ci\"i")
        self.assertTrue(cached)

    # キャッシュに無ければ send を呼び、結果を書き戻すこと
    def test_cache_miss_calls_send(self):
        cache: dict[str, str] = {}
        text, cached = ask(" A  B ", cache, lambda q: iter(["ci", '"', "i"]))
        self.assertEqual(text, 'ci"i')
        self.assertFalse(cached)
        self.assertEqual(cache["a b"], 'ci"i')


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: テストが失敗することを確認する**

Run: `cd ai/vq && python3 -m unittest test_vq -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'vq'`

- [ ] **Step 3: 実装を書く**

`ai/vq/vq.py`:

```python
#!/usr/bin/env python3
"""自分の vim 設定を踏まえてコマンドを提案する CLI。

エージェントのハーネスを経由すると、起動とツール定義のロードと発火判定の
固定コストが推論時間を上回る。このタスクはファイル探索も編集も要らないので、
単発の API コールだけを投げる。
"""

from __future__ import annotations

import json
import os
import re
import sys
import unicodedata
from pathlib import Path

MODEL = "claude-haiku-4-5-20251001"
MAX_TOKENS = 200

# 設定要約はこのスクリプトの隣に置く。生の init.lua は渡さない
SUMMARY_PATH = Path(__file__).with_name("config-summary.md")


def _cache_dir() -> Path:
    """キャッシュとログの置き場所。XDG に従う。"""
    base = os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache")
    return Path(base) / "vq"


def normalize(query: str) -> str:
    """キャッシュキー用にクエリを正規化する。

    NFKC で全角半角を揃え、前後と連続の空白を潰し、小文字に寄せる。
    """
    text = unicodedata.normalize("NFKC", query).strip().lower()
    return re.sub(r"\s+", " ", text)


def load_api_key(env: dict[str, str], read_file) -> str | None:
    """API キーを環境変数、無ければ設定ファイルから読む。

    リポジトリには鍵を置かないので、どちらもリポジトリ外を見る。
    """
    key = env.get("ANTHROPIC_API_KEY", "").strip()
    if key:
        return key
    try:
        return read_file(_key_path()).strip() or None
    except OSError:
        return None


def _key_path() -> Path:
    """鍵ファイルの場所。"""
    base = os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config")
    return Path(base) / "vq" / "api-key"


def build_system(summary: str) -> str:
    """system prompt を組み立てる。出力形式を厳しく固定して出力トークンを抑える。"""
    return f"""あなたはvimコマンドの提案器です。ユーザーの設定は以下の通り。

{summary}

出力は必ず以下の形式。前置きと補足は一切書かない。

<コマンド1行>
---
<構成要素>: <役割の説明>
<構成要素>: <役割の説明>

説明は各行40字以内。ユーザー独自のマッピングを使った場合は
その旨を明示する。標準機能で足りる場合は独自マッピングを使わない。"""


def ask(query: str, cache: dict[str, str], send) -> tuple[str, bool]:
    """クエリに答える。キャッシュにあればそれを返し、無ければ send で取りに行く。

    send はトークンのイテレータを返す呼び出し可能オブジェクト。
    ストリーミングをそのまま標準出力へ流すため、呼び出し側が差し替えられるようにしてある。
    """
    key = normalize(query)
    if key in cache:
        return cache[key], True
    chunks = []
    for chunk in send(query):
        chunks.append(chunk)
        sys.stdout.write(chunk)
        sys.stdout.flush()
    text = "".join(chunks)
    cache[key] = text
    return text, False


def _load_cache() -> dict[str, str]:
    """ローカルのキャッシュを読む。壊れていたら捨てて作り直す。"""
    path = _cache_dir() / "cache.json"
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}


def _save_cache(cache: dict[str, str]) -> None:
    """キャッシュを書き戻す。"""
    directory = _cache_dir()
    directory.mkdir(parents=True, exist_ok=True)
    (directory / "cache.json").write_text(
        json.dumps(cache, ensure_ascii=False), encoding="utf-8"
    )


def _log(query: str, answer: str, cached: bool) -> None:
    """質問と回答を追記する。何を繰り返し忘れているかを後から見るため。"""
    directory = _cache_dir()
    directory.mkdir(parents=True, exist_ok=True)
    row = {"query": query, "answer": answer, "cached": cached}
    with (directory / "log.jsonl").open("a", encoding="utf-8") as f:
        f.write(json.dumps(row, ensure_ascii=False) + "\n")


def main() -> int:
    """CLI 入口。"""
    query = " ".join(sys.argv[1:]).strip()
    if not query:
        print("usage: vq <聞きたい操作>", file=sys.stderr)
        return 2

    api_key = load_api_key(dict(os.environ), lambda p: Path(p).read_text(encoding="utf-8"))
    if api_key is None:
        print(
            f"vq: ANTHROPIC_API_KEY も {_key_path()} も無い",
            file=sys.stderr,
        )
        return 1

    import anthropic

    client = anthropic.Anthropic(api_key=api_key)
    system = build_system(SUMMARY_PATH.read_text(encoding="utf-8"))

    def send(text: str):
        """API をストリーミングで叩く。最初のトークンが出た時点で読み始められる。"""
        with client.messages.stream(
            model=MODEL,
            max_tokens=MAX_TOKENS,
            system=system,
            messages=[{"role": "user", "content": text}],
        ) as stream:
            yield from stream.text_stream

    cache = _load_cache()
    answer, cached = ask(query, cache, send)
    if cached:
        sys.stdout.write(answer)
    sys.stdout.write("\n")
    _save_cache(cache)
    _log(query, answer, cached)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

- [ ] **Step 4: テストが通ることを確認する**

Run: `cd ai/vq && python3 -m unittest test_vq -v`
Expected: `Ran 10 tests` / `OK`

- [ ] **Step 5: config-summary.md と README.md を書く**

`ai/vq/config-summary.md` は暫定版を置く。中身は Task 11 の実機作業で作り直す。

```markdown
# nvim 設定の要約

暫定版。実機で作り直すまでの仮置き。手順は README.md を見ること。

- ベースは AstroNvim v5
- leader は Space、localleader は `,`
- CapsLock と Ctrl は入れ替えてある (Hyprland 側の `kb_options = ctrl:swapcaps`)
- ファイラは neo-tree、Git は lazygit
- Rust は rustaceanvim、補完とフォーマットは conform
```

`ai/vq/README.md`:

````markdown
# vq

自分の vim 設定を踏まえてコマンドを提案する CLI。

```sh
vq "クォートの中だけ消したい"
```

## API キー

`ANTHROPIC_API_KEY`、無ければ `$XDG_CONFIG_HOME/vq/api-key` を読む。
どちらもリポジトリの外に置く。

## config-summary.md の作り直し

nvim の設定を変えたときだけ作り直す。

1. 実キーマップを dump する。

   ```sh
   nvim --headless -c 'lua local t={} for _,m in ipairs({"n","i","v","x","o","t"}) do for _,k in ipairs(vim.api.nvim_get_keymap(m)) do t[#t+1]=m.." "..k.lhs.." "..(k.desc or "") end end io.write(table.concat(t,"\n")) ' -c 'qa' > /tmp/keymap.txt
   ```

2. `/tmp/keymap.txt` と `nvim/lazy-lock.json` を Opus に渡し、leader キー、自分で足したマッピング、
   入っているプラグインとそれが追加するオペレータおよびテキストオブジェクトを30〜50行に圧縮させる。
3. 結果を `config-summary.md` に置く。

生の `init.lua` を system prompt に渡さないこと。入力トークンが増えて最初のトークンまでが遅くなり、
モデルも関係ない行に引っ張られる。
````

- [ ] **Step 6: lint を通す**

Run: `markdownlint --config ai/hooks/markdownlint.jsonc ai/vq/README.md ai/vq/config-summary.md`
Expected: 出力なし

- [ ] **Step 7: Commit**

```bash
git add ai/vq
git commit -m "feat(ai): Vim コマンド提案 CLI の vq を追加"
```

---

### Task 5: overlay のパッケージを3つ足す

textlint のプリセット2つと go-modern-guidelines。どれも nixpkgs に無い。

#### Files

- Create: `pkgs/textlint-rule-preset-ai-words-ja.nix`
- Create: `pkgs/textlint-rule-preset-ai-writing.nix`
- Create: `pkgs/go-modern-guidelines.nix`
- Modify: `modules/nixos/overlays.nix`

#### Interfaces

- Consumes: なし
- Produces: `pkgs.textlint-rule-preset-ai-words-ja`、`pkgs.textlint-rule-preset-ai-writing`、`pkgs.go-modern-guidelines`

ソースのハッシュは `nix flake prefetch` で取得済み。依存のハッシュ (`pnpmDeps`、`npmDepsHash`、`vendorHash`) は macOS では確定できないので `lib.fakeHash` を置き、NixOS マシンでのビルドエラーに出る正しい値へ差し替える。

- [ ] **Step 1: ai-words-ja のパッケージを書く**

`pkgs/textlint-rule-preset-ai-words-ja.nix`:

```nix
# AI が書いた日本語に出やすい単語と言い回しを検出する textlint プリセット
# nixpkgs に無いので自前でパッケージ化する
{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs,
  pnpm_10,
  fetchPnpmDeps,
  pnpmConfigHook,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "textlint-rule-preset-ai-words-ja";
  version = "1.2.1";

  src = fetchFromGitHub {
    owner = "p1ass";
    repo = "textlint-rule-preset-ai-words-ja";
    tag = "v${finalAttrs.version}";
    hash = "sha256-0QgNPVyheFdPLCLq6JJy5AFIJ5txr1TOvzJ2VFC2C0I=";
  };

  # TODO: NixOS 機でビルドし、エラーに出る正しい値へ差し替える
  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_10;
    fetcherVersion = 4;
    hash = lib.fakeHash;
  };

  nativeBuildInputs = [nodejs pnpmConfigHook pnpm_10];

  # TypeScript を lib/ へコンパイルする。package.json の main が lib/index.js を指す
  buildPhase = ''
    runHook preBuild
    pnpm build
    runHook postBuild
  '';

  # textlint.withPackages は NODE_PATH に lib/node_modules を並べる
  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/node_modules/${finalAttrs.pname}
    cp -r lib package.json node_modules $out/lib/node_modules/${finalAttrs.pname}/
    runHook postInstall
  '';

  meta = {
    description = "AI が書いた日本語に出てきやすい単語と言い回しを見つける textlint のプリセット";
    homepage = "https://github.com/p1ass/textlint-rule-preset-ai-words-ja";
    license = lib.licenses.mit;
    platforms = nodejs.meta.platforms;
  };
})
```

- [ ] **Step 2: ai-writing のパッケージを書く**

`pkgs/textlint-rule-preset-ai-writing.nix`:

```nix
# AI が書いた文章の構造 (リストの形、見出しの強調、コロンの使い方) を検出する textlint プリセット
# ai-words-ja が単語を見るのに対し、こちらは構造を見る。作者自身が補完関係だと書いている
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs,
}:
buildNpmPackage (finalAttrs: {
  pname = "textlint-rule-preset-ai-writing";
  version = "1.7.0";

  src = fetchFromGitHub {
    owner = "textlint-ja";
    repo = "textlint-rule-preset-ai-writing";
    tag = "v${finalAttrs.version}";
    hash = "sha256-mEi17KZLic5Uzr7NthAM47TqQsCUy6RyknBWB7tTZBc=";
  };

  # TODO: NixOS 機でビルドし、エラーに出る正しい値へ差し替える
  npmDepsHash = lib.fakeHash;

  # ライブラリなので bin は作らない。textlint.withPackages が NODE_PATH で拾う
  dontNpmInstall = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/node_modules/@textlint-ja/${finalAttrs.pname}
    cp -r lib package.json node_modules $out/lib/node_modules/@textlint-ja/${finalAttrs.pname}/
    runHook postInstall
  '';

  meta = {
    description = "AI が書いた文章の構造的な癖を検出する textlint プリセット";
    homepage = "https://github.com/textlint-ja/textlint-rule-preset-ai-writing";
    license = lib.licenses.mit;
    platforms = nodejs.meta.platforms;
  };
})
```

- [ ] **Step 3: go-modern-guidelines のパッケージを書く**

`pkgs/go-modern-guidelines.nix`:

```nix
# プロジェクトの Go バージョンに合わせた最新の書き方をエージェントへ渡す CLI
# use-modern-go skill がこのバイナリを呼ぶ
{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule (finalAttrs: {
  pname = "go-modern-guidelines";
  version = "1.1.1";

  src = fetchFromGitHub {
    owner = "JetBrains";
    repo = "go-modern-guidelines";
    rev = "155dc7ca10da5e1f6c841503086957b1b37f5815";
    hash = "sha256-Gm96NA55N2+YHH/3NW+qAeiqYkrsZeBT8EVgLP0Lx34=";
  };

  # TODO: NixOS 機でビルドし、エラーに出る正しい値へ差し替える
  vendorHash = lib.fakeHash;

  # skill 本体も同梱する。ai-agents.nix が $out/share/skills から張る
  postInstall = ''
    mkdir -p $out/share/skills
    cp -r $src/plugin/skills/use-modern-go $out/share/skills/
  '';

  meta = {
    description = "Help AI coding agents write modern Go";
    homepage = "https://github.com/JetBrains/go-modern-guidelines";
    license = lib.licenses.asl20;
    mainProgram = "go-modern-guidelines";
  };
})
```

- [ ] **Step 4: overlay に配線する**

`modules/nixos/overlays.nix` の `nixpkgs.overlays` リストの末尾へ、既存の glaze オーバーレイの後に足す。

```nix
    # dotnix 自前のパッケージ (nixpkgs に無いもの)
    (final: _prev: {
      textlint-rule-preset-ai-words-ja =
        final.callPackage ../../pkgs/textlint-rule-preset-ai-words-ja.nix {};
      textlint-rule-preset-ai-writing =
        final.callPackage ../../pkgs/textlint-rule-preset-ai-writing.nix {};
      go-modern-guidelines =
        final.callPackage ../../pkgs/go-modern-guidelines.nix {};
    })
```

- [ ] **Step 5: フォーマットを確認する**

Run: `alejandra --check pkgs/ modules/nixos/overlays.nix`
Expected: `0 files changed` (差分があれば `alejandra pkgs/ modules/nixos/overlays.nix` で直す)

- [ ] **Step 6: Commit**

```bash
git add pkgs modules/nixos/overlays.nix
git commit -m "feat(pkgs): textlint プリセット2つと go-modern-guidelines を追加"
```

---

### Task 6: flake inputs を足す

skill とプラグインの供給元を pin する。

#### Files

- Modify: `flake.nix:11-32` (inputs ブロック)

#### Interfaces

- Consumes: なし
- Produces: `inputs.{superpowers,ponytail,humanizer,claude-plugins-official,trailofbits-skills,rust-guidelines,stop-ai-slop-jp,ast-grep-skill,ax,sem}`

- [ ] **Step 1: inputs を足す**

`flake.nix` の `inputs` ブロックの `widevine-proxy2-release` の後に足す。

```nix
    # --- AI エージェント用の skill とプラグイン ---
    # どれも Nix のビルドは不要でファイルを配るだけなので flake = false
    superpowers = {
      url = "github:obra/superpowers";
      flake = false;
    };
    ponytail = {
      url = "github:DietrichGebert/ponytail";
      flake = false;
    };
    humanizer = {
      url = "github:blader/humanizer";
      flake = false;
    };
    claude-plugins-official = {
      url = "github:anthropics/claude-plugins-official";
      flake = false;
    };
    trailofbits-skills = {
      url = "github:trailofbits/skills";
      flake = false;
    };
    rust-guidelines = {
      url = "github:microsoft/rust-guidelines";
      flake = false;
    };
    stop-ai-slop-jp = {
      url = "github:iKora128/stop-ai-slop-jp";
      flake = false;
    };
    ast-grep-skill = {
      url = "github:ast-grep/agent-skill";
      flake = false;
    };

    # --- AI エージェント用の CLI (上流が flake を持つ) ---
    # ax は nixpkgs に無い
    ax = {
      url = "github:yusukebe/ax";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nixpkgs の sem は semaphoreci/cli で別物なので上流を使う
    sem = {
      url = "github:ataraxy-labs/sem";
      inputs.nixpkgs.follows = "nixpkgs";
    };
```

- [ ] **Step 2: フォーマットとロックを確認する**

Run: `alejandra --check flake.nix`
Expected: `0 files changed`

`flake.lock` の更新は NixOS マシンで行う。このマシンでは実行しない。

- [ ] **Step 3: Commit**

```bash
git add flake.nix
git commit -m "feat(flake): AI エージェント用の skill とプラグインの input を追加"
```

---

### Task 7: ai-agents.nix のパッケージと AGENTS.md の配線

モジュールの骨格を作る。この時点で rebuild するとツールが PATH に入り、`AGENTS.md` が3箇所から見える。

#### Files

- Create: `modules/home/programs/ai-agents.nix`
- Modify: `modules/home/default.nix:3-19` (imports)

#### Interfaces

- Consumes: `inputs.ax`、`inputs.sem`、`pkgs.go-modern-guidelines`、`config.dotfiles.path`
- Produces: `modules/home/programs/ai-agents.nix` (Task 8 が skill の配線を足す)

- [ ] **Step 1: モジュールを作る**

`modules/home/programs/ai-agents.nix`:

```nix
# AI コーディングエージェント (Claude Code / Codex / DeepSeek Harness) の共通環境
#
# ai/ を唯一の実体とし、各エージェントの探索パスからリンクを張る。
# 自作のものは作業ツリーを直接指すので、編集は rebuild なしに効く。
{
  config,
  pkgs,
  inputs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;

  # リポジトリの ai/ ディレクトリ (nix store の外にある実体)
  aiDir = "${config.dotfiles.path}/ai";

  # 作業ツリーを直接指すリンクを作る短縮形
  link = path: config.lib.file.mkOutOfStoreSymlink "${aiDir}/${path}";

  # textlint と日本語向けプリセット一式
  textlint = pkgs.textlint.withPackages [
    pkgs.textlint-rule-preset-ai-words-ja
    pkgs.textlint-rule-preset-ai-writing
    pkgs.textlint-rule-preset-ja-technical-writing
  ];
in {
  home.packages = [
    # --- エージェント本体 ---
    pkgs.claude-code
    pkgs.codex

    # --- エージェントが使うツール ---
    pkgs.ast-grep # 構文木ベースの検索と書き換え
    pkgs.zat # コードのアウトライン表示
    pkgs.go-modern-guidelines # use-modern-go skill が呼ぶ
    pkgs.gh # issue と PR の操作
    pkgs.jq # lint-md.sh が hook の入力を読む
    inputs.ax.packages.${system}.default # HTTP 取得と HTML 抽出
    inputs.sem.packages.${system}.default # エンティティ単位の diff と影響範囲

    # --- 文章の lint ---
    textlint
    pkgs.markdownlint-cli

    # --- 人間用 ---
    pkgs.hunk # diff レビュー用 TUI
  ];

  # hunk は git の pager を奪うので無効化する。
  # git diff の見た目は programs.delta のままにする
  programs.hunk = {
    enable = true;
    enableGitIntegration = false;
  };

  home.file = {
    # 全エージェント共通の規約。3ハーネスが別々の場所を見るので同じ実体へ3本張る
    ".claude/CLAUDE.md".source = link "AGENTS.md";
    ".codex/AGENTS.md".source = link "AGENTS.md";
    ".dsh/AGENTS.md".source = link "AGENTS.md";

    # lint スクリプト。AGENTS.md からはハーネス非依存の ~/.agents/hooks を案内する
    ".agents/hooks".source = link "hooks";
    ".claude/hooks".source = link "hooks";
  };
}
```

- [ ] **Step 2: imports に足す**

`modules/home/default.nix` の imports リストの `./programs/direnv.nix` の前へ、アルファベット順で足す。

```nix
    ./programs/ai-agents.nix
```

- [ ] **Step 3: フォーマットを確認する**

Run: `alejandra --check modules/home/programs/ai-agents.nix modules/home/default.nix`
Expected: `0 files changed`

- [ ] **Step 4: Commit**

```bash
git add modules/home/programs/ai-agents.nix modules/home/default.nix
git commit -m "feat(home): AI エージェント用のパッケージと AGENTS.md の配線を追加"
```

---

### Task 8: skill とプラグインの配線

`ai/skills/` と各 input から skill を集めて `~/.agents/skills/` と `~/.claude/skills/` へ配り、`agents/` と `commands/` を skill へ変換する。

#### Files

- Modify: `modules/home/programs/ai-agents.nix`

#### Interfaces

- Consumes: `ai/tools/md2skill.py` (Task 2)、Task 6 の inputs
- Produces: `~/.agents/skills/*`、`~/.claude/skills/*`、`~/.claude/agents/*`、`~/.claude/commands/*`、`~/.agents/plugins/*`

- [ ] **Step 1: let ブロックにヘルパを足す**

まずモジュールの引数に `lib` を足す。Task 7 では使っていなかったが、ここから必要になる。

```nix
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
```

続けて `let` 内、`textlint` の定義の後に次を足す。

```nix
  # ディレクトリ配下のサブディレクトリ名を集める。無いディレクトリには空を返す
  subdirs = dir:
    if builtins.pathExists dir
    then builtins.attrNames (lib.filterAttrs (_: t: t == "directory") (builtins.readDir dir))
    else [];

  # ディレクトリ直下の .md ファイル名 (拡張子なし) を集める
  mdNames = dir:
    if builtins.pathExists dir
    then
      map (lib.removeSuffix ".md")
      (builtins.attrNames (lib.filterAttrs (n: t: t == "regular" && lib.hasSuffix ".md" n) (builtins.readDir dir)))
    else [];

  # 取り込むプラグイン。それぞれ skills / agents / commands / hooks のどれかを持つ
  plugins = {
    superpowers = inputs.superpowers;
    ponytail = inputs.ponytail;
    humanizer = inputs.humanizer;
    skill-creator = "${inputs.claude-plugins-official}/plugins/skill-creator";
    claude-md-management = "${inputs.claude-plugins-official}/plugins/claude-md-management";
    code-simplifier = "${inputs.claude-plugins-official}/plugins/code-simplifier";
  };

  # 外部から持ってくる skill: 名前 -> ディレクトリ
  externalSkills =
    {
      stop-ai-slop-jp = "${inputs.stop-ai-slop-jp}";
      ast-grep = "${inputs.ast-grep-skill}/ast-grep/skills/ast-grep";
      hunk-review = "${pkgs.hunk}/share/skills/hunk/hunk-review";
      hunk-extensions = "${pkgs.hunk}/share/skills/hunk/hunk-extensions";
      use-modern-go = "${pkgs.go-modern-guidelines}/share/skills/use-modern-go";
    }
    # trailofbits は50個以上あるので使うものだけ選ぶ
    // lib.listToAttrs (map (n:
      lib.nameValuePair n "${inputs.trailofbits-skills}/plugins/${n}/skills/${n}") [
      "modern-python"
      "property-based-testing"
      "gh-cli"
    ])
    # 各プラグインの skills/ 配下
    // lib.foldl' (acc: name:
      acc
      // lib.listToAttrs (map (s:
        lib.nameValuePair s "${plugins.${name}}/skills/${s}")
      (subdirs "${plugins.${name}}/skills"))) {} (builtins.attrNames plugins);

  # 自作 skill: 作業ツリーを直接指すので編集が rebuild なしに効く
  ownSkills = lib.listToAttrs (map (n:
    lib.nameValuePair n (link "skills/${n}"))
  (subdirs ../../../ai/skills));

  # agents/ と commands/ を SKILL.md に変換したもの。
  # Codex と DeepSeek は SKILL.md しか読まないため、この変換が無いと届かない
  generatedSkills = pkgs.runCommand "dotnix-generated-skills" {} ''
    mkdir -p $out
    ${lib.concatMapStringsSep "\n" (name: let
      root = plugins.${name};
    in ''
      ${lib.concatMapStringsSep "\n" (a: ''
        mkdir -p $out/${a}
        ${pkgs.python3}/bin/python3 ${../../../ai/tools/md2skill.py} \
          --kind agent --name ${a} \
          ${root}/agents/${a}.md $out/${a}/SKILL.md || rm -rf $out/${a}
      '') (mdNames "${root}/agents")}
      ${lib.concatMapStringsSep "\n" (c: ''
        mkdir -p $out/source-command-${c}
        ${pkgs.python3}/bin/python3 ${../../../ai/tools/md2skill.py} \
          --kind command --name ${c} \
          ${root}/commands/${c}.md $out/source-command-${c}/SKILL.md \
          || rm -rf $out/source-command-${c}
      '') (mdNames "${root}/commands")}
    '') (builtins.attrNames plugins)}
  '';

  # 生成された skill を名前 -> パスの形に直す
  generated = lib.listToAttrs (map (n:
    lib.nameValuePair n "${generatedSkills}/${n}")
  (subdirs generatedSkills));

  # 全 skill。自作が最後なので同名なら自作が勝つ
  allSkills = externalSkills // generated // ownSkills;

  # 1つの skill を両方の探索パスへ張る
  skillLinks = prefix:
    lib.mapAttrs' (n: src: lib.nameValuePair "${prefix}/${n}" {source = src;}) allSkills;
```

- [ ] **Step 2: home.file に配線を足す**

`home.file` の定義を `lib.mkMerge` に変える。

```nix
  home.file = lib.mkMerge [
    {
      # 全エージェント共通の規約。3ハーネスが別々の場所を見るので同じ実体へ3本張る
      ".claude/CLAUDE.md".source = link "AGENTS.md";
      ".codex/AGENTS.md".source = link "AGENTS.md";
      ".dsh/AGENTS.md".source = link "AGENTS.md";

      # lint スクリプト。AGENTS.md からはハーネス非依存の ~/.agents/hooks を案内する
      ".agents/hooks".source = link "hooks";
      ".claude/hooks".source = link "hooks";
    }

    # skill は Codex と DeepSeek が見る .agents と、Claude Code が見る .claude の両方へ。
    # ディレクトリごと張らないのは ~/.claude/skills/synced (claude.ai 同期) を巻き込まないため
    (skillLinks ".agents/skills")
    (skillLinks ".claude/skills")

    # サブエージェントとスラッシュコマンドは Claude Code へは素のまま渡す
    (lib.foldl' (acc: name: let
      root = plugins.${name};
    in
      acc
      // lib.listToAttrs (map (a:
        lib.nameValuePair ".claude/agents/${a}.md" {source = "${root}/agents/${a}.md";})
      (mdNames "${root}/agents"))
      // lib.listToAttrs (map (c:
        lib.nameValuePair ".claude/commands/${c}.md" {source = "${root}/commands/${c}.md";})
      (mdNames "${root}/commands"))) {} (builtins.attrNames plugins))

    # プラグインのルートを安定パスで見せる。
    # hook スクリプトがここからの相対で自分の位置を解決するので、
    # hook 設定に store path を書かずに済む
    (lib.mapAttrs' (n: root:
      lib.nameValuePair ".agents/plugins/${n}" {source = "${root}";})
    plugins)
  ];
```

- [ ] **Step 3: フォーマットを確認する**

Run: `alejandra --check modules/home/programs/ai-agents.nix`
Expected: `0 files changed`

- [ ] **Step 4: 変換スクリプトが Nix から呼べる形か確認する**

Run:

```bash
python3 ai/tools/md2skill.py --kind command --name revise-claude-md \
  "$(ls -d ~/.claude/plugins/cache/claude-plugins-official/claude-md-management/*/ | tail -1)commands/revise-claude-md.md" \
  /tmp/cmd-skill.md && head -4 /tmp/cmd-skill.md
```

Expected: `name: source-command-revise-claude-md` の行が出ること

- [ ] **Step 5: Commit**

```bash
git add modules/home/programs/ai-agents.nix
git commit -m "feat(home): skill とプラグインを全エージェントへ配る配線を追加"
```

---

### Task 9: settings.json と Codex の設定

Claude Code と Codex の設定をリポジトリ実体へ移し、hook を両方へ配線する。

#### Files

- Create: `ai/claude/settings.json`
- Create: `ai/codex/config.toml`
- Create: `ai/codex/hooks.json`
- Modify: `modules/home/programs/ai-agents.nix`

#### Interfaces

- Consumes: `ai/hooks/lint-md.sh` (Task 3)、`~/.agents/plugins/*` (Task 8)
- Produces: `~/.claude/settings.json`、`~/.codex/config.toml`、`~/.codex/hooks.json`

- [ ] **Step 1: Claude Code の設定を写す**

`ai/claude/settings.json`。現在の `~/.claude/settings.json` を土台に、macOS 固有の通知コマンドを落とし、hook のパスを新しい配置に直す。

```json
{
  "model": "opus",
  "theme": "dark",
  "effortLevel": "high",
  "modelSettings": {
    "claude-opus-5": {
      "effortLevel": "xhigh"
    }
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.agents/hooks/lint-md.sh",
            "timeout": 30
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "startup|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "\"$HOME/.agents/plugins/superpowers/hooks/run-hook.cmd\" session-start",
            "shell": "bash",
            "async": false
          },
          {
            "type": "command",
            "command": "CLAUDE_PLUGIN_ROOT=\"$HOME/.agents/plugins/ponytail\" node \"$HOME/.agents/plugins/ponytail/hooks/ponytail-activate.js\"",
            "timeout": 5
          }
        ]
      }
    ],
    "SubagentStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "CLAUDE_PLUGIN_ROOT=\"$HOME/.agents/plugins/ponytail\" node \"$HOME/.agents/plugins/ponytail/hooks/ponytail-subagent.js\"",
            "timeout": 5
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "CLAUDE_PLUGIN_ROOT=\"$HOME/.agents/plugins/ponytail\" node \"$HOME/.agents/plugins/ponytail/hooks/ponytail-mode-tracker.js\"",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

`enabledPlugins` と `extraKnownMarketplaces` は書かない。プラグインはマーケットプレイスではなく Task 8 の配線で入る。

- [ ] **Step 2: Codex の設定を書く**

`ai/codex/config.toml`:

```toml
# Codex の hook を有効化する。既定では無効
[features]
codex_hooks = true
```

`ai/codex/hooks.json`。Claude Code と同じスキーマなので、同じ内容を置く。

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.agents/hooks/lint-md.sh",
            "timeout": 30
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "startup|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "\"$HOME/.agents/plugins/superpowers/hooks/run-hook.cmd\" session-start",
            "shell": "bash",
            "async": false
          },
          {
            "type": "command",
            "command": "CLAUDE_PLUGIN_ROOT=\"$HOME/.agents/plugins/ponytail\" node \"$HOME/.agents/plugins/ponytail/hooks/ponytail-activate.js\"",
            "timeout": 5
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "CLAUDE_PLUGIN_ROOT=\"$HOME/.agents/plugins/ponytail\" node \"$HOME/.agents/plugins/ponytail/hooks/ponytail-mode-tracker.js\"",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 3: JSON が壊れていないことを確認する**

Run: `jq -e . ai/claude/settings.json ai/codex/hooks.json > /dev/null && echo "json ok"`
Expected: `json ok`

- [ ] **Step 4: 配線を足す**

`modules/home/programs/ai-agents.nix` の `home.file` の最初のブロックへ足す。

```nix
      # Claude Code と Codex の設定。どちらもハーネス自身が書き換えるので作業ツリーを直接指す
      ".claude/settings.json".source = link "claude/settings.json";
      ".codex/config.toml".source = link "codex/config.toml";
      ".codex/hooks.json".source = link "codex/hooks.json";
```

- [ ] **Step 5: フォーマットを確認する**

Run: `alejandra --check modules/home/programs/ai-agents.nix`
Expected: `0 files changed`

- [ ] **Step 6: Commit**

```bash
git add ai/claude ai/codex modules/home/programs/ai-agents.nix
git commit -m "feat(ai): Claude Code と Codex の設定と hook をリポジトリへ移動"
```

---

### Task 10: japanese-writing skill

stop-ai-slop-jp と k16shikano の2つの gist を、ジャンルで出し分ける1つの skill に統合する。

#### Files

- Create: `ai/skills/japanese-writing/SKILL.md`
- Create: `ai/skills/japanese-writing/references/llm-tells.md`
- Create: `ai/skills/japanese-writing/references/tech-docs.md`
- Create: `ai/skills/japanese-writing/references/long-form.md`
- Create: `ai/skills/japanese-writing/references/personal.md`
- Create: `ai/skills/japanese-writing/references/examples.md`

#### Interfaces

- Consumes: なし
- Produces: `japanese-writing` skill (Task 8 の `ownSkills` が自動で拾う)

出典は次の3つ。実装時に取得して中身を移す。

| 出典 | 取得先 |
| --- | --- |
| stop-ai-slop-jp | `~/.claude/skills/stop-ai-slop-jp/` (SKILL.md と references/ 3本) |
| japanese-tech-writing | `https://gist.github.com/k16shikano/fd287c3133457c4fd8f5601d34aa817d` |
| cognitive-rhythm-writing | `https://gist.github.com/k16shikano/eb2929f13ed19c97188393d297be8432` |

- [ ] **Step 1: 出典を手元に取る**

Run:

```bash
mkdir -p /tmp/jw-src
ax "https://api.github.com/gists/fd287c3133457c4fd8f5601d34aa817d" --body | jq -r '.files[].content' > /tmp/jw-src/tech-writing.md
ax "https://api.github.com/gists/eb2929f13ed19c97188393d297be8432" --body | jq -r '.files[].content' > /tmp/jw-src/cognitive-rhythm.md
cp -r ~/.claude/skills/stop-ai-slop-jp /tmp/jw-src/slop
wc -l /tmp/jw-src/*.md /tmp/jw-src/slop/SKILL.md
```

Expected: `tech-writing.md` 162行、`cognitive-rhythm.md` 134行、`slop/SKILL.md` 127行

- [ ] **Step 2: SKILL.md を書く**

`ai/skills/japanese-writing/SKILL.md`。役割はジャンルの判定と、読む reference の指定だけに絞る。

```markdown
---
name: japanese-writing
description: 日本語の文章を書く、直す、レビューするときに使う。技術文書、記事や書籍の原稿、個人のブログ、commit や PR の短文で適用するルールが違うため、まずジャンルを決めてから該当する reference だけを読む。AI が書いた日本語に出る癖の除去、論証の厳密さ、段落構成、認知リズム、主体性の回復を扱う。
---

# 日本語ライティング

## 最初にジャンルを決める

適用するルールはジャンルで変わる。技術文書に個人のブログ向けのルールを当てると逆効果になる
(README に毒や自虐を入れることになる)。書き始める前に下から1つ選ぶ。

| ジャンル | 対象 | 読む reference |
| --- | --- | --- |
| 技術文書 | README、docs/、設計書、API ドキュメント、コードコメント | `llm-tells.md`、`tech-docs.md` |
| 読み物 | 記事、書籍の章、解説、チュートリアル | `llm-tells.md`、`tech-docs.md`、`long-form.md` |
| 個人の文章 | ブログ、感想、ポエム | `llm-tells.md`、`personal.md` |
| 短文 | commit message、PR 説明、issue | `llm-tells.md` |

判断に迷ったら、その文章に**書き手個人の立場が要るか**で決める。要るなら個人の文章、
要らないなら技術文書。

## 全ジャンル共通

`references/llm-tells.md` は必ず読む。LLM が量産する空句、英語慣用句の直訳、
無生物主語の擬人化は、どのジャンルでも等しく害になる。

## textlint との分担

語彙と記号の機械的な判定は textlint に任せてある。この skill では扱わない。

- textlint が拾う: 偏愛語、全角ダッシュ、中黒での3項目並列、`**` の残骸、コロンの後の半角スペース
- この skill が扱う: false agency、論証の飛躍、命題型 H2、未回収の緊張、立場の不在

`.md` を書いたら `~/.agents/hooks/lint-md.sh <file>` を走らせる。

## 迷ったときの参照

`references/examples.md` に、AI 版と人間版の対比をジャンルのタグ付きで置いてある。
```

- [ ] **Step 3: references を5本書く**

出典から次のように振り分ける。原文の表現はできるだけ保ち、ジャンルに合わない項目だけ落とす。

`references/llm-tells.md` — `/tmp/jw-src/tech-writing.md` の「LLM っぽい表現の禁止」節と「翻訳調の比喩と擬人化の禁止」節をそのまま移す。

`references/tech-docs.md` — `/tmp/jw-src/tech-writing.md` の次の節を移す。

- 段落と論証の構成
- 論証の厳密さ
- 読み手の負荷の管理
- 冗長の排除
- 見出しの付け方
- 読者への誠実さ

`references/long-form.md` — `/tmp/jw-src/cognitive-rhythm.md` の全節と、`tech-writing.md` の「演出の抑制」節を移す。`tech-writing.md` の「視点と語り」節のうち、架空の人物設定と二人称に関する項目もここへ入れる。

`references/personal.md` — `/tmp/jw-src/slop/SKILL.md` の「大原則」と「コアルール」の A と B、「クイックチェック」の構造レベルと強度と立場、「採点」、「修正の優先順位」を移す。コアルール C (語彙と記号) は textlint が拾うので落とす。

`references/examples.md` — `/tmp/jw-src/slop/references/examples.md` の17本に、各例へジャンルのタグ (`[個人]` `[技術文書]` `[読み物]`) を付ける。`tech-writing.md` の「悪い例 / 良い例」もタグ付きで足す。

- [ ] **Step 4: lint を通す**

Run: `markdownlint --config ai/hooks/markdownlint.jsonc ai/skills/japanese-writing/SKILL.md ai/skills/japanese-writing/references/*.md`
Expected: 出力なし

- [ ] **Step 5: 分担が守れているか確認する**

Run: `rg -n '泥臭さ|手触り|解像度|──' ai/skills/japanese-writing/references/*.md`
Expected: `examples.md` の中の例としてのみ出現すること。ルールとしての禁止リストが残っていたら落とす (textlint の担当)

- [ ] **Step 6: Commit**

```bash
git add ai/skills/japanese-writing
git commit -m "feat(ai): 日本語ライティングの統合 skill を追加"
```

---

### Task 11: rust-guidelines ラッパと vq の呼び出し口

#### Files

- Create: `ai/skills/rust-guidelines/SKILL.md`
- Create: `pkgs/vq.nix`
- Modify: `modules/nixos/overlays.nix`
- Modify: `modules/home/programs/ai-agents.nix`
- Modify: `nvim/lua/polish.lua`

#### Interfaces

- Consumes: `ai/vq/vq.py` (Task 4)、`inputs.rust-guidelines` (Task 6)
- Produces: `pkgs.vq`、`rust-guidelines` skill、nvim の `:Vq`

- [ ] **Step 1: rust-guidelines の SKILL.md を書く**

`ai/skills/rust-guidelines/SKILL.md`。連結版は 135KB あるので全部は読ませず、索引だけ置く。

```markdown
---
name: rust-guidelines
description: Rust を書く、直す、レビューするときに使う。Microsoft の Pragmatic Rust Guidelines を参照し、API 設計、安全性、正しさ、ドキュメント、AI から使いやすい設計の指針を示す。該当するカテゴリだけを読むための索引。
---

# Pragmatic Rust Guidelines

Microsoft の [Pragmatic Rust Guidelines](https://microsoft.github.io/rust-guidelines/) を引く。

## 読み方

全部で 135KB ある。**全部は読まない。** 下の表から該当するカテゴリを1つか2つ選び、
`references/<category>/` の中の `M-*.md` だけを読む。各ファイルは1つの指針で完結している。

| カテゴリ | いつ読むか |
| --- | --- |
| `universal` | すべての Rust コード。まずここ |
| `libs` | ライブラリや crate の公開 API を設計するとき |
| `apps` | アプリケーションを書くとき |
| `safety` | `unsafe` を書くとき、FFI を触るとき |
| `correctness` | 不変条件、エラー処理、型で誤用を防ぐとき |
| `docs` | 公開 API のドキュメントを書くとき |
| `ai` | エージェントが触る前提で API を設計するとき |

## 指針の引き方

各指針には `M-DESIGN-FOR-AI` のような ID が振ってある。レビューで指摘するときは ID を添える。

`references/<category>/README.md` にそのカテゴリの概要がある。迷ったらそこから入る。
```

- [ ] **Step 2: vq のパッケージを書く**

`vq.py` は `SUMMARY_PATH` で自分の隣の `config-summary.md` を読む。`writers.writePython3Bin` は
スクリプト1ファイルしか store に置かないので使えない。両方を同じディレクトリに置いてから bin を作る。

`pkgs/vq.nix`:

```nix
# 自分の vim 設定を踏まえてコマンドを提案する CLI
#
# エージェントのハーネスを経由せず、Haiku へ単発の API コールを投げるだけ。
# vq.py が隣の config-summary.md を読むので、2つを同じディレクトリへ置いてから
# ラッパを作る
{
  python3,
  runCommand,
  makeWrapper,
  aiDir ? ../ai,
}: let
  python = python3.withPackages (ps: [ps.anthropic]);
in
  runCommand "vq" {
    nativeBuildInputs = [makeWrapper];
  } ''
    mkdir -p $out/libexec/vq $out/bin
    cp ${aiDir}/vq/vq.py $out/libexec/vq/vq.py
    cp ${aiDir}/vq/config-summary.md $out/libexec/vq/config-summary.md
    makeWrapper ${python}/bin/python3 $out/bin/vq \
      --add-flags "$out/libexec/vq/vq.py"
  ''
```

- [ ] **Step 3: overlay と home.packages に足す**

`modules/nixos/overlays.nix` の dotnix 自前パッケージのブロックへ足す。

```nix
      vq = final.callPackage ../../pkgs/vq.nix {};
```

`modules/home/programs/ai-agents.nix` の `home.packages` の「人間用」ブロックへ足す。

```nix
    pkgs.vq # vim のコマンドを思い出すための CLI
```

rust-guidelines の本文は上流にあるので、`references` だけを別に張る。`ai/skills/rust-guidelines/`
は SKILL.md しか持たず、`skillLinks` はディレクトリごと張るため、`references` は後から重ねる。

`home.file` の最初のブロック (AGENTS.md を張っているところ) へ足す。

```nix
      # rust-guidelines の索引 SKILL.md は ai/skills/ にあり、
      # 本文 135KB は上流の src/guidelines/ を references として見せる
      ".agents/skills/rust-guidelines/references".source = "${inputs.rust-guidelines}/src/guidelines";
      ".claude/skills/rust-guidelines/references".source = "${inputs.rust-guidelines}/src/guidelines";
```

- [ ] **Step 4: nvim に :Vq を足す**

`nvim/lua/polish.lua` の末尾へ足す。

```lua
-- vim から離れずにコマンドを尋ねる。結果をポップアップに出す
-- systemlist は完了を待つのでストリーミングの恩恵は受けない
vim.api.nvim_create_user_command("Vq", function(opts)
  local lines = vim.fn.systemlist({ "vq", opts.args })
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_open_win(buf, false, {
    relative = "cursor",
    row = 1,
    col = 0,
    width = 60,
    height = math.min(#lines, 10),
    border = "rounded",
    style = "minimal",
  })
end, { nargs = "+", desc = "vq に vim コマンドを尋ねる" })
```

- [ ] **Step 5: 検証する**

Run:

```bash
markdownlint --config ai/hooks/markdownlint.jsonc ai/skills/rust-guidelines/SKILL.md
alejandra --check pkgs/vq.nix modules/nixos/overlays.nix modules/home/programs/ai-agents.nix
```

Expected: どちらも出力なし

- [ ] **Step 6: Commit**

```bash
git add ai/skills/rust-guidelines pkgs/vq.nix modules/nixos/overlays.nix modules/home/programs/ai-agents.nix nvim/lua/polish.lua
git commit -m "feat(ai): rust-guidelines の索引 skill と vq の呼び出し口を追加"
```

---

### Task 12: ai_knowledge の内容移植と docs の整備

`santamn/ai_knowledge` を廃止し、内容を dotnix へ取り込む。

#### Files

- Create: `docs/ai-agents.md`
- Modify: `AGENTS.md` (リポジトリのディレクトリ構成の節)
- Modify: `README.md`

#### Interfaces

- Consumes: Task 1 から 11 のすべて
- Produces: `docs/ai-agents.md`

- [ ] **Step 1: docs/ai-agents.md を書く**

構成の説明と、増やし方の手順を書く。`ai_knowledge` の `current-status.md` と `cli-for-ai.md` にある情報のうち、コードで表現できていないものだけを移す。

節は次の4つにする。

1. **構成** — `ai/` の中身と、どのエージェントがどこを見るかの表 (spec の「全体構造」から)
2. **skill を足す** — `ai/skills/<name>/SKILL.md` を作って rebuild するだけであること。外部由来なら flake input を足して `externalSkills` に1行
3. **プラグインを足す** — `plugins` に1行足すと skills/agents/commands/hooks が自動で配られること
4. **秘密情報** — `vq` の API キーと GitHub MCP のトークンはリポジトリに置かないこと。[#12](https://github.com/santamn/dotnix/issues/12) を参照

- [ ] **Step 2: AGENTS.md のディレクトリ構成に足す**

`AGENTS.md` の「Directory Structure」の `nvim/` の行の後に足す。

```markdown
- `ai/` — AI エージェント共通の規約・skill・hook。`~/.agents/` と `~/.claude/` と `~/.codex/` から参照される。nvim/ と同じく rebuild なしで反映される (詳細は [ai-agents.md](docs/ai-agents.md) を参照)
- `pkgs/` — nixpkgs に無いパッケージの定義。`modules/nixos/overlays.nix` から `callPackage` で読む
```

- [ ] **Step 3: lint を通す**

Run: `markdownlint --config ai/hooks/markdownlint.jsonc docs/ai-agents.md AGENTS.md README.md`
Expected: 出力なし

- [ ] **Step 4: Commit**

```bash
git add docs/ai-agents.md AGENTS.md README.md
git commit -m "docs: AI エージェント環境の構成と増やし方を追加"
```

- [ ] **Step 5: ai_knowledge の廃止をユーザに依頼する**

このリポジトリからは操作しない。ユーザに `santamn/ai_knowledge` を archive するよう伝える。

---

### Task 13: NixOS マシンでの検証

**このタスクは作業機 (macOS) では実行できない。** 各ステップをユーザに依頼する。

#### Files

- Modify: `pkgs/textlint-rule-preset-ai-words-ja.nix` (hash)
- Modify: `pkgs/textlint-rule-preset-ai-writing.nix` (hash)
- Modify: `pkgs/go-modern-guidelines.nix` (vendorHash)
- Modify: `flake.lock`

- [ ] **Step 1: flake.lock を更新してもらう**

依頼するコマンド: `nix flake lock`

- [ ] **Step 2: 依存のハッシュを3つ確定してもらう**

依頼するコマンド:

```bash
nix build .#nixosConfigurations.thinkpad-x13-gen6.pkgs.textlint-rule-preset-ai-words-ja 2>&1 | grep -A2 'got:'
nix build .#nixosConfigurations.thinkpad-x13-gen6.pkgs.textlint-rule-preset-ai-writing 2>&1 | grep -A2 'got:'
nix build .#nixosConfigurations.thinkpad-x13-gen6.pkgs.go-modern-guidelines 2>&1 | grep -A2 'got:'
```

出てきた `got:` の値を `lib.fakeHash` と置き換える。3つとも通るまで繰り返す。

- [ ] **Step 3: flake check と rebuild を依頼する**

依頼するコマンド: `nix flake check` の後に `sudo nixos-rebuild switch --flake .`

- [ ] **Step 4: spec の検証項目を1つずつ確認してもらう**

[spec の「検証」節](../specs/2026-09-19-ai-agent-env.md)の12項目を上から確認する。

1. `nix flake check` が通る
2. `~/.agents/skills/` と `~/.claude/skills/` に同じ skill が並ぶ
3. `claude` と `codex` の両方で `japanese-writing` が候補に出る
4. `ax`、`sem`、`ast-grep`、`hunk`、`zat`、`textlint`、`markdownlint`、`jq`、`vq` が PATH にある
5. `sem --version` が ataraxy-labs 版を返す
6. 日本語を含む `.md` を書くと `claude` と `codex` の両方で `lint-md.sh` が発火する
7. `claude` で `/revise-claude-md` が出る
8. `claude` で `code-simplifier` サブエージェントが選べる
9. `codex` で `code-simplifier` と `source-command-revise-claude-md` が skill として出る
10. `codex` のセッション開始時に superpowers と ponytail の hook が発火する
11. `git diff` の表示が delta のまま
12. `~/.dsh/AGENTS.md` が `ai/AGENTS.md` を指している

- [ ] **Step 5: config-summary.md を実機で作り直してもらう**

`ai/vq/README.md` の手順を実行してもらい、暫定版を置き換える。

- [ ] **Step 6: Commit**

```bash
git add pkgs flake.lock ai/vq/config-summary.md
git commit -m "fix(pkgs): 依存のハッシュを確定し、vq の設定要約を実機の値に更新"
```
