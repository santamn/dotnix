# ユーザ santamn の Home Manager 設定のエントリポイント
{...}: {
  imports = [
    ../modules/home
  ];

  # Home Manager 自身を Home Manager で管理する
  programs.home-manager.enable = true;

  # 初回セットアップ時のバージョン。変更してはいけない
  home.stateVersion = "25.05";

  # ===========================
  # hydenix Module Options
  # ===========================
  # HyDE (Hyprland デスクトップ) 一式を有効化する。個別の無効化は各サブオプションで行う
  hydenix.hm = {
    enable = true;

    theme = {
      enable = true;
      active = "Decay Green";
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
      '';

      hypridle = {
        enable = true;
        overrideConfig = ''
          general {
            lock_cmd = pidof hyprlock || hyde-shell lockscreen.sh # dbus/sysd lock command (loginctl lock-session)
            before_sleep_cmd = loginctl lock-session              # command to run before sleep
            after_sleep_cmd = hyprctl dispatch dpms on            # command to run after sleep
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

    # --- Editors ---
    editors = {
      enable = true;
      # hydenix 側は素の pkgs.neovim を home.packages に足すだけなので無効化する: programs.neovim と重複してエラーになる
      neovim = false;
      vim = false;
      vscode = {
        enable = false;
        wallbash = false;
      };
      default = "nvim";
    };

    # --- Firefox (無効化、Zen Browser を使うため) ---
    firefox.enable = false;

    # --- Social ---
    social = {
      enable = true;
      discord.enable = false;
      vesktop.enable = true;
    };

    # --- Terminals (kitty は無効化、Ghostty を使うため) ---
    terminals = {
      enable = true;
      kitty.enable = false;
    };

    # --- Shell ---
    # zsh/nushell/starship は modules/home/programs/ 側で個別に管理しているため、
    # hydenix 側の shell モジュール (oh-my-zsh 等) を丸ごと無効化して衝突を避ける
    shell.enable = false;
  };

  # ===========================
  # 旧 hydenix 使用時のカスタマイズ (mutable ファイルの上書き)
  # ===========================
  # 注意: hydenix 側が同じパスを mutable = true で配置しているため、
  # 上書きする側にも mutable = true を付けないと activation の cp で戻される
  # (docs-ja/04-mutable-files.md 参照)。
  home.file = {
    # 日付の表示フォーマットを YYYY-MM-DD に変更
    ".config/waybar/modules/clock.jsonc" = {
      text = builtins.toJSON {
        clock = {
          format = "{:%R 󰃭 %Y-%m-%d}";
          rotate = 0;
          format-alt = "{:%I:%M %p}";
          tooltip-format = "<span>{calendar}</span>";
          calendar = {
            mode = "month";
            mode-mon-col = 3;
            on-scroll = 1;
            format = {
              months = "<span color='#ffead3'><b>{}</b></span>";
              weekdays = "<span color='#ffcc66'><b>{}</b></span>";
              today = "<span color='#ff6699'><b>{}</b></span>";
            };
          };
          actions = {
            on-click-right = "mode";
            on-click-forward = "tz_up";
            on-click-backward = "tz_down";
            on-scroll-up = "shift_up";
            on-scroll-down = "shift_down";
          };
        };
      };
      force = true;
      mutable = true;
    };

    # 天気モジュールから地名を消す
    ".config/waybar/modules/custom-weather.jsonc" = {
      text = builtins.toJSON {
        "custom/weather" = {
          exec = "WEATHER_SHOW_LOCATION=False hyde-shell weather";
          tooltip = true;
          format = "{0}";
          interval = 30;
          return-type = "json";
        };
      };
      force = true;
      mutable = true;
    };

    # ロック画面のフォントを SF Pro 風に変更
    ".config/hypr/hyprlock/theme.conf" = {
      text = "source = ./SF Pro.conf\n";
      force = true;
      mutable = true;
    };
  };
}
