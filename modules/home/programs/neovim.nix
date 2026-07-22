# Neovim: バイナリと外部ツールだけを Nix で管理し、設定本体は普通の Lua で書く
#
# - 設定 (~/.config/nvim) はこのリポジトリの nvim/ へのシンボリックリンク。
#   Lua ファイルの編集は nixos-rebuild なしで即座に反映される
# - Mason は使わない (FHS 前提のビルド済みバイナリは NixOS で動かないため)。
#   LSP サーバー・フォーマッタは下の home.packages で入れて PATH 経由で使わせる
# - プロジェクト固有のツールチェーン (rust-analyzer, gopls など) は
#   各プロジェクトの devShell + direnv で提供する (templates/ 参照)
# - Tree-sitter パーサも Nix で入れる (実行時のコンパイル失敗を避けるため)
{
  config,
  pkgs,
  nixConfigPath,
  ...
}: let
  # nvim-treesitter の全言語パーサを1つのディレクトリに集約したもの
  treesitterParsers = pkgs.symlinkJoin {
    name = "nvim-treesitter-parsers";
    paths = pkgs.vimPlugins.nvim-treesitter.withAllGrammars.dependencies;
  };
in {
  programs.neovim = {
    enable = true;
    defaultEditor = true; # EDITOR=nvim を設定
    viAlias = true;
    vimAlias = true;
  };

  home.packages = with pkgs; [
    # --- Neovim から使う汎用ツール ---
    lazygit # Git TUI
    wl-clipboard # クリップボード連携
    nodejs # 一部プラグインと LSP の実行環境
    gdu # ディスク使用量表示
    tree-sitter # パーサを手動追加したい場合の :TSInstall 用 CLI

    # --- 常時使う LSP・フォーマッタ (旧 Mason 管理分) ---
    # 言語プロジェクト固有のもの (rust-analyzer 等) は devShell 側で入れる
    lua-language-server
    stylua

    # --- Nix 開発ツール ---
    nil # Nix Language Server
    statix # Nix 静的解析
    nixpkgs-fmt # Nix フォーマッタ
    nix-prefetch # SHA256 ハッシュ取得

    # --- ネイティブ拡張のビルドや :TSInstall のフォールバック用 ---
    gnumake
    gcc
    unzip
    wget
    gnutar
    curl
    gzip
  ];

  # ~/.config/nvim をリポジトリの nvim/ への直リンクに:
  # どちらを編集しても即座に反映される (rebuild 不要)
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${nixConfigPath}/nvim";

  # Tree-sitter パーサを Neovim の runtimepath (~/.local/share/nvim/site) に配置する。
  # nvim-treesitter プラグイン本体は lazy.nvim が管理するが、パーサの実体は
  # ここで Nix が供給するため実行時のダウンロード・コンパイルは発生しない
  xdg.dataFile."nvim/site/parser".source = "${treesitterParsers}/parser";
}
