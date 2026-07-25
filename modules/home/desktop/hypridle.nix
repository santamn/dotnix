# アイドル時の自動ロック・画面オフ・サスペンド (hypridle)
#
# Hyprland 0.55 以降、hyprctl dispatch の引数は Lua の式になった
# (旧: `hyprctl dispatch dpms on` → 新: `hyprctl dispatch 'hl.dsp.dpms({ action = "on" })'`)
{...}: let
  # 画面のオン・オフを行う hyprctl コマンド
  dpms = action: "hyprctl dispatch 'hl.dsp.dpms({ action = \"${action}\" })'";
in {
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock"; # 多重起動を防ぎつつロック
        before_sleep_cmd = "loginctl lock-session"; # サスペンド前にロック
        after_sleep_cmd = dpms "on"; # 復帰時に画面をオン
      };

      listener = [
        # 15分で画面をロック
        {
          timeout = 900;
          on-timeout = "loginctl lock-session";
        }
        # 20分で画面をオフ
        {
          timeout = 1200;
          on-timeout = dpms "off";
          on-resume = dpms "on";
        }
        # 30分でサスペンド
        {
          timeout = 1800;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
