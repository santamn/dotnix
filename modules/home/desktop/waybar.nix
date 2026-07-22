# ステータスバー (waybar)
# 配色は stylix のスキーム (themes/decay-green.yaml) から取得している
{config, ...}: let
  colors = config.lib.stylix.colors.withHashtag;
in {
  programs.waybar = {
    enable = true;
    # Hyprland セッション開始時に systemd ユーザサービスとして起動
    systemd.enable = true;

    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 32;
      spacing = 4;

      modules-left = ["hyprland/workspaces" "hyprland/window"];
      modules-center = ["clock"];
      modules-right = [
        "tray"
        "idle_inhibitor"
        "pulseaudio"
        "pulseaudio#microphone"
        "backlight"
        "network"
        "bluetooth"
        "battery"
        "custom/power"
      ];

      "hyprland/workspaces" = {
        format = "{id}";
        on-click = "activate";
        sort-by-number = true;
      };

      "hyprland/window" = {
        max-length = 40;
        separate-outputs = true;
      };

      # 日付は YYYY-MM-DD 形式で表示する
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

      tray = {
        icon-size = 16;
        spacing = 8;
      };

      idle_inhibitor = {
        format = "{icon}";
        format-icons = {
          activated = ""; # 画面を消灯させない状態
          deactivated = "";
        };
        tooltip-format-activated = "自動ロック無効";
        tooltip-format-deactivated = "自動ロック有効";
      };

      pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = "󰝟 {volume}%";
        format-icons = {
          headphone = "󰋋";
          default = ["󰕿" "󰖀" "󰕾"];
        };
        scroll-step = 5;
        on-click = "pavucontrol";
        tooltip-format = "{desc}";
      };

      "pulseaudio#microphone" = {
        format = "{format_source}";
        format-source = "󰍬";
        format-source-muted = "󰍭";
        on-click = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
        tooltip-format = "マイク {source_volume}%";
      };

      backlight = {
        format = "{icon} {percent}%";
        format-icons = ["󰃞" "󰃟" "󰃠"];
      };

      network = {
        format-wifi = "󰤨";
        format-ethernet = "󰈀";
        format-disconnected = "󰤭";
        tooltip-format-wifi = "{essid} ({signalStrength}%)";
        tooltip-format-ethernet = "{ipaddr}";
        tooltip-format-disconnected = "切断";
        on-click = "nm-connection-editor";
      };

      bluetooth = {
        format = "󰂯";
        format-disabled = "󰂲";
        format-connected = "󰂱 {num_connections}";
        tooltip-format-connected = "{device_enumerate}";
        on-click = "blueman-manager";
      };

      battery = {
        states = {
          warning = 30;
          critical = 15;
        };
        format = "{icon} {capacity}%";
        format-charging = "󰂄 {capacity}%";
        format-icons = ["󰁺" "󰁼" "󰁾" "󰂀" "󰁹"];
      };

      "custom/power" = {
        format = "⏻";
        tooltip = false;
        on-click = "wlogout";
      };
    };

    style = ''
      * {
        font-family: "FiraCode Nerd Font", "Noto Sans CJK JP", sans-serif;
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background: alpha(${colors.base00}, 0.85);
        color: ${colors.base05};
      }

      #workspaces {
        margin: 3px;
        padding: 0 4px;
        background: ${colors.base01};
        border-radius: 10px;
      }

      #workspaces button {
        padding: 0 6px;
        color: ${colors.base04};
        border-radius: 10px;
      }

      #workspaces button.active {
        color: ${colors.base00};
        background: ${colors.base0B};
      }

      #workspaces button.urgent {
        color: ${colors.base00};
        background: ${colors.base08};
      }

      #window {
        margin-left: 8px;
        color: ${colors.base05};
      }

      #clock {
        margin: 3px;
        padding: 0 12px;
        background: ${colors.base01};
        color: ${colors.base0B};
        border-radius: 10px;
      }

      #tray,
      #idle_inhibitor,
      #pulseaudio,
      #pulseaudio.microphone,
      #backlight,
      #network,
      #bluetooth,
      #battery,
      #custom-power {
        margin: 3px 2px;
        padding: 0 10px;
        background: ${colors.base01};
        border-radius: 10px;
      }

      #battery.warning {
        color: ${colors.base0A};
      }

      #battery.critical {
        color: ${colors.base08};
      }

      #battery.charging {
        color: ${colors.base0B};
      }

      #custom-power {
        color: ${colors.base08};
        padding-right: 13px;
      }

      tooltip {
        background: ${colors.base00};
        border: 1px solid ${colors.base0B};
        border-radius: 8px;
      }
    '';
  };
}
