# Hyprland 本体の設定
# キーバインドは HyDE (hydenix) の既定配置をほぼ踏襲している
{
  config,
  lib,
  ...
}: let
  # stylix のカラースキーム (themes/decay-green.yaml) を "#" なしの16進で参照できる
  colors = config.lib.stylix.colors;

  # ワークスペース 1〜10 の移動・ウィンドウ送りバインドを生成
  # (キー 0 はワークスペース 10 に対応)
  workspaceBinds = builtins.concatLists (builtins.genList (
      i: let
        ws = toString (i + 1);
        key = toString (lib.mod (i + 1) 10);
      in [
        "$mainMod, ${key}, workspace, ${ws}" # ワークスペースへ移動
        "$mainMod Shift, ${key}, movetoworkspace, ${ws}" # ウィンドウを送って移動
        "$mainMod Alt, ${key}, movetoworkspacesilent, ${ws}" # ウィンドウだけ送る
      ]
    )
    10);
in {
  wayland.windowManager.hyprland = {
    enable = true;
    # Hyprland 本体とポータルはシステム側 (programs.hyprland) が提供するため、
    # Home Manager からは重複してインストールしない
    package = null;
    portalPackage = null;

    # waybar / hypridle などの systemd ユーザサービスが使う
    # graphical-session.target を提供する
    systemd = {
      enable = true;
      variables = ["--all"];
    };

    settings = {
      # よく使うアプリ
      "$mainMod" = "SUPER";
      "$terminal" = "ghostty";
      "$editor" = "ghostty -e nvim";
      "$explorer" = "dolphin";
      "$browser" = "zen";

      # モニタ: 接続されたものを推奨解像度・自動配置で使う
      monitor = [",preferred,auto,1"];

      exec-once = [
        "fcitx5 -d" # 日本語入力
      ];

      env = [
        "QT_QPA_PLATFORM,wayland;xcb"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
      ];

      input = {
        kb_layout = "us";
        # CapsLock と Ctrl キーを入れ替える
        kb_options = "ctrl:swapcaps";
        follow_mouse = 1;

        touchpad = {
          # 指の上下とスクロール方向を逆にする
          natural_scroll = true;
          # スクロール速度を半分にする
          scroll_factor = 0.5;

          # タッチパッドの押し込みをクリックとして扱う
          # 1本:左クリック 2本:右クリック 3本:中クリック
          clickfinger_behavior = true;
          # タップでクリックを有効化
          tap-to-click = true;
          # タップは 1本:左クリック 2本:中クリック 3本:右クリック
          tap_button_map = "lmr";
        };
      };

      # 3本指スワイプでワークスペースを切り替え
      gesture = ["3, horizontal, workspace"];

      general = {
        gaps_in = 3;
        gaps_out = 8;
        border_size = 2;
        # Decay Green のボーダー配色 (アクティブ: 緑→黄 / 非アクティブ: 青→シアン)
        "col.active_border" = "rgba(${colors.base0B}ff) rgba(${colors.base0A}ff) 45deg";
        "col.inactive_border" = "rgba(${colors.base0D}cc) rgba(${colors.base0C}cc) 45deg";
        layout = "dwindle";
        resize_on_border = true;
      };

      decoration = {
        rounding = 10;
        shadow.enabled = false;
        blur = {
          enabled = true;
          size = 5;
          passes = 4;
          new_optimizations = true;
          ignore_opacity = true;
          xray = false;
        };
      };

      animations = {
        enabled = true;
        bezier = [
          "wind, 0.05, 0.9, 0.1, 1.05"
          "winIn, 0.1, 1.1, 0.1, 1.1"
          "winOut, 0.3, -0.3, 0, 1"
          "liner, 1, 1, 1, 1"
        ];
        animation = [
          "windows, 1, 6, wind, slide"
          "windowsIn, 1, 6, winIn, slide"
          "windowsOut, 1, 5, winOut, slide"
          "windowsMove, 1, 5, wind, slide"
          "border, 1, 1, liner"
          "fade, 1, 10, default"
          "workspaces, 1, 5, wind"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        # 中クリックペーストを無効化
        middle_click_paste = false;
        vfr = true; # 画面更新がないときの消費電力を抑える
      };

      # ウィンドウルール: 設定系のダイアログはフローティングにする
      windowrule = [
        "float, class:^(org.pulseaudio.pavucontrol|pavucontrol)$"
        "float, class:^(\\.?blueman-manager(-wrapped)?)$"
        "float, class:^(nm-connection-editor)$"
        "float, class:^(fcitx5-config-qt)$"
        # ブラウザのピクチャインピクチャを右下に固定
        "float, title:^(Picture-in-Picture|ピクチャーインピクチャー|ピクチャインピクチャ)$"
        "pin, title:^(Picture-in-Picture|ピクチャーインピクチャー|ピクチャインピクチャ)$"
      ];

      # rofi の背後をぼかす
      layerrule = [
        "blur, rofi"
        "ignorezero, rofi"
      ];

      # ---- キーバインド ----
      bind =
        [
          # ウィンドウ管理
          "$mainMod, Q, killactive"
          "Alt, F4, killactive"
          "$mainMod, Delete, exit" # Hyprland セッション終了
          "$mainMod, W, togglefloating"
          "$mainMod, G, togglegroup"
          "Shift, F11, fullscreen"
          "$mainMod, F, fullscreen"
          "$mainMod, L, exec, loginctl lock-session" # 画面ロック
          "$mainMod Shift, F, pin" # 最前面に固定
          "Control Alt, Delete, exec, wlogout" # ログアウトメニュー
          "$mainMod, J, togglesplit"

          # グループ内の移動
          "$mainMod Control, H, changegroupactive, b"
          "$mainMod Control, L, changegroupactive, f"

          # フォーカス移動
          "$mainMod, Left, movefocus, l"
          "$mainMod, Right, movefocus, r"
          "$mainMod, Up, movefocus, u"
          "$mainMod, Down, movefocus, d"
          "Alt, Tab, cyclenext"

          # ウィンドウをワークスペース内で移動
          "$mainMod Shift Control, Left, movewindow, l"
          "$mainMod Shift Control, Right, movewindow, r"
          "$mainMod Shift Control, Up, movewindow, u"
          "$mainMod Shift Control, Down, movewindow, d"

          # アプリ起動
          "$mainMod, T, exec, $terminal"
          "$mainMod, E, exec, $explorer"
          "$mainMod, C, exec, $editor"
          "$mainMod, B, exec, $browser"
          "Control Shift, Escape, exec, $terminal -e btm" # システムモニタ

          # rofi メニュー
          "$mainMod, A, exec, pkill -x rofi || rofi -show drun" # アプリランチャー
          "$mainMod, Tab, exec, pkill -x rofi || rofi -show window" # ウィンドウ切り替え
          "$mainMod Shift, E, exec, pkill -x rofi || rofi -show filebrowser" # ファイル検索
          "$mainMod, V, exec, pkill -x rofi || cliphist list | rofi -dmenu -p 󰅍 | cliphist decode | wl-copy" # クリップボード履歴
          "$mainMod, comma, exec, rofimoji" # 絵文字ピッカー

          # スクリーンショット・カラーピッカー
          "$mainMod, P, exec, hyprshot -m region" # 範囲を選択して撮影
          "$mainMod Control, P, exec, hyprshot -m region -z" # 画面を停止して範囲撮影
          "$mainMod Alt, P, exec, hyprshot -m output -m active" # アクティブモニタを撮影
          ", Print, exec, hyprshot -m output" # モニタ全体を撮影
          "$mainMod Shift, P, exec, hyprpicker -an" # 色を取得してクリップボードへ

          # 相対ワークスペース移動
          "$mainMod Control, Right, workspace, r+1"
          "$mainMod Control, Left, workspace, r-1"
          "$mainMod Control, Down, workspace, empty" # 空きワークスペースへ
          "$mainMod Control Alt, Right, movetoworkspace, r+1"
          "$mainMod Control Alt, Left, movetoworkspace, r-1"
          "$mainMod, mouse_down, workspace, e+1"
          "$mainMod, mouse_up, workspace, e-1"

          # スクラッチパッド (special workspace)
          "$mainMod, S, togglespecialworkspace"
          "$mainMod Shift, S, movetoworkspace, special"
          "$mainMod Alt, S, movetoworkspacesilent, special"
        ]
        ++ workspaceBinds;

      # リサイズ (押しっぱなしで連続動作)
      binde = [
        "$mainMod Shift, Right, resizeactive, 30 0"
        "$mainMod Shift, Left, resizeactive, -30 0"
        "$mainMod Shift, Up, resizeactive, 0 -30"
        "$mainMod Shift, Down, resizeactive, 0 30"
      ];

      # マウス・ドラッグ操作
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
        "$mainMod, Z, movewindow"
        "$mainMod, X, resizewindow"
      ];

      # メディア・音量 (ロック画面でも効く)
      bindl = [
        ", F10, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPause, exec, playerctl play-pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
      ];

      # 音量・輝度 (押しっぱなしで連続動作、ロック画面でも効く)
      bindel = [
        ", F11, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", F12, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ];
    };
  };
}
