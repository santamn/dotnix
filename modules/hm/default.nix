{
  pkgs,
  inputs,
  config,
  ...
}: {
  imports = [
    # Program-specific configurations
    ./programs/direnv.nix
    ./programs/fcitx5.nix
    ./programs/ghostty.nix
    ./programs/git.nix
    ./programs/kdeconnect.nix
    ./programs/neovim.nix
    ./programs/nushell.nix
    ./programs/ssh.nix
    ./programs/starship.nix
    ./programs/zsh.nix
    ./programs/zen-browser.nix
  ];

  # flake の置かれているパスを全体で使えるようにする
  _module.args.nixConfigPath = "${config.home.homeDirectory}/dotnix";

  # ===========================
  # Packages
  # ===========================
  home.packages = with pkgs; [
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
  ];

  # ===========================
  # XDG User Directories
  # ===========================
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    desktop = "${config.home.homeDirectory}/Desktop";
    documents = "${config.home.homeDirectory}/Documents";
    download = "${config.home.homeDirectory}/Downloads";
    music = "${config.home.homeDirectory}/Music";
    pictures = "${config.home.homeDirectory}/Pictures";
    publicShare = "${config.home.homeDirectory}/Public";
    templates = "${config.home.homeDirectory}/Templates";
    videos = "${config.home.homeDirectory}/Videos";
  };

  # ===========================
  # hydenix Module Options
  # ===========================
  hydenix.hm = {
    enable = true;

    hyprland = {
      extraConfig = ''
        input {
          # CapsLock と Ctrl キーを入れ替える
          kb_options = ctrl:swapcaps

          touchpad {
            # 指の上下とスクロール方向を逆にする
            natural_scroll = true
            # スクロール速度を半分にする
            scroll_factor = 0.5

            # タッチパッドの押し込みをクリックとして扱う
            # 1本:左クリック 2本:右クリック、3本:中クリック
            clickfinger_behavior = true
            # タップでクリックを有効化
            tap-to-click = true
            # 1本:左クリック 2本:中クリック 3本:右クリック に変更
            tap_button_map = lmr
          }
        }

        misc {
          # 中クリックペーストを無効化
          middle_click_paste = false
        }

        windowrulev2 = opacity 0.97 0.97, class:vesktop
        windowrulev2 = opacity 1.0 1.0, class:zen-beta
      '';

      hypridle = {
        enable = true;
        overrideConfig = ''
          general {
            lock_cmd = pidof hyprlock || hyprlock       # dbus/sysd lock command (loginctl lock-session)
            before_sleep_cmd = loginctl lock-session    # command to run before sleep
            after_sleep_cmd = hyprctl dispatch dpms on  # command to run after sleep
          }
          # 15分で画面をロック
          listener {
            timeout = 900                          # 15min
            on-timeout = loginctl lock-session     # lock screen when timeout has passed
          }
          # 20分で画面をオフ
          listener {
            timeout = 1200                         # 20min
            on-timeout = hyprctl dispatch dpms off # screen off when timeout has passed
            on-resume = hyprctl dispatch dpms on   # screen on when activity is detected after timeout has fired.
          }
          # 30分でサスペンド
          listener {
            timeout = 1800                         # 30min
            on-timeout = systemctl suspend         # suspend pc
          }
        '';
      };
    };

    theme = {
      enable = true;
      active = "Code Garden";
      themes = [
        "AncientAliens"
        "BlueSky"
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
