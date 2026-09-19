{
  description = "NixOS configuration powered by hydenix";

  # hydenix (Hyprland を自前ビルドすると重い) 向けのバイナリキャッシュ
  nixConfig = {
    extra-substituters = ["https://hyprland.cachix.org"];
    extra-trusted-substituters = ["https://hyprland.cachix.org"];
    extra-trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
  };

  inputs = {
    # hydenix が固定している nixpkgs に揃える。
    # 独自の nixpkgs を使うと hydenix 側とパッケージが二重になり不具合が出る
    nixpkgs.follows = "hydenix/nixpkgs";
    hydenix.url = "github:santamn/hydenix";
    nixos-hardware.follows = "hydenix/nixos-hardware";

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-firefox-addons = {
      url = "github:osipog/nix-firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    widevine-proxy2-release = {
      url = "file+https://api.github.com/repos/DevLARLEY/WidevineProxy2/releases/latest";
      flake = false;
    };

    # --- AI エージェント用の skill とプラグイン ---
    # どれも Nix のビルドは不要でファイルを配るだけなので flake = false
    superpowers = {
      url = "github:obra/superpowers";
      flake = false;
    };
    ponytail = {
      url = "github:DietrichGebert/ponytail";
      flake = false;
    };
    humanizer = {
      url = "github:blader/humanizer";
      flake = false;
    };
    claude-plugins-official = {
      url = "github:anthropics/claude-plugins-official";
      flake = false;
    };
    trailofbits-skills = {
      url = "github:trailofbits/skills";
      flake = false;
    };
    rust-guidelines = {
      url = "github:microsoft/rust-guidelines";
      flake = false;
    };
    stop-ai-slop-jp = {
      url = "github:iKora128/stop-ai-slop-jp";
      flake = false;
    };
    ast-grep-skill = {
      url = "github:ast-grep/agent-skill";
      flake = false;
    };

    # --- AI エージェント用の CLI (上流が flake を持つ) ---
    # ax は nixpkgs に無い
    ax = {
      url = "github:yusukebe/ax";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nixpkgs の sem は semaphoreci/cli で別物なので上流を使う
    sem = {
      url = "github:ataraxy-labs/sem";
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
          # home-manager 本体の読み込みと homeModules.default の配線 (sharedModules) まで面倒を見てくれる
          inputs.hydenix.nixosModules.default
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
      go = {
        path = ./templates/go;
        description = "Go 開発環境 (gopls / goimports / golangci-lint / delve)";
      };
      python = {
        path = ./templates/python;
        description = "Python 開発環境 (uv / basedpyright / ruff)";
      };
      haskell = {
        path = ./templates/haskell;
        description = "Haskell 開発環境 (GHC / cabal / HLS / hlint / ormolu)";
      };
      clojure = {
        path = ./templates/clojure;
        description = "Clojure 開発環境 (clojure-lsp / clj-kondo / babashka)";
      };
    };
  };
}
