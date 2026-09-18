# AstroNvim v6 への移行

2026-09-18 に AstroNvim を v5 から v6 に上げた。移行の内容と、NixOS 機でまだ確認していないことをここにまとめる。確認が済んだら「NixOS 機での確認手順」の節は消してよい。

## なぜ壊れる可能性があったのか

v6 の目玉は Neovim 0.11 で入った `vim.lsp.config` への全面移行と、nvim-treesitter の main ブランチ書き換えへの追従の2つ。このリポジトリで実際に問題になったのは後者だけだった。

nvim-treesitter の main ブランチでは、`get_installed()` が `install_dir/parser` だけを走査して runtimepath を見ない。そして AstroCore はハイライトと textobjects を有効にするかどうかをこの関数で判定する。移行前の `nvim/lua/plugins/treesitter.lua` は `install_dir` を `~/.local/share/nvim/treesitter` に向けていたので、Nix が `~/.local/share/nvim/site/parser` に置いたパーサは AstroCore からは存在しないことになる。そのまま上げると全ファイルタイプでハイライトが消えるか、`auto_install` が全パーサを再コンパイルし始める。

main ブランチの `install_dir` 既定値は `stdpath("data")/site` で、Nix の配置先とちょうど一致する。そのため override を削除するだけで解決した。

## 方針の変更: 実行時コンパイルを完全に捨てた

移行のついでに、Tree-sitter パーサの供給を Nix に一本化した。開発環境は devShell で揃えるという方針に合わせ、`~/.local/share` に可変な状態を溜めないようにする。

- `astrocore` に `treesitter.auto_install = false` を入れた
- `~/.local/share/nvim/site/queries` にもクエリを配置した。main ブランチはクエリをプラグイン内の `runtime/queries` に持っており、そこは runtimepath に載らない。`:TSInstall` を封じた以上、Nix が置かないとハイライトが全滅する (詳細は [neovim.md](neovim.md))
- `home.packages` から `tree-sitter` CLI とビルドツール (`gcc`, `gnumake`, `unzip`, `wget`, `gnutar`, `curl`, `gzip`) を削除した。`astrocore.treesitter.install()` は `tree-sitter` が PATH にないと即 return するので、これ自体が歯止めになっている
- `nodejs` も削除した。`programs.neovim.withNodeJs` は既定 false で、Mason も無効、常用の LSP もすべてネイティブバイナリのため。Node が要るプロジェクトでは devShell に入れる

**`:TSInstall` は使えなくなった。** パーサを追加・更新するには nixpkgs を更新する。`withAllGrammars` が約300言語を持っているので、足りない状況はまず起きないはず。

## 挙動が変わったところ

移行前から意図どおりに動いていなかった箇所を、このタイミングで直した。

**保存時フォーマットが二重に走っていた。** `astrocore` の `features.formatting = false` は AstroCore に存在しないキーで、何もしていなかった。コメントには「AstroLSP の formatting は無効化」と書いてあったが実際には `format_on_save.enabled = true` が生きており、conform と合わせて保存のたびに2回フォーマットが走っていた。AstroLSP 側を `format_on_save = false` にして conform に一本化した。

**dashboard の Open Directory が動いていなかった。** キーが `o` で、AstroNvim 既定の Recents と衝突していた。後に登録される Recents 側が勝つため、メニューには出るが押しても何も起きない状態だった。`d` に変更した。

**Nix のフォーマッタが合っていなかった。** `home.packages` に入っていたのは `nixpkgs-fmt` だが、このリポジトリの `.nix` は37ファイルすべて alejandra のスタイルで書かれている。`alejandra` に差し替え、conform に繋いだ。`stylua` も同様に、入っているのにどこからも呼ばれていなかったので繋いだ。

**`statix` はエディタから呼ばれていない。** none-ls を無効にしている以上、リンタを繋ぐには nvim-lint を足す必要がある。今はコマンドラインツールとして使う前提のまま残してある。

## 確認済みのこと

