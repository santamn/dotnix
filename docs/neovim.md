# Neovim の運用

## 基本方針: Lua で設定してバイナリを Nix で管理

- 設定本体は [nvim/](../nvim/) にある普通の Lua (AstroNvim v6 + lazy.nvim)
  - `~/.config/nvim` はこのディレクトリへのシンボリックリンクなので Lua の編集は nixos-rebuild なしで即座に反映される
- Nix が担当するもの ([modules/home/programs/neovim.nix](../modules/home/programs/neovim.nix)):
  - Neovim 本体
  - LSP サーバー・フォーマッタなどの外部バイナリ
  - Tree-sitter パーサ
- プラグインは lazy.nvim が今まで通り GitHub から取得する
  - バージョン固定のため `nvim/lazy-lock.json` はコミットしてよい

## NixOS 特有の注意点

### Mason は使わない

Mason が配布するビルド済みバイナリは動的にリンクされるため NixOS では動かないことが多い。このリポジトリでは Mason 関連プラグインを無効化してある ([nvim/lua/plugins/disabled.lua](../nvim/lua/plugins/disabled.lua))。

ツールの追加方法は次のとおり:

| 種類 | 追加先 |
|-----|-------|
| どのプロジェクトでも使うツール (lua_ls, stylua, nil など) | [modules/home/programs/neovim.nix](../modules/home/programs/neovim.nix) の `home.packages` |
| 言語ツールチェーン (rust-analyzer, gopls など) | 各プロジェクトの devShell (下記) |

LSP サーバーを増す場合は [nvim/lua/plugins/astrolsp.lua](../nvim/lua/plugins/astrolsp.lua) の `servers` にも追記する必要がある。なぜなら、通常 AstroNvim ではどの LSP を起動するかを mason-lspconfig が列挙して AstroLSP に渡すことになっているが、ここでは Mason を無効化しているので PATH にバイナリを置いただけでは自動検出されないからである。

LSP の追加には2箇所必要:

| 役割 | 場所 |
|-----|-----|
| バイナリの供給 | Nix (`home.packages` または devShell) |
| 起動する宣言 | astrolsp の `servers` |

PATH にバイナリが無いサーバーは起動されずに黙って飛ばされる。そのため devShell でしか入らないものを `servers` に並べておいても、そのプロジェクトの外でエラーが出ることはない。

フォーマッタは conform.nvim に一本化してある ([nvim/lua/plugins/conform.lua](../nvim/lua/plugins/conform.lua))。`formatters_by_ft` に載っていないファイルタイプは LSP の整形に落ちるので、LSP が整形できる言語 (Haskell の HLS、Clojure の clojure-lsp など) は何も書かなくてよい。

### Tree-sitter パーサーも Nix で入れる

tree-sitter のパーサー一式 (`pkgs.vimPlugins.nvim-treesitter.withAllGrammars`) を `~/.local/share/nvim/site/parser` に、クエリを `~/.local/share/nvim/site/queries` に[配置しており](../modules/home/programs/neovim.nix)、実行時にはダウンロードやコンパイルは発生しない。nvim-treesitter (main ブランチ) の `install_dir` 既定値がちょうどこの場所なので、Lua 側で置き場所を設定する必要はない。

パーサーだけでは足りない点に注意。main ブランチはクエリをプラグイン内の `runtime/queries` に持っていて、この場所は runtimepath に載らない。本来は `:TSInstall` が `site/queries` へリンクを張るところを Nix が肩代わりしている。クエリが無いと `vim.treesitter.query.get` が nil を返し、AstroCore がハイライトも indent も fold も有効にしない。正規表現の syntax は効いたままなので見た目では気づきにくい。確認は `:checkhealth nvim-treesitter` の Installed languages 表で、H (highlights) 列が `✓` になっているかを見る。

**`:TSInstall` は使えない。** 実行時コンパイルを完全に捨てており、`tree-sitter` CLI もコンパイラも `home.packages` に入れていない。パーサを追加・更新するときは nixpkgs を更新する。この決定の経緯は [astronvim-v6-migration.md](astronvim-v6-migration.md) を参照。

## プロジェクトごとの devShell (direnv)

言語ツールチェーンはグローバルには入れず、プロジェクトごとの devShell によって提供する。 `.envrc` を用意することでディレクトリを変更するだけで環境が切り替わり、Neovim の LSP もそのプロジェクトのツールチェーンを使うようになっている。

雛形は [templates/](../templates/) にある:

| 言語 | 展開コマンド | 入るもの |
|---|---|---|
| Rust | `nix flake init -t ~/dotnix#rust` | rust-analyzer / clippy / rustfmt / codelldb |
| Go | `nix flake init -t ~/dotnix#go` | gopls / goimports / golangci-lint / delve |
| Python | `nix flake init -t ~/dotnix#python` | uv / basedpyright / ruff |
| Haskell | `nix flake init -t ~/dotnix#haskell` | GHC / cabal / HLS / hlint / ormolu |
| Clojure | `nix flake init -t ~/dotnix#clojure` | JDK / clojure / clojure-lsp / clj-kondo / babashka |

新しいプロジェクトの始め方 (Rust の例):

```bash
mkdir myproject && cd myproject
nix flake init -t ~/dotnix#rust   # flake.nix / .envrc / .gitignore の雛形を展開
direnv allow
cargo init
```

言語を増やすときは3箇所に手を入れる:

| 役割 | 場所 |
|---|---|
| devShell の雛形 | `templates/<言語>/` (flake.nix と .envrc と .gitignore) |
| 雛形の登録 | ルートの [flake.nix](../flake.nix) の `templates` |
| LSP の起動宣言 | astrolsp の `servers` |

## Rust の開発体験

[rustaceanvim](https://github.com/mrcjkb/rustaceanvim) が rust-analyzer を管理する([nvim/lua/plugins/rustaceanvim.lua](../nvim/lua/plugins/rustaceanvim.lua))。

- 保存時に clippy が走り、インレイヒント・CodeLens・ホバーアクションが有効
- `<Leader>r*` に Rust 専用コマンド (runnables / debuggables / expandMacro など)
- デバッグは devShell が提供する codelldb を使う (`CODELLDB_PATH` / `LIBLLDB_PATH`
  は templates/rust の devShell が設定する)
- crates.nvim により Cargo.toml 上で依存クレートの更新・バージョン補完ができる

**重要**: rustaceanvim と lspconfig の両方から rust-analyzer が二重に起動してしまうことで補完や診断が壊れてしまうのを避けるため、`rust_analyzer` を astrolsp の `servers` に追加してはいけない。

## Herdr で AI エージェントと連携

[Herdr](https://herdr.dev/) は AI エージェント用のターミナルマルチプレクサ。エージェントの状態 (作業中 / 入力待ち / 完了) がサイドバーに表示される。

```bash
cd myproject
herdr                 # ワークスペースを作成して起動
# ペインを左右に分割し、左で nvim、右で claude を起動する
```

Neovim 側の連携キーマップ ([nvim/lua/plugins/herdr.lua](../nvim/lua/plugins/herdr.lua)):

| キー | 動作 |
|---|---|
| `<Leader>zf` | 現在のファイルパスを右隣のエージェントペインに送る |
| `<Leader>zl` (ビジュアルモード) | 選択範囲を右隣のエージェントペインに送る |

セッションはデタッチしても残るため、SSH 先でエージェントを回し続ける用途にも使える。
