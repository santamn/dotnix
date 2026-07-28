# ログアウト・電源メニュー (wlogout)
#
# HyDE の style_1 (画面中央に横一列の大きなボタン) の移植。
# 配色は stylix のスキームから取る。
# 背面のぼかしは hyprland.nix の layer_rule (namespace: logout_dialog) が担当
{
  config,
  pkgs,
  ...
}: let
  colors = config.lib.stylix.colors;

  # wlogout 同梱のアイコンを白に塗り替えたもの (暗色テーマで見えるようにする)
  icons =
    pkgs.runCommand "wlogout-icons-white" {
      nativeBuildInputs = [pkgs.imagemagick];
    } ''
      mkdir -p $out
      for f in ${pkgs.wlogout}/share/wlogout/icons/*.png; do
        magick "$f" -channel RGB -fill '#ffffff' -colorize 100 "$out/$(basename "$f")"
      done
    '';

  # ボタン中央の余白 (px)。HyDE はモニタ解像度から動的計算するが、ここでは
  # thinkpad-x13-gen6 の 1920x1200 を基準に静的に決めている
  # (縦: 28% ≈ 336px、ホバー時: 23% ≈ 276px で上下に少し伸びる)
  margin = "336";
  hoverMargin = "276";
in {
  programs.wlogout = {
    enable = true;

    # HyDE の layout_1 と同じ6ボタン構成 (アクションはこの環境向けに置き換え)
    layout = [
      {
        label = "lock";
        action = "loginctl lock-session";
        text = "ロック";
        keybind = "l";
      }
      {
        label = "logout";
        action = "hyprctl dispatch 'hl.dsp.exit()'";
        text = "ログアウト";
        keybind = "e";
      }
      {
        label = "suspend";
        action = "systemctl suspend";
        text = "サスペンド";
        keybind = "u";
      }
      {
        label = "shutdown";
        action = "systemctl poweroff";
        text = "シャットダウン";
        keybind = "s";
      }
      {
        label = "hibernate";
        action = "systemctl hibernate";
        text = "休止状態";
        keybind = "h";
      }
      {
        label = "reboot";
        action = "systemctl reboot";
        text = "再起動";
        keybind = "r";
      }
    ];

    style = ''
      * {
        background-image: none;
        font-family: "${config.stylix.fonts.sansSerif.name}";
        font-size: 20px;
      }

      window {
        background-color: rgba(${colors."base00-rgb-r"}, ${colors."base00-rgb-g"}, ${colors."base00-rgb-b"}, 0.5);
      }

      button {
        color: #${colors.base05};
        background-color: rgba(${colors."base01-rgb-r"}, ${colors."base01-rgb-g"}, ${colors."base01-rgb-b"}, 0.9);
        outline-style: none;
        border: none;
        border-width: 0px;
        background-repeat: no-repeat;
        background-position: center;
        background-size: 20%;
        border-radius: 0px;
        box-shadow: none;
        text-shadow: none;
        margin: ${margin}px 0px ${margin}px 0px;
      }

      button:focus {
        background-color: rgba(${colors."base02-rgb-r"}, ${colors."base02-rgb-g"}, ${colors."base02-rgb-b"}, 0.9);
        background-size: 30%;
      }

      button:hover {
        color: #${colors.base00};
        background-color: #${colors.base0B};
        background-size: 40%;
        border-radius: 15px;
        margin: ${hoverMargin}px 0px ${hoverMargin}px 0px;
        transition: all 0.3s cubic-bezier(.55, 0.0, .28, 1.682);
      }

      #lock {
        background-image: image(url("${icons}/lock.png"));
        border-radius: 30px 0px 0px 30px;
        margin-left: 40px;
      }

      #logout {
        background-image: image(url("${icons}/logout.png"));
      }

      #suspend {
        background-image: image(url("${icons}/suspend.png"));
      }

      #shutdown {
        background-image: image(url("${icons}/shutdown.png"));
      }

      #hibernate {
        background-image: image(url("${icons}/hibernate.png"));
      }

      #reboot {
        background-image: image(url("${icons}/reboot.png"));
        border-radius: 0px 30px 30px 0px;
        margin-right: 40px;
      }

      #lock:hover, #reboot:hover {
        border-radius: 15px;
      }
    '';
  };
}
