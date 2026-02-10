{
  pkgs,
  lib,
  ...
}: {
  imports = [
    # ./example.nix - add your modules here
  ];

  environment.systemPackages = with pkgs; [
    git
  ];

  # ===========================
  # Shell
  # ===========================
  # Enable zsh system-wide (adds to /etc/shells, enables completion)
  programs.zsh.enable = true;

  # ===========================
  # Bluetooth
  # ===========================
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true; # Bluetooth manager GUI

  # ===========================
  # Power Management (TLP for laptops)
  # ===========================
  services.tlp = {
    enable = true;
    settings = {
      # Battery thresholds for ThinkPad to extend battery life
      START_CHARGE_THRESH_BAT0 = 40;
      STOP_CHARGE_THRESH_BAT0 = 80;

      # CPU scaling
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    };
  };
  # TLP と power-profiles-daemon は競合するため無効化
  services.power-profiles-daemon.enable = lib.mkForce false;

  # ===========================
  # Japanese Input Method
  # ===========================
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk
    ];
  };

  # ===========================
  # Virtualization (Docker & Podman)
  # ===========================
  virtualisation.docker.enable = true;
  virtualisation.podman = {
    enable = true;
    dockerCompat = false; # Docker is already enabled
  };

  # ===========================
  # Nix Garbage Collection
  # ===========================
  nix.gc = {
    automatic = true; # Enable automatic garbage collection
    dates = "weekly"; # Run weekly
    options = "--delete-older-than 30d"; # Delete generations older than 30 days
  };

  # Automatically optimize the Nix store to save disk space
  nix.settings.auto-optimise-store = true;

  # ===========================
  # Input Devices & Hardware
  # ===========================
  # Enable fingerprint reader
  services.fprintd.enable = true;
  # sudo コマンド実行時に指紋認証を許可する（sshd ではなく sudo）
  security.pam.services.sudo.enableFingerprintAuth = true;

  # Touchpad settings
  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = true; # Scroll content down when swiping up (Natural Scrolling)
    };
  };

  # Keyboard settings (Swap CapsLock and Ctrl)
  services.xserver.xkb.options = "ctrl:swapcaps";
  console.useXkbConfig = true; # Apply xkb options to console

  # ===========================
  # Fonts
  # ===========================
  fonts = {
    packages = with pkgs; [
      nerd-fonts.fira-code
      nerd-fonts.hack
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      terminus_font
      cantarell-fonts
    ];
    fontDir.enable = true;
    fontconfig = {
      defaultFonts = {
        serif = [
          "Noto Serif CJK JP"
          "Noto Color Emoji"
        ];
        sansSerif = [
          "Noto Sans CJK JP"
          "Noto Color Emoji"
        ];
        emoji = ["Noto Color Emoji"];
      };
    };
  };
}
