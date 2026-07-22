# Neovim の運用方針

## 基本方針: Lua は普通に書き、バイナリだけ Nix で管理する

- 設定本体は [nvim/](../nvim/) にある普通の Lua (AstroNvim v5 + lazy.nvim)。
  `~/.config/nvim` はこのディレクトリへのシンボリックリンクなので、
  **Lua の編集は nixos-rebuild なしで即座に反映される**
- Nix が担当するのは以下だけ ([modules/home/programs/neovim.nix](../modules/home/programs/neovim.nix)):
  - Neovim 本体
  - LSP サーバー・フォーマッタなどの外部バイナリ
  - Tree-sitter パーサ
- プラグインは lazy.nvim が今まで通り GitHub から取得する。
  バージョン固定のため `nvim/lazy-lock.json` はコミットしてよい

## NixOS 特有の注意点

### Mason は使わない

Mason が配布するビルド済みバイナリは FHS 前提 (動的リンク) のため NixOS では動かないことが多い。
このリポジトリでは Mason 関連プラグインを無効化してある ([nvim/lua/plugins/mason.lua](../nvim/lua/plugins/mason.lua))。

ツールの追加方法:

| 種類 | 追加先 |
|---|---|
| どのプロジェクトでも使うツール (lua_ls, stylua, nil など) | [modules/home/programs/neovim.nix](../modules/home/programs/neovim.nix) の `home.packages` |
| 言語ツールチェーン (rust-analyzer, gopls など) | 各プロジェクトの devShell (下記) |

LSP サーバーを増やしたら [nvim/lua/plugins/astrolsp.lua](../nvim/lua/plugins/astrolsp.lua) の `servers` にも追記する
(lspconfig は PATH 上のバイナリを使って起動する)。

### Tree-sitter パーサも Nix で入れる

`pkgs.vimPlugins.nvim-treesitter.withAllGrammars` の全パーサを
`~/.local/share/nvim/site/parser` に配置してある。実行時のダウンロードや
C コンパイルは発生しない。もし特定言語でハイライトが崩れる場合は
`:TSInstall <lang>` で lazy.nvim 側のバージョンに合わせたパーサを入れ直せる
(gcc と tree-sitter CLI は導入済み)。

## プロジェクトごとの devShell (direnv)

言語ツールチェーンはグローバルに入れず、プロジェクトごとの devShell で提供する。
`.envrc` により cd するだけで環境が切り替わり、Neovim の LSP もそのプロジェクトの
ツールチェーンを使う (direnv.vim が起動時に環境を引き継ぐ)。

新しい Rust プロジェクトの始め方:

```bash
mkdir myproject && cd myproject
nix flake init -t ~/dotnix#rust   # flake.nix / .envrc の雛形を展開
direnv allow
cargo init
```

## Rust の開発体験 (VSCode 相当)

[rustaceanvim](https://github.com/mrcjkb/rustaceanvim) が rust-analyzer を管理する
([nvim/lua/plugins/rustaceanvim.lua](../nvim/lua/plugins/rustaceanvim.lua))。

- 保存時に clippy が走り、インレイヒント・CodeLens・ホバーアクションが有効
- `<Leader>r*` に Rust 専用コマンド (runnables / debuggables / expandMacro など)
- デバッグは devShell が提供する codelldb を使う (`CODELLDB_PATH` / `LIBLLDB_PATH`
  は templates/rust の devShell が設定する)
- crates.nvim により Cargo.toml 上で依存クレートの更新・バージョン補完ができる

> **重要**: `rust_analyzer` を astrolsp の `servers` に追加してはいけない。
> rustaceanvim と lspconfig の両方から rust-analyzer が二重起動し、補完や診断が壊れる
> (以前の「Rust がうまく動かない」原因はこれ)。

## Herdr で「左にコード、右に AI」

[Herdr](https://herdr.dev/) は AI エージェント用のターミナルマルチプレクサ (tmux 互換キーバインド)。
エージェントの状態 (作業中 / 入力待ち / 完了) がサイドバーに表示される。

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