ローカルの Neovim 0.12.5 で、XDG ディレクトリを分離した隔離環境を作って確認した。以下は再確認しなくてよい。

- `:Lazy! sync` が最後まで通り、設定由来のエラーが出ない
- AstroNvim が `^6` で解決してロードされる。nvim-treesitter と nvim-treesitter-textobjects は main ブランチに乗る
- `install_dir` が `stdpath("data")/site/parser` を指し、そこに置いたパーサを `get_installed()` と `astrocore.treesitter.has_parser()` が検出する
- `tree-sitter` CLI が PATH にない状態では実行時コンパイルの経路に入らない
- 設定値が意図どおり解決される (`signature_help = true` / `format_on_save = { enabled = false }` / `auto_install = false` / `large_buf.size = 262144` / conform が lua・nix・rust を拾う)
- dashboard のキーに重複がない
- PATH にバイナリが無い LSP は静かにスキップされる (エラー通知もクライアント生成もない)

## NixOS 機での確認手順

上の隔離環境では Nix のパーサ、rust-analyzer、direnv を再現できなかった。実機で以下を確認する。

```bash
cd ~/dotnix
nh os switch .
```

1. `nvim --version` が 0.11 以上であること (0.12 系を想定している)
2. `nvim` を起動し、`:Lazy sync` でエラーが出ないこと
3. `:checkhealth astronvim` と `:checkhealth vim.lsp` を見る。`:LspInfo` は v6 で廃止されているので使わない
4. **Tree-sitter が今回の要**。`:checkhealth nvim-treesitter` の Installed languages 表で、lua・nix・rust・go の H (highlights) 列が `✓` になっているかを見る。色が付いているかの目視では判定できない。パーサもクエリも無いまま正規表現の syntax だけが効いている状態と区別がつかないため。`.` が並ぶならクエリが、行そのものが無いならパーサが届いていない。Requirements の `tree-sitter-cli not found` は捨てた機能なので無視してよい
5. Rust プロジェクトの devShell に入って `nvim src/main.rs`。rust-analyzer が起動し、インレイヒントと CodeLens が出るか。`<Leader>rr` (runnables) と `K` (ホバーアクション) を叩く
6. `Cargo.toml` を開いて crates.nvim のバージョン表示が出るか
7. **保存時フォーマットが1回だけ走ること**。Rust、Lua、Nix のファイルで試す。特に `.nix` は alejandra に差し替えたので、保存して差分が出ないことを確認する
8. `<Leader>d` のデバッガメニューが which-key に出るか。ブレークポイントを置いて `<Leader>dc` で起動し、DAP UI と変数のインライン表示が出るか
9. 挿入モードで関数の `(` を打ってシグネチャヘルプが出るか (`lsp_signature.nvim` を AstroLSP の `features.signature_help` に置き換えたため)
10. `<Leader>lr` で IncRename のライブプレビューが動くか
11. dashboard で `d` を押して Open Directory が動くか
12. Herdr のペイン内で `<Leader>zf` と、ビジュアル選択してから `<Leader>zl`
13. `gcc` と `tree-sitter` を消したことで起動時に警告が出ていないか

## うまくいかないとき

Lua の設定は `~/.config/nvim` がこのリポジトリへのシンボリックリンクなので、`git revert` すれば rebuild なしで戻る。

```bash
cd ~/dotnix
git log --oneline               # 移行は5コミットに分かれている
git revert <コミット>
```

プラグインの状態がおかしいときは、lazy のデータを消して入れ直す。設定は消えない。

```bash
rm -rf ~/.local/share/nvim/lazy ~/.local/state/nvim
nvim --headless "+Lazy! sync" +qa
```

パーサだけを疑うときは、Nix が置いたものが見えているかを直接確認する。

```bash
ls ~/.local/share/nvim/site/parser | head
nvim --headless -c 'lua print(vim.inspect(require("nvim-treesitter").get_installed("parsers")))' -c qa
```

## 関連

- 運用方針の全体は [neovim.md](neovim.md)
- 上流の移行ガイド: <https://docs.astronvim.com/configuration/v6_migration/>
