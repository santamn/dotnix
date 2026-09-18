# Neovim: バイナリと外部ツールだけを Nix で管理し、設定本体は普通の Lua で書く
#
# - 設定 (~/.config/nvim) はこのリポジトリの nvim/ へのシンボリックリンクとして管理される
# - Mason は使わない: FHS 前提のビルド済みバイナリは NixOS で動かないため
# - プロジェクト固有のツールチェーン (rust-analyzer, gopls など) は各プロジェクトの devShell + direnv で入れる
{
  config,
  pkgs,
  ...
}: let
  # nvim-treesitter の全言語パーサとクエリを1つのディレクトリに集約したもの
  treesitterRuntime = pkgs.symlinkJoin {
    name = "nvim-treesitter-runtime";
    paths = pkgs.vimPlugins.nvim-treesitter.withAllGrammars.dependencies;
  };
in {
  programs.neovim = {
    enable = true;
    defaultEditor = true; # EDITOR=nvim を設定
    viAlias = true;
    vimAlias = true;

    # Home Manager もラッパ用の初期化 Lua (プロバイダ無効化など) を生成するが、
    # それを ~/.config/nvim/init.lua に書き出すと下のシンボリックリンクと衝突してactivation が失敗するため
    # nvim 起動時の --cmd 経由で読ませることで両立させる
    sideloadInitLua = true;

    # Ruby / Python3 のリモートプラグインは使わないため無効化 (26.05 以降の既定値)
    withRuby = false;
    withPython3 = false;
  };

  home.packages = with pkgs; [
    # --- Neovim から使う汎用ツール ---
    lazygit # Git TUI
    wl-clipboard # クリップボード連携
    gdu # ディスク使用量表示

    # --- 常時使う LSP・フォーマッタ (旧 Mason 管理分) ---
    # 言語プロジェクト固有のもの (rust-analyzer 等) は devShell 側で入れる
    lua-language-server
    stylua

    # --- Nix 開発ツール ---
    nil # Nix Language Server
    statix # 静的解析ツール: コマンドラインから使う。エディタ連携はしていない
    alejandra # フォーマッタ
    nix-prefetch # SHA256 ハッシュ取得
  ];

  # ~/.config/nvim をリポジトリの nvim/ への直リンクに:　どちらを編集しても即座に反映される
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/nvim";

  # Tree-sitter のパーサとクエリを Neovim の runtimepath (~/.local/share/nvim/site) に配置
  xdg.dataFile."nvim/site/parser".source = "${treesitterRuntime}/parser";
  xdg.dataFile."nvim/site/queries".source = "${treesitterRuntime}/queries";
}
