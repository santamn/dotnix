{
  pkgs,
  inputs,
  config,
  ...
}: {
  # ===========================
  # Zen Browser Configuration
  # ===========================
  # Zen Browser uses ~/.zen directory by default, but Home Manager manages ~/.mozilla/firefox.
  # We create a profiles.ini in ~/.zen that points to the Home Manager managed profile.
  home.file.".zen/profiles.ini".text = ''
    [Profile0]
    Name=default
    IsRelative=0
    Path=${config.home.homeDirectory}/.mozilla/firefox/default
    Default=1

    [General]
    StartWithLastProfile=1
    Version=2
  '';

  programs.firefox = {
    enable = true;
    package = inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default;

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

        # Scroll behavior
        "mousewheel.default.delta_multiplier_y" = 50; # Default is 100, set to 50 for slower scrolling

        # Zoom level
        # -1.0 is system default.
        # To zoom out (make things smaller):
        # - on standard display try "0.9" or "0.8"
        # - on Retina display try "1.5" or "1.7"
        "layout.css.devPixelsPerPx" = "1.0";
      };
    };
  };

  # Set Zen Browser as default browser
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    "text/html" = "zen.desktop";
    "text/xml" = "zen.desktop";
    "application/xhtml+xml" = "zen.desktop";
    "application/vnd.mozilla.xul+xml" = "zen.desktop";
    "x-scheme-handler/http" = "zen.desktop";
    "x-scheme-handler/https" = "zen.desktop";
  };
}
