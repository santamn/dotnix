# Hyprland 本体の設定
# キーバインドは HyDE (hydenix) の既定配置をほぼ踏襲している
# HyDE の Keybinds Hint (SUPER+/) に倣い、バインド一覧を rofi で表示する機能も用意している
{
  config,
  lib,
  pkgs,
  ...
}: let
  # stylix のカラースキーム (壁紙から自動生成) を "#" なしの16進で参照できる
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

  # ---- キーバインド定義とチートシート生成 ----
  # 「実際の Hyprland バインド」と「SUPER+/ で表示するチートシート」が
  # 二重管理にならないよう、説明文つきのデータを1箇所にまとめてここから両方を導出する
  mkEntry = category: mods: key: action: desc: {inherit category mods key action desc;};

  # entry から Hyprland の "MODS, KEY, ACTION" 形式の文字列を組み立てる
  toHyprBind = e: "${e.mods}, ${e.key}, ${e.action}";

  # チートシート表示用にキー名を読みやすい表記へ変換する対応表
  keyLabels = {
    comma = ",";
    Print = "PrintScreen";
    mouse_down = "MouseWheel↓";
    mouse_up = "MouseWheel↑";
    "mouse:272" = "LeftClick";
    "mouse:273" = "RightClick";
    XF86AudioMute = "Mute";
    XF86AudioMicMute = "MicMute";
    XF86AudioPlay = "Play";
    XF86AudioPause = "Pause";
    XF86AudioNext = "Next";
    XF86AudioPrev = "Prev";
    XF86AudioLowerVolume = "Vol-";
    XF86AudioRaiseVolume = "Vol+";
    XF86MonBrightnessUp = "Bright+";
    XF86MonBrightnessDown = "Bright-";
  };
  keyLabel = key: keyLabels.${key} or key;

  # "$mainMod" などの変数名を表示用の修飾キー名へ変換する対応表
  modNames = {
    "$mainMod" = "SUPER";
    Control = "Ctrl";
  };
  modsLabel = mods: lib.concatMapStringsSep "+" (m: modNames.${m} or m) (lib.splitString " " mods);

  # 修飾キーとキーの組み合わせをチートシート用の1文字列にする (例: "SUPER+Shift+Q")
  keyCombo = mods: key:
    if mods == ""
    then keyLabel key
    else "${modsLabel mods}+${keyLabel key}";

  toCheatLine = e: "${keyCombo e.mods e.key} → ${e.desc}";

  # 実際にバインドされ、チートシートにも表示される主要バインド (bind)
  mainEntries = [
    (mkEntry "ウィンドウ管理" "$mainMod" "Q" "killactive" "ウィンドウを閉じる")
    (mkEntry "ウィンドウ管理" "Alt" "F4" "killactive" "ウィンドウを閉じる")
    (mkEntry "ウィンドウ管理" "$mainMod" "Delete" "exit" "Hyprland セッションを終了する")
    (mkEntry "ウィンドウ管理" "$mainMod" "W" "togglefloating" "フローティング表示を切り替える")
    (mkEntry "ウィンドウ管理" "$mainMod" "G" "togglegroup" "ウィンドウをグループ化する")
    (mkEntry "ウィンドウ管理" "Shift" "F11" "fullscreen" "全画面表示を切り替える")
    (mkEntry "ウィンドウ管理" "$mainMod" "F" "fullscreen" "全画面表示を切り替える")
    (mkEntry "ウィンドウ管理" "$mainMod" "L" "exec, loginctl lock-session" "画面をロックする")
    (mkEntry "ウィンドウ管理" "$mainMod Shift" "F" "pin" "最前面に固定する")
    (mkEntry "ウィンドウ管理" "Control Alt" "Delete" "exec, wlogout" "ログアウトメニューを開く")
    (mkEntry "ウィンドウ管理" "$mainMod" "J" "togglesplit" "分割方向を切り替える")

    (mkEntry "グループ内の移動" "$mainMod Control" "H" "changegroupactive, b" "グループ内の前のウィンドウへ")
    (mkEntry "グループ内の移動" "$mainMod Control" "L" "changegroupactive, f" "グループ内の次のウィンドウへ")

    (mkEntry "フォーカス移動" "$mainMod" "Left" "movefocus, l" "左のウィンドウへフォーカス移動")
    (mkEntry "フォーカス移動" "$mainMod" "Right" "movefocus, r" "右のウィンドウへフォーカス移動")
    (mkEntry "フォーカス移動" "$mainMod" "Up" "movefocus, u" "上のウィンドウへフォーカス移動")
    (mkEntry "フォーカス移動" "$mainMod" "Down" "movefocus, d" "下のウィンドウへフォーカス移動")
    (mkEntry "フォーカス移動" "Alt" "Tab" "cyclenext" "ウィンドウを順に切り替える")

    (mkEntry "ウィンドウ移動" "$mainMod Shift Control" "Left" "movewindow, l" "ウィンドウを左へ移動")
    (mkEntry "ウィンドウ移動" "$mainMod Shift Control" "Right" "movewindow, r" "ウィンドウを右へ移動")
    (mkEntry "ウィンドウ移動" "$mainMod Shift Control" "Up" "movewindow, u" "ウィンドウを上へ移動")
    (mkEntry "ウィンドウ移動" "$mainMod Shift Control" "Down" "movewindow, d" "ウィンドウを下へ移動")

    (mkEntry "アプリ起動" "$mainMod" "T" "exec, $terminal" "ターミナルを開く")
    (mkEntry "アプリ起動" "$mainMod" "E" "exec, $explorer" "ファイルマネージャを開く")
    (mkEntry "アプリ起動" "$mainMod" "C" "exec, $editor" "エディタを開く")
    (mkEntry "アプリ起動" "$mainMod" "B" "exec, $browser" "ブラウザを開く")
    (mkEntry "アプリ起動" "Control Shift" "Escape" "exec, $terminal -e btm" "システムモニタを開く")

    (mkEntry "rofi メニュー" "$mainMod" "A" "exec, pkill -x rofi || rofi -show drun" "アプリランチャーを開く")
    (mkEntry "rofi メニュー" "$mainMod" "Tab" "exec, pkill -x rofi || rofi -show window" "ウィンドウ切り替えメニューを開く")
    (mkEntry "rofi メニュー" "$mainMod Shift" "E" "exec, pkill -x rofi || rofi -show filebrowser" "ファイル検索を開く")
    (mkEntry "rofi メニュー" "$mainMod" "V" "exec, pkill -x rofi || cliphist list | rofi -dmenu -p 󰅍 | cliphist decode | wl-copy" "クリップボード履歴を開く")
    (mkEntry "rofi メニュー" "$mainMod" "comma" "exec, rofimoji" "絵文字ピッカーを開く")

    (mkEntry "スクリーンショット・カラーピッカー" "$mainMod" "P" "exec, hyprshot -m region" "範囲を選択して撮影")
    (mkEntry "スクリーンショット・カラーピッカー" "$mainMod Control" "P" "exec, hyprshot -m region -z" "画面を停止して範囲を撮影")
    (mkEntry "スクリーンショット・カラーピッカー" "$mainMod Alt" "P" "exec, hyprshot -m output -m active" "アクティブモニタを撮影")
    (mkEntry "スクリーンショット・カラーピッカー" "" "Print" "exec, hyprshot -m output" "モニタ全体を撮影")
    (mkEntry "スクリーンショット・カラーピッカー" "$mainMod Shift" "P" "exec, hyprpicker -an" "色を取得してクリップボードへコピー")

    (mkEntry "ワークスペース" "$mainMod Control" "Right" "workspace, r+1" "次のワークスペースへ")
    (mkEntry "ワークスペース" "$mainMod Control" "Left" "workspace, r-1" "前のワークスペースへ")
    (mkEntry "ワークスペース" "$mainMod Control" "Down" "workspace, empty" "空きワークスペースへ")
    (mkEntry "ワークスペース" "$mainMod Control Alt" "Right" "movetoworkspace, r+1" "次のワークスペースへウィンドウを送る")
    (mkEntry "ワークスペース" "$mainMod Control Alt" "Left" "movetoworkspace, r-1" "前のワークスペースへウィンドウを送る")
    (mkEntry "ワークスペース" "$mainMod" "mouse_down" "workspace, e+1" "次のワークスペースへ (ホイール)")
    (mkEntry "ワークスペース" "$mainMod" "mouse_up" "workspace, e-1" "前のワークスペースへ (ホイール)")

    (mkEntry "スクラッチパッド" "$mainMod" "S" "togglespecialworkspace" "スクラッチパッドの表示を切り替える")
    (mkEntry "スクラッチパッド" "$mainMod Shift" "S" "movetoworkspace, special" "スクラッチパッドへウィンドウを送る")
    (mkEntry "スクラッチパッド" "$mainMod Alt" "S" "movetoworkspacesilent, special" "スクラッチパッドへウィンドウだけ送る")
  ];

  # リサイズ (押しっぱなしで連続動作、binde)
  resizeEntries = [
    (mkEntry "リサイズ" "$mainMod Shift" "Right" "resizeactive, 30 0" "右へ拡大")
    (mkEntry "リサイズ" "$mainMod Shift" "Left" "resizeactive, -30 0" "左へ縮小")
    (mkEntry "リサイズ" "$mainMod Shift" "Up" "resizeactive, 0 -30" "上へ縮小")
    (mkEntry "リサイズ" "$mainMod Shift" "Down" "resizeactive, 0 30" "下へ拡大")
  ];

  # マウス・ドラッグ操作 (bindm)
  dragEntries = [
    (mkEntry "マウス操作" "$mainMod" "mouse:272" "movewindow" "ウィンドウをドラッグ移動")
    (mkEntry "マウス操作" "$mainMod" "mouse:273" "resizewindow" "ウィンドウをドラッグリサイズ")
    (mkEntry "マウス操作" "$mainMod" "Z" "movewindow" "ウィンドウをドラッグ移動")
    (mkEntry "マウス操作" "$mainMod" "X" "resizewindow" "ウィンドウをドラッグリサイズ")
  ];

  # メディア・音量 (ロック画面でも効く、bindl)
  mediaEntries = [
    (mkEntry "メディア・音量" "" "F10" "exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" "ミュート切り替え")
    (mkEntry "メディア・音量" "" "XF86AudioMute" "exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" "ミュート切り替え")
    (mkEntry "メディア・音量" "" "XF86AudioMicMute" "exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle" "マイクミュート切り替え")
    (mkEntry "メディア・音量" "" "XF86AudioPlay" "exec, playerctl play-pause" "再生・一時停止")
    (mkEntry "メディア・音量" "" "XF86AudioPause" "exec, playerctl play-pause" "再生・一時停止")
    (mkEntry "メディア・音量" "" "XF86AudioNext" "exec, playerctl next" "次の曲")
    (mkEntry "メディア・音量" "" "XF86AudioPrev" "exec, playerctl previous" "前の曲")
  ];

  # 音量・輝度 (押しっぱなしで連続動作、ロック画面でも効く、bindel)
  sliderEntries = [
    (mkEntry "音量・輝度" "" "F11" "exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-" "音量を下げる")
    (mkEntry "音量・輝度" "" "F12" "exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+" "音量を上げる")
    (mkEntry "音量・輝度" "" "XF86AudioLowerVolume" "exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-" "音量を下げる")
    (mkEntry "音量・輝度" "" "XF86AudioRaiseVolume" "exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+" "音量を上げる")
    (mkEntry "音量・輝度" "" "XF86MonBrightnessUp" "exec, brightnessctl set 5%+" "輝度を上げる")
    (mkEntry "音量・輝度" "" "XF86MonBrightnessDown" "exec, brightnessctl set 5%-" "輝度を下げる")
  ];

  # ワークスペース 1〜10 の一括バインド (workspaceBinds) はチートシートには要約だけを載せる
  workspaceCheatOnly = [
    (mkEntry "ワークスペース" "$mainMod" "1〜0" "" "該当ワークスペースへ移動")
    (mkEntry "ワークスペース" "$mainMod Shift" "1〜0" "" "ウィンドウを送って移動")
    (mkEntry "ワークスペース" "$mainMod Alt" "1〜0" "" "ウィンドウだけ送る (フォーカスは移動しない)")
  ];

  # キーバインド一覧を表示するバインド自体もチートシートに含める
  # (実際のバインドは keybindsHint の store path に依存するため下記で別途組み立てる)
  keybindsHintCheatEntry = mkEntry "rofi メニュー" "$mainMod" "slash" "" "キーバインド一覧を表示する";

  cheatEntries =
    mainEntries
    ++ resizeEntries
    ++ dragEntries
    ++ mediaEntries
    ++ sliderEntries
    ++ workspaceCheatOnly
    ++ [keybindsHintCheatEntry];

  # チートシートでの見出し表示順 (Nix の属性集合は挿入順を保持しないため明示的に順序を持たせる)
  categoryOrder = [
    "ウィンドウ管理"
    "グループ内の移動"
    "フォーカス移動"
    "ウィンドウ移動"
    "アプリ起動"
    "rofi メニュー"
    "スクリーンショット・カラーピッカー"
    "ワークスペース"
    "スクラッチパッド"
    "リサイズ"
    "マウス操作"
    "メディア・音量"
    "音量・輝度"
  ];

  cheatSheetText = lib.concatStringsSep "\n\n" (map (
      cat:
        lib.concatStringsSep "\n" (
          ["── ${cat} ──"]
          ++ map toCheatLine (builtins.filter (e: e.category == cat) cheatEntries)
        )
    )
    categoryOrder);

  # SUPER+/ で起動する、キーバインド一覧を rofi に表示するスクリプト (HyDE の Keybinds Hint 相当)
  keybindsHint = pkgs.writeShellApplication {
    name = "hypr-keybinds-hint";
    runtimeInputs = [pkgs.rofi];
    text = ''
      rofi -dmenu -i -p "󰌌 Keybinds" -theme-str 'window {width: 45%; height: 65%;} listview {lines: 20;}' <<'EOF'
      ${cheatSheetText}
      EOF
    '';
  };
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
        # ボーダー配色 (アクティブ: base0B→base0A / 非アクティブ: base0D→base0C のグラデーション)
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
      # mainEntries などのデータから生成 (詳細は上の let ブロックを参照)
      bind =
        (map toHyprBind mainEntries)
        ++ workspaceBinds
        ++ ["$mainMod, slash, exec, pkill -x rofi || ${keybindsHint}/bin/hypr-keybinds-hint"]; # キーバインド一覧を表示 (HyDE の Keybinds Hint 相当)

      binde = map toHyprBind resizeEntries;
      bindm = map toHyprBind dragEntries;
      bindl = map toHyprBind mediaEntries;
      bindel = map toHyprBind sliderEntries;
    };
  };

  home.packages = [keybindsHint];
}
