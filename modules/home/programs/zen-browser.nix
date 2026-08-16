{
  pkgs,
  inputs,
  config,
  ...
}: let
  # Home Manager が管理する Firefox プロファイルの置き場所
  # 旧来の ~/.mozilla/firefox ではなく XDG 準拠の位置に置く
  # (Home Manager 26.05 の新既定と同じ。~/.zen/profiles.ini からも参照するため
  #  二重管理にならないようここを唯一の定義とする)
  firefoxConfigPath = "${config.xdg.configHome}/mozilla/firefox";
in {
  # ===========================
  # Zen Browser Configuration
  # ===========================
  # Zen Browser は既定で ~/.zen を使うが、プロファイルの中身は Home Manager が
  # 上記 firefoxConfigPath で管理する。~/.zen/profiles.ini からそこを指させる
  home.file.".zen/profiles.ini".text = ''
    [Profile0]
    Name=default
    IsRelative=0
    Path=${firefoxConfigPath}/default
    Default=1

    [General]
    StartWithLastProfile=1
    Version=2
  '';

  programs.firefox = {
    enable = true;
    package = inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default;

    # プロファイルの置き場所 (既定値は stateVersion 依存で変わるため明示する)
    configPath = firefoxConfigPath;

    profiles.default = {
      id = 0;
      name = "default";
      isDefault = true;

      # Search engine
      search = {
        default = "ddg";
        force = true;
      };

      # Extensions (Firefox Add-ons)
      extensions.packages = with pkgs.firefoxAddons; [
        ublock-origin
        darkreader
        hide-youtube-shorts
        enhancer-for-youtube
        control-panel-for-twitter
        ublacklist
        plamo-translate
        foxscroller
        leechblock-ng
        uaswitcher
      ];

      settings = {
        # Localization
        "intl.locale.requested" = "ja,en-US,en";

        # optional: without this the addons need to be enabled manually after first install
        "extensions.autoDisableScopes" = 0;

        # Privacy settings
        "privacy.donottrackheader.enabled" = true;
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;

        # Disable telemetry
        "browser.newtabpage.activity-stream.feeds.telemetry" = false;
        "browser.newtabpage.activity-stream.telemetry" = false;
        "browser.ping-centre.telemetry" = false;
        "toolkit.telemetry.archive.enabled" = false;
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.unified" = false;

        # Performance
        "gfx.webrender.all" = true;
        "media.ffmpeg.vaapi.enabled" = true;

        # Zoom level
        # -1.0 is system default.
        # To zoom out (make things smaller):
        # - on standard display try "0.9" or "0.8"
        # - on Retina display try "1.5" or "1.7"
        "layout.css.devPixelsPerPx" = "1.2";

        # スクロール速度を半分にする
        "mousewheel.default.delta_multiplier_y" = 50;
      };
    };
  };

  # Set Zen Browser as default browser
  # (zen-browser flake の default = beta の desktop ファイル名は zen-beta.desktop)
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    "text/html" = "zen-beta.desktop";
    "text/xml" = "zen-beta.desktop";
    "application/xhtml+xml" = "zen-beta.desktop";
    "application/vnd.mozilla.xul+xml" = "zen-beta.desktop";
    "x-scheme-handler/http" = "zen-beta.desktop";
    "x-scheme-handler/https" = "zen-beta.desktop";
  };
}
