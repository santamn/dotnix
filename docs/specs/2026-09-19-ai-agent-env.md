# AI エージェント開発環境の設計

対応 issue: [#9](https://github.com/santamn/dotnix/issues/9)

## 目的

Claude Code 専用に組んである今の環境を、Claude Code と Codex と DeepSeek Deep Code のどれからでも同じものが見える形に組み直し、NixOS 上で宣言的に再現できるようにする。

## 前提となる調査結果

- クロスエージェントの skill 探索パスは `~/.agents/skills/<name>/SKILL.md`。Codex と Deep Code はここを見る。Claude Code だけが `~/.claude/skills/` を見る
- `hunk` (0.21.1)、`zat` (0.5.3)、`claude-code`、`codex`、`textlint`、`markdownlint-cli`、`gh` は nixpkgs にある
- `hunk` は nixpkgs 版が `$out/share/skills/hunk/{hunk-review,hunk-extensions}/SKILL.md` を同梱する
- Claude Code のプラグインは、マニフェスト (`.claude-plugin/plugin.json`) だけが Claude 固有で、中身の `skills/<name>/SKILL.md` は Agent Skills 形式そのもの。`skills/` を `~/.agents/skills/` に張れば他エージェントからも使える
- Claude Code はプラグイン機構を経由せずに `~/.claude/skills/`、`~/.claude/commands/`、`~/.claude/agents/` を直接読む。公式プラグインは `anthropics/claude-plugins-official` の `plugins/<name>/` に素のファイルとして置いてあるので、張るだけで入る
- **hook は Claude 固有ではない。** Codex は `~/.codex/hooks.json` を同じスキーマで読む (`SessionStart`、`UserPromptSubmit`、`PreToolUse`、`PostToolUse`、`SubagentStop`、`Stop`)。`config.toml` に `[features] codex_hooks = true` が要る。ponytail が hook ファイルを `claude-codex-hooks.json` という名前で1本にまとめているのはこのため
- Codex は plugin hook に `PLUGIN_ROOT` と `PLUGIN_DATA` を渡し、既存の Claude プラグインとの互換のため `CLAUDE_PLUGIN_ROOT` と `CLAUDE_PLUGIN_DATA` も渡す
- Codex はプラグインの `commands/*.md` を起動時に skill へ変換する (`codex-rs/core-plugins/src/command_migration.rs`)。`source-command-<slug>` という名前の skill になり、frontmatter に `description` が必須で、4000 バイトを超えるものは落とされる
- superpowers は `.codex-plugin/`、`.cursor-plugin/`、`.devin-plugin/`、`.hermes-plugin/`、`.kimi-plugin/`、`.muse-plugin/`、`.opencode/`、`.pi/`、`.agents/plugins/` と、ルートに `AGENTS.md`・`GEMINI.md` を持つ。ponytail も `gemini-extension.json`、`opencode.json`、`pi-extension/`、`AGENTS.md` を持つ。どちらもマルチハーネス前提で作られている
- `ax` は nixpkgs にないが、リポジトリが `flake.nix` と `package.nix` を同梱している
- `sem` は nixpkgs にもあるが、それは semaphoreci/cli であって ataraxy-labs/sem とは別物。名前が衝突しているので nixpkgs の `sem` は使えない。ataraxy-labs/sem も `flake.nix` と `package.nix` を同梱している
- `serena` は nixpkgs にないため本設計の範囲外とし、[#12](https://github.com/santamn/dotnix/issues/12) に分離した

## 全体構造

`dotnix/ai/` を唯一の実体とし、各エージェントの探索パスからリンクを張る。

```text
dotnix/ai/
  AGENTS.md                  # 全エージェント共通の規約
  claude/settings.json       # Claude Code の設定 (Claude Code 自身が書き換える)
  hooks/
    lint-md.sh               # markdownlint と textlint をまとめて走らせる
    markdownlint.jsonc
  textlintrc.json
  skills/
    japanese-writing/
    rust-guidelines/
  vq/
    vq.py
    config-summary.md
    README.md
```

張るリンクは次の通り。

| リンク元 | リンク先 | 種別 |
| --- | --- | --- |
| `~/.agents/skills/<name>` | `ai/skills/<name>` または input の store path | 自作は out-of-store |
| `~/.claude/skills/<name>` | 同上 | 同上 |
| `~/.claude/commands/<name>.md` | 各プラグインの `commands/` | store path |
| `~/.claude/agents/<name>.md` | 各プラグインの `agents/` | store path |
| `~/.agents/plugins/<name>` | 各プラグインのルート | store path |
| `~/.codex/AGENTS.md` | `ai/AGENTS.md` | out-of-store |
| `~/.claude/CLAUDE.md` | `ai/AGENTS.md` | out-of-store |
| `~/.dsh/AGENTS.md` | `ai/AGENTS.md` | out-of-store |
| `~/.claude/settings.json` | `ai/claude/settings.json` | out-of-store |
| `~/.codex/hooks.json` | `ai/codex/hooks.json` | out-of-store |
| `~/.codex/config.toml` | `ai/codex/config.toml` | out-of-store |
| `~/.claude/hooks` | `ai/hooks` | out-of-store |
| `~/.agents/hooks` | `ai/hooks` | out-of-store |

`~/.agents/plugins/<name>` はプラグインのルートを指す安定パスとして置く。hook スクリプトが `${CLAUDE_PLUGIN_ROOT}` や自身のパスからプラグインルートを解決するため、store path を直接 hook 設定に書くと input 更新のたびに `settings.json` を書き換える羽目になる。間に安定パスを挟んでこれを避ける。

自作 skill と `AGENTS.md` は `config.lib.file.mkOutOfStoreSymlink` で張る。`nvim/` と同じ方式で、編集すれば rebuild なしに効く。

`~/.claude/skills` をディレクトリごと張る案は採らない。claude.ai から同期される `~/.claude/skills/synced/` を巻き込むため、skill ごとに張る。

配線は `ai/skills/` と各 input の skill ディレクトリを `builtins.readDir` で走査して生成する。skill を1つ足すときに nix を書く必要はなく、rebuild だけで済む。

## パッケージ

新設する `modules/home/programs/ai-agents.nix` に置く。

nixpkgs から入るもの。

- `claude-code`
- `codex`
- `hunk`
- `zat`
- `ast-grep`
- `markdownlint-cli`
- `textlint` (`withPackages` でプリセットを束ねる)
- `gh`
- `jq` (`lint-md.sh` が hook の入力を読むのに使う。現在 `packages.nix` に無い)

`fd` と `ripgrep` は既に `modules/home/packages.nix` にある。

flake input から入れるもの。どちらも上流が `flake.nix` と `package.nix` を同梱しているので、`packages.<system>.default` をそのまま使う。

| パッケージ | 上流 | 備考 |
| --- | --- | --- |
| `ax` | yusukebe/ax | nixpkgs に無い |
| `sem` | ataraxy-labs/sem | nixpkgs の `sem` は semaphoreci/cli で別物。名前が衝突するので `home.packages` には input 側を入れる |

`modules/nixos/overlays.nix` で自前パッケージ化するもの。

| パッケージ | 上流 | 手段 |
| --- | --- | --- |
| `textlint-rule-preset-ai-words-ja` | p1ass/textlint-rule-preset-ai-words-ja | pnpm。`pnpm-lock.yaml` があるので `fetchPnpmDeps` + `pnpmConfigHook`。実行時依存は kuromojin と morpheme-match-textlint の2つ |
| `textlint-rule-preset-ai-writing` | textlint-ja/textlint-rule-preset-ai-writing | npm。`package-lock.json` があるので `buildNpmPackage` |
| `go-modern-guidelines` | JetBrains/go-modern-guidelines | `buildGoModule` |

`textlint-rule-preset-ja-technical-writing` は nixpkgs にあるのでそのまま使う。

textlint のプリセット構成は次の3つとする。

1. `preset-ai-words-ja` — AI が使いがちな単語と言い回し
2. `preset-ai-writing` — AI が使いがちな構造 (リストの形、見出しの強調、コロン)
3. `preset-ja-technical-writing` — 一文の長さ、二重否定、漢字の連続など

### hunk と delta の衝突

`hunk` の home-manager モジュールは `enableGitIntegration` で git の pager を奪う。`programs.delta` が既に pager を設定しているため、`enableGitIntegration = false` とし、`hunk` は独立したコマンドとして使う。`git diff` の見た目は delta のままにする。

## skill

`~/.agents/skills/` と `~/.claude/skills/` の両方に張るもの。

| skill | 出所 | 備考 |
| --- | --- | --- |
| `japanese-writing` | 新規 | ジャンルの振り分け役。後述 |
| `ast-grep` | ast-grep/agent-skill | 既存。flake input で pin |
| `sem` | ataraxy-labs/sem | 既存。`llms.txt` を SKILL.md として置く |
| `stop-ai-slop-jp` | iKora128/stop-ai-slop-jp | 文章規範。個人の文章にだけ当てる |
| `japanese-tech-writing`, `cognitive-rhythm-writing` | k16shikano の gist | 文章規範。上流が兄弟配置を前提にしている |
| `hunk-review`, `hunk-extensions` | `pkgs.hunk` 同梱 | store path から張る |
| `use-modern-go` | JetBrains/go-modern-guidelines | CLI `go-modern-guidelines` を呼ぶ |
| `modern-python`, `modern-cpp`, `property-based-testing`, `gh-cli` | trailofbits/skills | plugins/\<name\>/skills/\<name\> を張る |
| `rust-guidelines` | 新規ラッパ | 後述 |
| プラグイン由来 | 後述 | 各プラグインの `skills/` を張る |

### rust-guidelines ラッパ

microsoft/rust-guidelines は SKILL.md を持たず、`src/guidelines/<category>/M-*.md` という形で置いてある。`scripts/agents_summary.sh` が全部を1ファイル (135KB, 約3500行) に連結するが、これをそのまま読ませると文脈を食い潰す。

そこで `ai/skills/rust-guidelines/SKILL.md` を自前で書き、`references/` に上流の `src/guidelines/` を張る。SKILL.md にはカテゴリの索引だけを置き、該当するカテゴリの `M-*.md` だけを読ませる。

カテゴリは `universal`、`apps`、`libs`、`safety`、`correctness`、`docs`、`ai`。

### trailofbits/skills の選定

上流には50個以上の skill がある。description が全部文脈に載るとノイズになるため、次の3つを張る。必要になれば足す。

- `modern-python`
- `property-based-testing`
- `gh-cli`

## プラグインの取り込み

マーケットプレイス機構は使わない。`~/.claude/plugins/` 配下のキャッシュ構造を Nix で再現するのは Claude Code の内部実装に依存して脆く、そもそも Claude Code しか読まない。

代わりに、プラグインを flake input で pin し、中身の種類ごとに Claude Code と Codex の両方が直接読む場所へ配る。プラグインの中身は素のファイルなので、これで足りる。

### 取り込むプラグイン

| プラグイン | 上流 | 中身 |
| --- | --- | --- |
| `superpowers` | obra/superpowers | `skills/` + `hooks/` |
| `ponytail` | DietrichGebert/ponytail | `skills/` + `commands/` + `hooks/` + MCP |
| `humanizer` | blader/humanizer | `SKILL.md` + `agents/` |
| `skill-creator` | anthropics/claude-plugins-official | `skills/` |
| `claude-md-management` | 同上 | `commands/` + `skills/` |
| `code-simplifier` | 同上 | `agents/` |

`code-review` プラグインは入れない。本文が「Haiku エージェントに確認させる」「Sonnet エージェントを5つ並列で起動する」という形で Claude のサブエージェントとモデル名に依存していて、他エージェントへ持っていっても素直には動かない。Claude Code には同名の組み込み skill (`/code-review`) があり、そちらはハーネスが面倒を見るので、プラグイン版を捨てても Claude 側で失うものはない。

superpowers と ponytail は上流を直接 pin する。公式マーケットプレイス経由のコピーより上流のほうが新しく、マルチハーネス用のアダプタも揃っている。

### 種類ごとの配り方

| 中身 | Claude Code | Codex と Deep Code |
| --- | --- | --- |
| `skills/<name>/` | `~/.claude/skills/<name>` へ symlink | `~/.agents/skills/<name>` へ symlink |
| `agents/<name>.md` | `~/.claude/agents/<name>.md` へ symlink | `~/.agents/skills/<name>/SKILL.md` を生成 |
| `commands/<name>.md` | `~/.claude/commands/<name>.md` へ symlink | `~/.agents/skills/source-command-<name>/SKILL.md` を生成 |
| `hooks/*.json` | `ai/claude/settings.json` に取り込む | `ai/codex/hooks.json` に取り込む |
| プラグインルート | | `~/.agents/plugins/<name>` へ symlink |

### agents と commands から skill を生成する

サブエージェントの定義 (`agents/<name>.md`) は frontmatter の `name` と `description`、それに本文という構造で、SKILL.md と同じ形をしている。`model:` などの Claude 固有のキーを落とすだけで skill になる。

コマンド (`commands/<name>.md`) も同様に frontmatter と本文で、Codex 自身が起動時に `source-command-<slug>` という skill へ変換している。同じ変換を Nix の build 時に行い、生成物を `~/.agents/skills/` に置く。命名は Codex に合わせる。

変換は `runCommand` の中で走る小さなスクリプトで行う。やることは frontmatter の抽出、`name` と `description` の書き出し、`CLAUDE.md` を `AGENTS.md` に置換、の3つだけ。

Claude Code 側では `context: fork` と `agent:` を frontmatter に足せばサブエージェントとして動くので、`code-simplifier` は Claude では今まで通り別コンテキストで走り、他エージェントでは通常の skill として動く。

### hook の配り方

Codex は `~/.codex/hooks.json` を Claude Code と同じスキーマで読む。`ai/codex/config.toml` に `[features] codex_hooks = true` を入れる。

hook スクリプトはプラグインルートからの相対パスで自分の位置を解決する。superpowers の `hooks/session-start` は自身のパスから、ponytail の hook は `${CLAUDE_PLUGIN_ROOT}` から解決する。`~/.agents/plugins/<name>` を安定パスとして張り、hook のコマンド文字列では次のように書く。

```sh
CLAUDE_PLUGIN_ROOT="$HOME/.agents/plugins/ponytail" node "$HOME/.agents/plugins/ponytail/hooks/ponytail-activate.js"
```

これで `settings.json` と `hooks.json` に store path が入らず、input を更新してもリポジトリのファイルを書き換えずに済む。

### 限界

取り込むものを選ぶ基準は「本文がモデル名やハーネスの機能に依存していないか」とする。依存しているものは、形式だけ変換しても動かない。

Codex 自身のコマンド移行も、プラグイン由来のものについては `CLAUDE.md` から `AGENTS.md` への置換しか行わず、モデル名は直さない。さらに4000バイトを超えるコマンドは落とす。自前で変換すればサイズ制限は回避できるが、内容の依存は残る。

残す `claude-md-management` のコマンドは1357バイトで、本文もモデルに依存しない。`code-simplifier` も本文がコーディング指針なので、そのまま skill として機能する。

`/plugin-name:command` の名前空間は失う。`/revise-claude-md:revise-claude-md` は `/revise-claude-md` になる。衝突したら張る側でリネームする。

## DeepSeek Harness での成立

[deepseek-ai/deepseek-harness](https://github.com/deepseek-ai/deepseek-harness) の実装を読んで確認した。結論として**この設計はほぼそのまま通る**が、リンクが1本足りない。

### skill の探索パス

`docs/subsystems/skills.md` にある local provider の走査順。

| Rank | Source | Root |
| --- | --- | --- |
| 100 | `project-dsh` | `<projectRoot>/.dsh/skills` |
| 200 | `project-agents` | `<projectRoot>/.agents/skills` |
| 300 | `custom` | `Config.customSkillDirs` |
| 400 | `user-dsh` | `<dshHome>/skills` |
| 500 | `user-agents` | `<agentsHome>/skills` |
| 600 | `bundled` | `Config.bundledSkillDir` |

`agentsHome` は `$DSH_AGENTS_HOME` か `~/.agents` が既定。rank 500 の `user-agents` が我々の `~/.agents/skills` にそのまま当たる。

### hook

`packages/hooks/` に `dsh-hooks-claude-code` と `dsh-hooks-codex` という2つのブリッジプラグインがある。**既存の `hooks.json` をそのまま実行する**ための仕組みで、書き直しは要らない。

| Field | 渡す値 |
| --- | --- |
| `configPath` | `~/.claude/settings.json` または `~/.codex/hooks.json` |
| `pluginRoot` | `${CLAUDE_PLUGIN_ROOT}` の置換先。`~/.agents/plugins/<name>` を渡す |
| `projectDir` | `${CLAUDE_PROJECT_DIR}` の置換先 |

`pluginRoot` フィールドがあるおかげで、安定パスを挟む設計がそのまま効く。

### commands と agents

DeepSeek のコマンドレジストリはプラグインが所有するもので、Claude や Codex のコマンドファイルは読まない。サブエージェントも独自の仕組みを持つ。

ただし我々は `commands/` と `agents/` を skill へ変換して `~/.agents/skills/` に置くので、どちらも skill 経路で届く。変換を挟む設計がここで効く。

### 足りないリンク

DeepSeek のユーザ全体規約は `~/.agents/AGENTS.md` ではない。`dshHome` の説明にある通り「`AGENTS.md` を含む harness home」は `$DSH_HOME` か `~/.dsh` で、規約はそこに固定で置かれる。リンクを1本足す。

| リンク元 | リンク先 |
| --- | --- |
| `~/.dsh/AGENTS.md` | `ai/AGENTS.md` |

### インストール自体

`@deepseek-ai/dsh` は nixpkgs になく、リポジトリに `flake.nix` も無い。pnpm のモノレポで、バージョンは `0.1.6-alpha.2` とまだ alpha。

配線は用意しておくが、パッケージ化と実機での検証は DeepSeek を実際に使い始めるときに回す。`~/.dsh/AGENTS.md` のリンクと `~/.agents/skills` は DeepSeek の有無に関係なく張れるので、今回入れる。hook ブリッジの composition 設定だけは、設定ファイルの正確な位置を導入時に確認する。

## japanese-writing skill

文章規範は3本とも上流そのままを独立した skill として置き、`japanese-writing` はジャンルの判定と振り分けだけを持つ。

### 振り分けにした理由

当初は3本を1つの skill へ統合し、`references/` に抜粋を置く設計だった。実装中に2点わかって方針を変えた。

1. `cognitive-rhythm-writing` の SKILL.md は冒頭で `../japanese-tech-writing/SKILL.md` を読むよう指示している。上流はこの2本が skill ディレクトリに兄弟として並ぶ前提で書かれており、抜粋するとこの連携が壊れる
2. 3本のうち2本は description が既にジャンルで絞られている。`japanese-tech-writing` は「技術書の章、草稿、記事、解説文を書くとき」、`cognitive-rhythm-writing` は「読み物として読ませたい章・記事・解説文」。誤発火の心配は上流が解決済みだった

抜粋には固有の価値がなく、上流が更新されれば腐るだけなので削除した。

### 供給元

| skill | 上流 | input の形 |
| --- | --- | --- |
| `japanese-tech-writing` | k16shikano の gist | `git+https://gist.github.com/...` |
| `cognitive-rhythm-writing` | k16shikano の gist | 同上 |
| `stop-ai-slop-jp` | iKora128/stop-ai-slop-jp | `github:` |

gist は git リポジトリなので、そのまま `flake = false` の input にできる。どちらも `SKILL.md` がリポジトリのルートにある。

### japanese-writing が持つもの

- ジャンルの判定表と、そのジャンルで読む規範 skill の指定
- 間違えやすい組み合わせの明示
- textlint との分担
- `references/examples.md`: 3出典を横断した AI 版と人間版の対比。ジャンルタグ付き

### 残るリスク

`stop-ai-slop-jp` の description は「AIで書いた日本語を、人間が書いた文章に戻す」と広く、技術文書にも発火する。「毒を許す」「中間温度を混ぜる」を README に当てると読みにくくなる。

上流の description を書き換えると fork になるので避け、`ai/AGENTS.md` に「日本語は `japanese-writing` から入る。規範 skill を直接掴まない」と明記して防ぐ。AGENTS.md は常に読まれるので、hook より確実である。

## vq (Vim コマンド提案 CLI)

skill としては作らない。エージェントのハーネスを経由すると、起動、ツール定義のロード、発火判定、SKILL.md の読み込みといった固定コストが推論時間を上回る。このタスクはファイル探索も編集もツール呼び出しも要らないので、Haiku への単発 API コールを投げるだけの薄い CLI にする。

### 構成

```text
ai/vq/
  vq.py              # CLI 本体 (100行程度)
  config-summary.md  # nvim 設定の要約 (30〜50行)
  README.md          # 要約の作り直し手順
```

### 仕様

- モデルは `claude-haiku-4-5-20251001`
- `max_tokens=200`、ストリーミングを有効にする
- system prompt に `config-summary.md` を埋め込む。`init.lua` を生で渡さない
- 出力形式を固定する。コマンド1行、`---`、構成要素ごとに1行 (各40字以内)。前置きと締めは書かせない
- 独自マッピングを使った場合はその旨を明示させる。標準機能で足りる場合は独自マッピングを使わせない
- キャッシュは `$XDG_CACHE_HOME/vq/cache.json`。キーは正規化したクエリ (NFKC 変換、前後の空白除去、連続空白の圧縮)
- ログは `$XDG_CACHE_HOME/vq/log.jsonl` に質問と回答を追記する。何を繰り返し忘れているかを見るため
- API キーは `ANTHROPIC_API_KEY` を読み、無ければ `$XDG_CONFIG_HOME/vq/api-key` を読む。リポジトリには置かない

プロンプトキャッシュは使わない。設定要約が短く最小トークン数に届かないため効かない。

### config-summary.md の作り方

`README.md` に手順を書く。設定を変えたときだけ作り直す。

1. `nvim --headless` で `vim.api.nvim_get_keymap` を全モード分 dump する
2. dump と `nvim/lazy-lock.json` を Opus に渡し、leader キー、自分で足したマッピング、入っているプラグインとそれが追加するオペレータおよびテキストオブジェクトを30〜50行に圧縮させる
3. 結果を `config-summary.md` に置く

### パッケージング

`pkgs.writers.writePython3Bin` に `python3Packages.anthropic` を渡す。

### 呼び出し口

- zsh 関数 `vq` (`modules/home/programs/zsh.nix`)。ストリーミングがそのまま見える
- nvim の `:Vq` (`nvim/lua/polish.lua`)。`systemlist()` で叩いて結果をポップアップに出す

`:Vq` は `systemlist()` が完了を待つためストリーミングの恩恵を受けない。体感が悪ければ `jobstart` に変える。

## lint の実行経路

エージェントごとに hook の仕組みが違うので、判定本体はリポジトリのシェルスクリプト1つに置く。

`ai/hooks/lint-md.sh` が次を順に走らせる。

1. `markdownlint` — 設定は `ai/hooks/markdownlint.jsonc`。現在 macOS で使っているものをそのまま移す
2. `textlint` — 設定は `ai/textlintrc.json`

textlint は日本語文字を含むファイルにだけ掛ける。`AGENTS.md` のような英語ファイルに日本語ルールを当てても雑音しか出ない。判定は `rg -q '[ぁ-んァ-ヶ一-龠]'` で行う。

呼び出し口は3つ。Claude Code と Codex は hook のスキーマが同じなので、同じ定義を両方に入れる。

- Claude Code は `ai/claude/settings.json` の `PostToolUse` (matcher は `Write|Edit`) から呼ぶ
- Codex は `ai/codex/hooks.json` の `PostToolUse` から呼ぶ
- hook を持たないエージェントのために `ai/AGENTS.md` にも「.md を書いたら走らせる」と書く

終了コードの扱いは現行のスクリプトを踏襲する。指摘があれば exit 2 で stderr に出し、「文書の内容を変えずに直せ。linter を黙らせるために内容を消すな」を添える。

## AGENTS.md の中身

### 方針

skill の `description` は起動時にすべて文脈へ載る。AGENTS.md で skill を並べ直しても情報は増えない。AGENTS.md が足せるのは次の3つだけなので、それに絞る。

1. 既定の振る舞いを上書きする規則
2. 選択肢が複数あるときに、どれを使うかの振り分け
3. 自動発火が当てにならない skill の名指し

現在の `~/.claude/CLAUDE.md` は「インストール済みツールの一覧」と「既定を上書きする規則」が別の節に分かれていて、同じことを2回言っている。1つの振り分け表にまとめる。

言語は既存の記述に合わせて英語のままとする。既存の3節の本文はそのまま残す。

### 下書き

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
````

### 既存の記述からの変更点

| 変更 | 理由 |
| --- | --- |
| `stop-ai-slop-jp` の名指しを `japanese-writing` に差し替え | 統合先が変わる。`stop-ai-slop-jp` は `japanese-writing` の中から参照される |
| 「Installed tools」の一覧を削除 | 振り分け表に吸収した。ツール名だけを並べても、いつ使うかが書いていなければ効かない |
| 言語ごとの guidelines skill への振り分けを追加 | 新規 |
| lint の呼び出しを追加 | 新規。hook が無いエージェント向けの経路 |
| 人間用ツールの節を追加 | `hunk` と `vq` をエージェントが使わないようにする |

`~/.agents/hooks` も `ai/hooks` への symlink として張る。`~/.claude/hooks` と同じ実体を指す。AGENTS.md からハーネス非依存のパスで呼べるようにするため。

## 範囲外

- Serena と GitHub の MCP サーバ ([#12](https://github.com/santamn/dotnix/issues/12))
- ponytail の MCP サーバ (`ponytail-mcp/`) と statusline。skill、commands、hooks だけを取り込む
- Gemini、opencode、Pi など Claude Code と Codex 以外のハーネス向けの配線。上流にアダプタはあるが、使っていないので張らない
- `@deepseek-ai/dsh` のパッケージ化。nixpkgs になく flake も無い alpha 版なので、導入時に別 issue を立てる。探索パスの配線だけ今回入れる
- commit message への textlint 適用
- macOS 側の設定。`ai/` は共有できるが、`settings.json` の通知コマンドが macOS 固有なので今回は NixOS だけを対象とする

## 検証

NixOS マシンで次を確認する。

1. `nix flake check` が通る
2. `nixos-rebuild switch` 後、`~/.agents/skills/` と `~/.claude/skills/` に同じ skill が並ぶ
3. `claude` と `codex` の両方で `japanese-writing` が候補に出る
4. `ax`、`sem`、`ast-grep`、`hunk`、`zat`、`textlint`、`markdownlint`、`jq`、`vq` が PATH にある
5. `sem --version` が ataraxy-labs 版を返す (semaphoreci/cli ではない)
6. 日本語を含む `.md` を書くと、`claude` と `codex` の両方で `lint-md.sh` が発火する
7. `claude` で `/revise-claude-md` が出る
8. `claude` で `code-simplifier` サブエージェントが選べる
9. `codex` で `code-simplifier` と `source-command-revise-claude-md` が skill として出る
10. `codex` のセッション開始時に superpowers と ponytail の hook が発火する
11. `git diff` の表示が delta のままである
12. `~/.dsh/AGENTS.md` が `ai/AGENTS.md` を指している (DeepSeek 未導入でもリンクは張られる)
