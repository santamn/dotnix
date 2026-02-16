{
  config,
  pkgs,
  nixConfigPath,
  ...
}: {
  home.packages = with pkgs; [
    lazygit # Git リポジトリの管理をターミナルで行うためのツール
    wl-clipboard # Hyprland 環境でのクリップボード共有のためのツール

    # --- Language Runtimes (for AstroNvim) ---
    nodejs # LSPs and REPL toggle terminal
    gdu # go DiskUsage() - Disk usage analyzer
    tree-sitter # Tree-sitter CLI for auto_install

    # --- Nix Tools ---
    nix-prefetch # Nix パッケージの SHA256 ハッシュ取得
    nixpkgs-fmt # Nix コードフォーマッター
    nil # Nix Language Server
    statix # Nix 静的解析ツール

    # --- Mason Dependencies ---
    gnumake
    gcc
    unzip
    wget
    gnutar
    curl
    gzip
  ];

  # ~/.config/nvim を ~/dotnix/nvim への直リンクに: どちらのファイルを編集しても即座に反映さる
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "${nixConfigPath}/nvim";
}
