{
  description = "NixOS configuration powered by hydenix";

  inputs = {
    nixpkgs = {
      # url = "github:nixos/nixpkgs/nixos-unstable"; # uncomment this if you know what you're doing
      follows = "hydenix/nixpkgs"; # then comment this
    };
    hydenix.url = "github:richen604/hydenix";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {...} @ inputs: let
    hydenixConfig = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs;
      };
      modules = [
        ./configuration.nix
        # モジュールの一つとしてアーキテクチャを指定
        {
          nixpkgs.hostPlatform = "x86_64-linux";
        }
      ];
    };
    vmConfig = inputs.hydenix.lib.vmConfig {
      inherit inputs;
      nixosConfiguration = hydenixConfig;
    };
  in {
    nixosConfigurations.hydenix = hydenixConfig;
    nixosConfigurations.default = hydenixConfig;
    packages."x86_64-linux".vm = vmConfig.config.system.build.vm;
  };
}
