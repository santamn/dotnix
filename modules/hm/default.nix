{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    # Program-specific configurations
    ./programs/direnv.nix
    ./programs/ghostty.nix
    ./programs/git.nix
    ./programs/neovim.nix
    ./programs/nushell.nix
    ./programs/ssh.nix
    ./programs/starship.nix
    ./programs/zsh.nix
    ./programs/zen-browser.nix
  ];

  # ===========================
  # Packages
  # ===========================
  home.packages = with pkgs; [
    # --- Development Tools ---
    lazygit
    helix # nushell の vi/vim/nano エイリアスで使用

    # --- Language Runtimes (for AstroNvim) ---
    nodejs # LSPs and REPL toggle terminal
    python3 # Python REPL
    go # go DiskUsage() toggle terminal
    tree-sitter # Tree-sitter CLI for auto_install

    # --- Nix Tools ---
    # These are kept global as they're used across all projects
    nix-prefetch # Nix パッケージの SHA256 ハッシュ取得
    nixpkgs-fmt # Nix コードフォーマッター
    nil # Nix Language Server
    statix # Nix 静的解析ツール

    # --- CLI tools ---
    wine64

    # --- Alternative Commands ---
    bat # cat
    bottom # top alternative
    eza # ls
    fd # find
    fzf # interactive file search
    ripgrep # grep

    # --- Daily Software ---
    slack
    zoom-us
    thunderbird
    signal-desktop

    # --- Japanese Input ---
    # fcitx5 is configured at system level (modules/system/default.nix)
    # Config tool can be launched via fcitx5-configtool
    fcitx5-configtool
  ];

  # ===========================
  # HyDenix Module Options
  # ===========================
  hydenix.hm = {
    enable = true;

    theme = {
      enable = true;
      active = "Tokyo Night";
      themes = [
        "AncientAliens"
        "BlueSky"
        "Breezy Autumn"
        "Catppuccin Mocha"
        "Catppuccin Latte"
        "Catppuccin-Macchiato"
        "Code Garden"
        "Decay Green"
        "Monokai"
        "Rain Dark"
        "Solarized Dark"
        "Tokyo Night"
      ];
    };

    # --- Editors ---
    editors = {
      enable = true;
      neovim = true;
      vim = false;
      vscode = {
        enable = false;
        wallbash = false;
      };
      default = "nvim";
    };

    # --- Firefox (disabled, using Zen Browser instead) ---
    firefox.enable = false;

    # --- Git ---
    git = {
      enable = true;
      name = "santamn";
      email = "cle.neige@gmail.com";
    };

    # --- Social ---
    social = {
      enable = true;
      discord.enable = false;
      vesktop.enable = true;
    };

    # --- Terminals ---
    terminals = {
      enable = true;
      kitty.enable = false;
    };
  };
}
