# Neovim の運用

## 基本方針: Lua で設定してバイナリを Nix で管理

- 設定本体は [nvim/](../nvim/) にある普通の Lua (AstroNvim v5 + lazy.nvim)
  - `~/.config/nvim` はこのディレクトリへのシンボリックリンクなので、
  Lua の編集は nixos-rebuild なしで即座に反映される
- Nix が担当するもの ([modules/home/programs/neovim.nix](../modules/home/programs/neovim.nix)):
  - Neovim 本体
  - LSP サーバー・フォーマッタなどの外部バイナリ
  - Tree-sitter パーサ
- プラグインは lazy.nvim が今まで通り GitHub から取得する
  - バージョン固定のため `nvim/lazy-lock.json` はコミットしてよい

## NixOS 特有の注意点

### Mason は使わない

Mason が配布するビルド済みバイナリは動的にリンクされるため NixOS では動かないことが多い。このリポジトリでは Mason 関連プラグインを無効化してある ([nvim/lua/plugins/mason.lua](../nvim/lua/plugins/mason.lua))。

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

### Tree-sitter パーサーも Nix で入れる

tree-sitter の全てのパーサー (`pkgs.vimPlugins.nvim-treesitter.withAllGrammars`) を `~/.local/share/nvim/site/parser` に[配置しており](modules/home/programs/neovim.nix#L16-L20)、実行時にはダウンロードやコンパイルは発生しない。
もし特定言語でハイライトが崩れる場合は `:TSInstall <lang>` を実行することで lazy.nvim 側のバージョンに合わせたパーサを入れ直すことができる。

## プロジェクトごとの devShell (direnv)

言語ツールチェーンはグローバルには入れず、プロジェクトごとの devShell によって提供する。 `.envrc` を用意することでディレクトリを変更するだけで環境が切り替わり、Neovim の LSP もそのプロジェクトのツールチェーンを使うようになっている。

新しい Rust プロジェクトの始め方:

```bash
mkdir myproject && cd myproject
nix flake init -t ~/dotnix#rust   # flake.nix / .envrc の雛形を展開
direnv allow
cargo init
```

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
