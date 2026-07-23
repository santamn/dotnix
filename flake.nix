{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # 壁紙・カラースキームから全アプリのテーマを統一生成する
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:nixos/nixos-hardware/master";

    # command-not-found の代替 (nix-index) と comma のデータベース
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-firefox-addons = {
      url = "github:osipog/nix-firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {nixpkgs, ...} @ inputs: let
    # ホスト1台分の NixOS 設定を組み立てるヘルパー関数
    # 新しいマシンを追加するときは hosts/<name>/ を作り、下の nixosConfigurations に1行足すだけでよい
    # (詳細は docs/new-machine.md を参照)
    mkHost = hostName:
      nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/${hostName} # ホスト固有 (ハードウェア構成・stateVersion など)
          ./modules/nixos # 全ホスト共通のシステム設定
          inputs.home-manager.nixosModules.home-manager
          inputs.stylix.nixosModules.stylix
          {networking.hostName = hostName;}
        ];
      };
  in {
    # `nixos-rebuild switch --flake .` はホスト名と同名の設定を自動選択するため、
    # 通常はホスト名の指定は不要。明示指定したい場合は `.#thinkpad-x13-gen6` のようにキー名を渡す
    nixosConfigurations = {
      thinkpad-x13-gen6 = mkHost "thinkpad-x13-gen6";
    };

    # プロジェクトごとの devShell の雛形: `nix flake init -t ~/dotnix#rust` で展開できる
    templates = {
      rust = {
        path = ./templates/rust;
        description = "Rust 開発環境 (rust-analyzer / clippy / codelldb)";
      };
    };
  };
}
