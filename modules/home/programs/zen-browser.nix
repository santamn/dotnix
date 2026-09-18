{
  pkgs,
  lib,
  inputs,
  ...
}: let
  # GitHub Releases の xpi ファイルを取得して Firefox にアドオンとして導入する関数
  githubXpiAddon = name: release: namePattern: let
    asset =
      lib.findFirst (a: builtins.match namePattern a.name != null)
      (throw "${name}: ${namePattern} に一致するアセットが見つかりませんでした")
      (builtins.fromJSON (builtins.readFile release)).assets;

    xpi = pkgs.fetchurl {
      url = asset.browser_download_url;
      sha256 = lib.removePrefix "sha256:" asset.digest;
    };
  in
    pkgs.runCommand "firefox-addon-${name}" {
      nativeBuildInputs = [pkgs.unzip pkgs.jq];
    } ''
      id=$(unzip -p ${xpi} manifest.json | jq -er '.browser_specific_settings.gecko.id')
      install -Dm644 ${xpi} \
        "$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/$id.xpi"
    '';
in {
  programs.firefox = {
    enable = true;
    package = inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default;
    configPath = ".zen";

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
      extensions.packages =
        (with pkgs.firefoxAddons; [
          ublock-origin
          darkreader
          control-panel-for-youtube
          control-panel-for-twitter
          ublacklist
          plamo-translate
          foxscroller
          leechblock-ng
          uaswitcher
        ])
        ++ [
          (githubXpiAddon "widevine-proxy2" inputs.widevine-proxy2-release "^WidevineProxy2-([0-9]+\\.)+xpi$")
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
