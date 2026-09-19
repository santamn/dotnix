# AI エージェント環境

Claude Code、Codex、DeepSeek Harness で同じ skill と規約を使うための構成。
設計の経緯は [specs/2026-09-19-ai-agent-env.md](specs/2026-09-19-ai-agent-env.md) にある。

## 構成

`ai/` が唯一の実体で、各エージェントの探索パスからリンクを張っている。
自作のものは作業ツリーを直接指すので、編集すれば rebuild なしに効く (`nvim/` と同じ方式)。

```text
ai/
  AGENTS.md          # 全エージェント共通の規約
  skills/            # 自作 skill
  tools/md2skill.py  # agents/commands 定義を SKILL.md へ変換
  hooks/lint-md.sh   # markdownlint と textlint
  textlintrc.json
  claude/settings.json
  codex/{config.toml,hooks.json}
  vq/                # Vim コマンド提案 CLI (人間用)
```

どのエージェントがどこを見るか。

| 見るもの | Claude Code | Codex | DeepSeek Harness |
| --- | --- | --- | --- |
| 全体規約 | `~/.claude/CLAUDE.md` | `~/.codex/AGENTS.md` | `~/.dsh/AGENTS.md` |
| skill | `~/.claude/skills/` | `~/.agents/skills/` | `~/.agents/skills/` |
| サブエージェント | `~/.claude/agents/` | (skill に変換) | (skill に変換) |
| スラッシュコマンド | `~/.claude/commands/` | (skill に変換) | (skill に変換) |
| hook | `~/.claude/settings.json` | `~/.codex/hooks.json` | ブリッジプラグイン経由 |

Claude Code と Codex は hook のスキーマが同じなので、同じ定義を両方に入れてある。
DeepSeek は `dsh-hooks-claude-code` と `dsh-hooks-codex` というブリッジを持っていて、
既存の `hooks.json` をそのまま実行できる。

## skill を足す

自作するなら `ai/skills/<name>/SKILL.md` を作るだけでよい。rebuild すれば
`~/.agents/skills/` と `~/.claude/skills/` の両方に並ぶ。中身の編集は rebuild が要らない。

外部から持ってくるなら2手順。

1. `flake.nix` の inputs に `flake = false` で足す
2. `modules/home/programs/ai-agents.nix` の `externalSkills` に `名前 = "パス";` を1行足す

## プラグインを足す

`modules/home/programs/ai-agents.nix` の `plugins` に1行足す。`skills/` `agents/`
`commands/` が自動で配られる。`hooks/` だけは `ai/claude/settings.json` と
`ai/codex/hooks.json` に手で書く。

hook のコマンドでは store path ではなく `$HOME/.agents/plugins/<name>` を指すこと。
input を更新するたびに設定ファイルを書き換えずに済む。

取り込む前に、本文がモデル名やハーネス固有の機能に依存していないか確認する。
依存しているものは、形式だけ変換しても他エージェントでは動かない
(公式の `code-review` プラグインを入れていないのはこれが理由)。

## マーケットプレイスは使わない

Claude Code の `~/.claude/plugins/` のキャッシュ構造は内部実装なので Nix で再現すると脆く、
そもそも Claude Code しか読まない。プラグインの中身は素のファイルなので、種類ごとに
各エージェントが直接読む場所へ配っている。

代わりに `/plugin-name:command` という名前空間は失う。衝突したら張る側でリネームする。

## 秘密情報

このリポジトリには秘密情報を置かない。管理機構もまだ無い。

- `vq` の API キー: `ANTHROPIC_API_KEY`、無ければ `$XDG_CONFIG_HOME/vq/api-key`
- GitHub MCP のトークン: 未定。[#12](https://github.com/santamn/dotnix/issues/12) で決める

sops-nix や agenix を入れるなら、この2つをまとめて扱えるようにする。

## 未対応

- Serena と GitHub の MCP サーバ ([#12](https://github.com/santamn/dotnix/issues/12))
- `@deepseek-ai/dsh` 本体のパッケージ化。nixpkgs になく flake も無い alpha 版なので、使い始めるときに別途立てる。探索パスの配線だけ先に入れてある
- ponytail の MCP サーバと statusline
