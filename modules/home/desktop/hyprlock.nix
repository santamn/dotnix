# ロック画面 (hyprlock)
# 旧 HyDE の "SF Pro" レイアウトに近い、大きな時計とシンプルな入力欄の構成。
# 指紋認証は hyprlock 内蔵のサポートを使うことで、指紋の読み取りを待ちながら
# 同時にパスワード入力もできる (PAM 側の設定は modules/nixos/fingerprint.nix)
{config, ...}: let
  colors = config.lib.stylix.colors;
in {
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
      };

      auth = {
        "pam:enabled" = true;
        # 指紋認証を有効化 (パスワード入力と並行して受け付ける)
        "fingerprint:enabled" = true;
        "fingerprint:ready_message" = "(指紋でも解除できます)";
        "fingerprint:present_message" = "指紋を確認しています...";
      };

      background = [
        {
          monitor = "";
          path = "${config.stylix.image}";
          blur_passes = 2;
          blur_size = 6;
          brightness = 0.5;
        }
      ];

      label = [
        # 時計 (SF Pro 風の大きく細いフォント)
        {
          monitor = "";
          text = "$TIME";
          font_size = 150;
          font_family = "Inter Light";
          color = "rgba(${colors.base07}ee)";
          position = "0, 300";
          halign = "center";
          valign = "center";
        }
        # 日付 (YYYY-MM-DD 形式 + 曜日)
        {
          monitor = "";
          text = ''cmd[update:60000] date +"%Y-%m-%d (%a)"'';
          font_size = 20;
          font_family = "Inter";
          color = "rgba(${colors.base06}cc)";
          position = "0, 180";
          halign = "center";
          valign = "center";
        }
        # ユーザ名
        {
          monitor = "";
          text = "$USER";
          font_size = 16;
          font_family = "Inter";
          color = "rgba(${colors.base05}cc)";
          position = "0, -120";
          halign = "center";
          valign = "center";
        }
      ];

      # パスワード入力欄 (指紋関連のメッセージもここに表示される)
      input-field = [
        {
          monitor = "";
          size = "300, 50";
          outline_thickness = 2;
          dots_size = 0.25;
          dots_spacing = 0.2;
          outer_color = "rgba(${colors.base0B}aa)";
          inner_color = "rgba(${colors.base01}dd)";
          font_color = "rgba(${colors.base06}ff)";
          placeholder_text = "<i>パスワード または 指紋</i>";
          fail_text = "<i>認証に失敗しました ($ATTEMPTS 回)</i>";
          fade_on_empty = false;
          rounding = 12;
          position = "0, -180";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
