# アイドル時の自動ロック・画面オフ・サスペンド (hypridle)
{...}: {
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock"; # 多重起動を防ぎつつロック
        before_sleep_cmd = "loginctl lock-session"; # サスペンド前にロック
        after_sleep_cmd = "hyprctl dispatch dpms on"; # 復帰時に画面をオン
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
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
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
