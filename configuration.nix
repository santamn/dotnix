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
    # Force a git-based fetch for HyDE themes (avoid tarball download/unpack).
    (
      final: prev: let
        themePkgs =
          prev
          // {
            fetchFromGitHub = args:
              prev.fetchgit {
                url = "https://github.com/${args.owner}/${args.repo}";
                rev = args.rev;
                hash =
                  args.hash or (args.sha256 or (
                    throw "hydenix theme fetchFromGitHub wrapper: missing hash/sha256 for ${args.owner}/${args.repo}@${args.rev}"
                  ));
                fetchSubmodules = args.fetchSubmodules or false;
                leaveDotGit = false;
              };
          };

        themesPath = "${inputs.hydenix}/hydenix/sources/themes/default.nix";
      in {
        hydenix-themes = import themesPath {pkgs = themePkgs;};
      }
    )
  ];

  # GitHub tarball download can occasionally truncate on some networks.
  # These settings make Nix fetches more robust (retries + IPv4 + HTTP/1.1).
  nix.settings = {
    download-attempts = 10;
    connect-timeout = 10;
    stalled-download-timeout = 60;
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
    # 既存のファイルがある場合、拡張子 .backup をつけて退避させ、エラーにしない
    backupFileExtension = "backup";
    extraSpecialArgs = {inherit inputs;};
    useGlobalPkgs = true;
    useUserPackages = true;

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
