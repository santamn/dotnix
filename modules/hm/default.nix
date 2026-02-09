{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    # ./example.nix - add your modules here
  ];

  # ===========================
  # Packages
  # ===========================
  home.packages = with pkgs; [
    # --- Terminal / Shell ---
    ghostty
    nushell

    # --- Development Tools ---
    lazygit

    # --- Nix Tools ---
    nix-prefetch # Nix パッケージの SHA256 ハッシュ取得
    nixpkgs-fmt # Nix コードフォーマッター
    nil # Nix Language Server
    statix # Nix 静的解析ツール

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
    wine64
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
      vscode.enable = false;
      vim.enable = false;
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

    # --- Shell ---
    shell = {
      enable = true;
      zsh = {
        enable = false;
      };
      bash.enable = false;
      fish.enable = false;
      starship.enable = true;
    };

    # --- Social ---
    social = {
      enable = true;
      discord.enable = false;
      vesktop.enable = true;
    };

    # --- Spotify ---
    spotify.enable = true;

    # --- Terminals ---
    terminals = {
      enable = true;
      kitty.enable = false; # Using Ghostty instead
    };
  };

  # ===========================
  # Program-specific configuration
  # ===========================
  programs.nushell.enable = true;

  # direnv で devShell を自動的に読み込む
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
  };

  # Ghostty terminal configuration
  # Note: Ghostty config is managed via ~/.config/ghostty/config
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      theme = "TokyoNight Moon";
      background-opacity = "0.70";

      font-size = 10;
      font-family = "Hack Nerd Font";
    };
  };

  # Git extras (delta integration)
  programs.git.delta.enable = true;

  programs.neovim = {
    enable = true;
    extraConfig = builtins.readFile ./nvim/init.lua;
  };

  # ===========================
  # Zen Browser Configuration
  # ===========================
  programs.firefox = {
    enable = true;
    package = inputs.zen-browser.packages."${pkgs.system}".default;

    profiles.default = {
      id = 0;
      name = "default";
      isDefault = true;

      # Search engine
      search = {
        default = "DuckDuckGo";
        force = true;
      };

      # Extensions (Firefox Add-ons)
      # Using direct XPI URLs from Mozilla Add-ons
      extensions = [
        # uBlock Origin
        (pkgs.fetchurl {
          url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          sha256 = "1kvj2kwwiih7yqiirqha7xfvip4vzrgyqr4rjjhaiyi5ibkcsnvq";
          name = "ublock-origin@mozilla.org.xpi";
        })
        # Dark Reader
        (pkgs.fetchurl {
          url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
          sha256 = "1gj455hd0nw2idssbs7cmpxkg1kbjafq18n718rfx0yg5wpl46i6";
          name = "addon@darkreader.org.xpi";
        })
        # Hide YouTube-Shorts
        (pkgs.fetchurl {
          url = "https://addons.mozilla.org/firefox/downloads/latest/hide-youtube-shorts/latest.xpi";
          sha256 = "051pgzsmd2yic8n9d435h6d0j0scw50rkp5hbi2bs7lb903s0c3g";
          name = "hideyoutubeshorts@mozilla.org.xpi";
        })
        # Enhancer for YouTube
        (pkgs.fetchurl {
          url = "https://addons.mozilla.org/firefox/downloads/latest/enhancer-for-youtube/latest.xpi";
          sha256 = "1zps29ss8nmp3a8k4042rwzx9y3jpivhnjy4qpd44gi7826nmv0y";
          name = "{dc8f61e1-cdc3-4ed7-9028-222b53cf895f}.xpi";
        })
        # Control Panel for Twitter
        (pkgs.fetchurl {
          url = "https://addons.mozilla.org/firefox/downloads/latest/control-panel-for-twitter/latest.xpi";
          sha256 = "07cgjbavi3axpj9slp27nfiyc5967z3mih3isjdsjjarza4i93vl";
          name = "{a35cf3ba-4850-4228-938f-6aa981c37dcc}.xpi";
        })
        # uBlacklist
        (pkgs.fetchurl {
          url = "https://addons.mozilla.org/firefox/downloads/latest/ublacklist/latest.xpi";
          sha256 = "1ghifsr2g4068karymrvipfbsgwsxz65q0hb8wfm6bh4g7wfgqpn";
          name = "uBlacklist@mozilla.org.xpi";
        })
        # Plamo Translate
        (pkgs.fetchurl {
          url = "https://addons.mozilla.org/firefox/downloads/latest/plamo-translate/latest.xpi";
          sha256 = "0zg9p878givx0mzakdmb4va0vyzxj2x87mbz7cmkx82kgxflv254";
          name = "{fddda36b-1927-4a54-ab54-6e2f5c3e5a1e}.xpi";
        })
        # FoxScroller
        (pkgs.fetchurl {
          url = "https://addons.mozilla.org/firefox/downloads/latest/foxscroller/latest.xpi";
          sha256 = "1r02m9kqhl7azfnwrikxlfxgima864yfpzxg8ywplv8wadhdzqvn";
          name = "foxscroller@mozilla.org.xpi";
        })
        # LeechBlock NG
        (pkgs.fetchurl {
          url = "https://addons.mozilla.org/firefox/downloads/latest/leechblock-ng/latest.xpi";
          sha256 = "1rf1p27xr49wlzxcyp8j3g33fcjk5c07z5b68wlgwllszp66cd8k";
          name = "leechblockng@protonmail.com.xpi";
        })
        # User-Agent Switcher
        (pkgs.fetchurl {
          url = "https://addons.mozilla.org/firefox/downloads/latest/uaswitcher/latest.xpi";
          sha256 = "0pvw48524dr6z4d74w51q13m1dn3aaj7v5h24zfyhmx5qqrwp8pd";
          name = "{dc572301-7619-461c-a073-cc513a434ddf}.xpi";
        })
      ];

      settings = {
        # Privacy settings
        "privacy.donottrackheader.enabled" = true;
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;

        # Disable telemetry
        "browser.newtabpage.activity-stream.feeds.telemetry" = false;
        "browser.newtabpage.activity-stream.telemetry" = false;
        "browser.ping-centre.telemetry" = false;
        "toolkit.telemetry.archive.enabled" = false;
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.unified" = false;

        # Performance
        "gfx.webrender.all" = true;
        "media.ffmpeg.vaapi.enabled" = true;
      };
    };
  };
}
