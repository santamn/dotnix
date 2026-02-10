{pkgs, ...}: {
  # Fcitx5 本体とアドオンのインストール・有効化
  i18n.inputMethod = {
    enabled = "fcitx5";

    fcitx5 = {
      addons = with pkgs; [
        fcitx5-mozc
        fcitx5-gtk
        qt6Packages.fcitx5-configtool
      ];
      waylandFrontend = true;

      settings = {
        inputMethod = {
          # キーボードレイアウトと入力メソッドのグループ設定 (~/.config/fcitx5/profile)
          GroupOrder = {
            "0" = "Default";
          };
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = "us";
            DefaultIM = "mozc";
          };
          "Groups/0/Items/0" = {
            Name = "keyboard-us";
            Layout = "";
          };
          "Groups/0/Items/1" = {
            Name = "mozc";
            Layout = "";
          };
        };

        # グローバルキー設定 (~/.config/fcitx5/config)
        globalOptions = {
          Hotkey = {
            # トグル式の入力切り替えを無効化
            TriggerKeys."0" = "";
            # 右Alt → 日本語入力 (Mozc) に切り替え
            ActivateKeys."0" = "Alt_R";
            # 左Alt → 英語入力 (Direct Input) に切り替え
            DeactivateKeys."0" = "Alt_L";
          };
        };

        # アドオンの設定 (~/.config/fcitx5/conf/classicui.conf)
        addons = {
          classicui = {
            # 縦書き候補ウィンドウを有効にするか
            "Vertical Candidate List" = false;
            # システムのスケールに追従
            PerScreenDPI = true;
            # フォント設定 (お好みに合わせて変更してください)
            Font = "Noto Sans CJK JP 12";
            # テーマ (Catppuccinなどを入れている場合は "catppuccin-mocha" 等も指定可能)
            Theme = "Default";
          };
        };
      };
    };
  };
}
