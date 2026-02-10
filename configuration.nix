{
  inputs,
  pkgs,
  lib,
  ...
}:
# FOLLOW THE BELOW INSTRUCTIONS LINE BY LINE TO SET UP YOUR SYSTEM
{
  imports = [
    # hydenix inputs - Required modules, don't modify unless you know what you're doing
    inputs.hydenix.inputs.home-manager.nixosModules.home-manager
    inputs.hydenix.nixosModules.default
    ./modules/system # Your custom system modules
    ./hardware-configuration.nix # Auto-generated hardware config

    # Hardware Configuration - Uncomment lines that match your hardware
    # Run `lshw -short` or `lspci` to identify your hardware

    # GPU Configuration (choose one):
    # inputs.nixos-hardware.nixosModules.common-gpu-nvidia # NVIDIA
    # inputs.nixos-hardware.nixosModules.common-gpu-amd # AMD

    # CPU Configuration (choose one):
    # inputs.nixos-hardware.nixosModules.common-cpu-amd # AMD CPUs
    inputs.nixos-hardware.nixosModules.common-cpu-intel # Intel CPUs

    # Additional Hardware Modules - Uncomment based on your system type:
    # inputs.nixos-hardware.nixosModules.common-hidpi # High-DPI displays
    inputs.nixos-hardware.nixosModules.common-pc-laptop # Laptops
    inputs.nixos-hardware.nixosModules.common-pc-ssd # SSD storage
  ];

  nixpkgs.overlays = lib.mkAfter [
    inputs.nix-firefox-addons.overlays.default

    # Workaround for occasional GitHub tarball truncation (Unexpected EOF).
    # Force a git-based fetch for the themes that frequently fail on some networks.
    (
      final: prev: let
        hasHydenixThemes = prev ? hydenix-themes;

        mkFetchGit = {
          url,
          rev,
          hash,
        }:
          prev.fetchgit {
            inherit url rev;
            inherit hash;
          };

        overrideThemeSrc = themeName: newSrc:
          if hasHydenixThemes && builtins.hasAttr themeName prev.hydenix-themes
          then prev.hydenix-themes.${themeName}.overrideAttrs (_: {src = newSrc;})
          else null;

        overrides = lib.filterAttrs (_: v: v != null) {
          "Rain Dark" = overrideThemeSrc "Rain Dark" (mkFetchGit {
            url = "https://github.com/rishav12s/Rain-Dark";
            rev = "da26bafb755fcd96d107cc7b60db43e85e3a3876";
            hash = "sha256-zv66a/fh3xqOIYVD6OUi4ZEpn3L29J2vvBnPBjeQW7w=";
          });

          "Catppuccin Mocha" = overrideThemeSrc "Catppuccin Mocha" (mkFetchGit {
            url = "https://github.com/HyDE-Project/hyde-themes";
            rev = "415d22a6bb6348a6d09c11307be54c592fb15138";
            hash = "sha256-GoXRPYUFdrw6P8OeOsSiFDC9FhaEyo1+lvta0FCJoPY=";
          });

          "Catppuccin Latte" = overrideThemeSrc "Catppuccin Latte" (mkFetchGit {
            url = "https://github.com/HyDE-Project/hyde-themes";
            rev = "9a9332bb660ecb2e05671b7dcd7dd058b0803e48";
            hash = "sha256-dW5DgXFxFNjt54Styzk+Ew3pv4rO1FX/qtfDGIClLuY=";
          });

          "Catppuccin-Macchiato" = overrideThemeSrc "Catppuccin-Macchiato" (mkFetchGit {
            url = "https://github.com/deepu105/hyde-theme-catppuccin-macchiato";
            rev = "7f1f33e554a342afcc9723d9b87123aa964cf994";
            hash = "sha256-W5xjs+E//G2uhwzjq2tiWUMNdff6xmWUvH59tUoKjA0=";
          });
        };
      in
        lib.optionalAttrs hasHydenixThemes {
          hydenix-themes = prev.hydenix-themes // overrides;
        }
    )
  ];

  # GitHub tarball download can occasionally truncate on some networks.
  # These settings make Nix fetches more robust (retries + IPv4 + HTTP/1.1).
  nix.settings = {
    download-attempts = 10;
    connect-timeout = 10;
    stalled-download-timeout = 60;
    curl-flags = [
      "-4"
      "--http1.1"
      "--retry"
      "10"
      "--retry-all-errors"
      "--retry-delay"
      "1"
      "--connect-timeout"
      "10"
      "--speed-time"
      "30"
      "--speed-limit"
      "1024"
    ];
  };

  # If enabling NVIDIA, you will be prompted to configure hardware.nvidia
  # hardware.nvidia = {
  #   open = true; # For newer cards, you may want open drivers
  #   prime = { # For hybrid graphics (laptops), configure PRIME:
  #     amdBusId = "PCI:0:2:0"; # Run `lspci | grep VGA` to get correct bus IDs
  #     intelBusId = "PCI:0:2:0"; # if you have intel graphics
  #     nvidiaBusId = "PCI:1:0:0";
  #     offload.enable = false; # Or disable PRIME offloading if you don't care
  #   };
  # };

  # Home Manager Configuration - manages user-specific configurations (dotfiles, themes, etc.)
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {inherit inputs;};

    # User Configuration - REQUIRED: Change "hydenix" to your actual username
    # This must match the username you define in users.users below
    users."santamn" = {...}: {
      imports = [
        inputs.hydenix.homeModules.default
        inputs.nix-index-database.homeModules.nix-index # Command-not-found and comma tool support
        ./modules/hm # Your custom home-manager modules (configure hydenix.hm here!)
      ];
    };
  };

  # User Account Setup - REQUIRED: Change "hydenix" to your desired username (must match above)
  users.users.santamn = {
    isNormalUser = true;
    initialPassword = "hydenix"; # SECURITY: Change this password after first login with `passwd`
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "docker"
    ]; # User groups (determines permissions)
    shell = pkgs.zsh; # Login shell: zsh (interactive shell auto-switches to nushell)
  };

  # Hydenix Configuration - Main configuration for the Hydenix desktop environment
  hydenix = {
    enable = true; # Enable Hydenix modules
    # Basic System Settings (REQUIRED):
    hostname = "thinkpad-x13-gen6"; # REQUIRED: Set your computer's network name (change to something unique)
    timezone = "Asia/Tokyo"; # REQUIRED: Set timezone (examples: "America/New_York", "Europe/London", "Asia/Tokyo")
    locale = "ja_JP.UTF-8"; # REQUIRED: Set locale/language (examples: "en_US.UTF-8", "en_GB.UTF-8", "de_DE.UTF-8")
  };

  # System Version - Don't change unless you know what you're doing (helps with system upgrades and compatibility)
  system.stateVersion = "25.05";
}
