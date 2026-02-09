<img align="right" width="75px" alt="NixOS" src="https://github.com/HyDE-Project/HyDE/blob/master/Source/assets/nixos.png?raw=true"/>

# NixOS configuration powered by hydenix

[hydenix](https://github.com/richen604/hydenix) のテンプレートをベースにした NixOS の設定です。

## apply configuration

```bash
sudo nixos-rebuild switch --flake .#thinkpad-x13-gen6
```

## packages

### desktop applications

- Discord (Vesktop)
- Signal
- Slack
- Spotify
- Zoom
- Zen Browser

### development tools

- バージョン管理: git/lazygit
- エディタ: Neovim (AstroNvim)
- shell 関係
  - ターミナルエミュレータ: Ghostty 
  - ログインシェル: zsh
  - 対話型シェル: nushell
  - プロンプト: starship
- direnv: 開発環境ごとに devShell を自動切り替え
  - プロジェクトごとに `.envrc` と `flake.nix` を配置すれば `cd` したら自動で開発環境を切り替える

### utilities

- wine: Windows アプリケーションを実行するための互換レイヤー

## file structure

### core configuration files

| file | description |
|------|-------------|
| `flake.nix` | メインの flake の設定・エントリポイント |
| `configuration.nix` | NixOS のシステム設定 |
| `hardware-configuration.nix` | ハードウェア設定(自動生成) |

### write your own modules

> **note:** Use these directories to override or extend hydenix modules with your custom configurations.

| directory | type | purpose |
|-----------|------|---------|
| `modules/hm/` | home manager | home-manager モジュールの設定 ( `hydenix.hm` のオプション設定も) |
| `modules/system/` | nixos system | システムレベルのカスタム設定 ( `hydenix` のオプション設定も) |

### directory tree

```
.
├── README.md
├── configuration.nix
├── docs
│   ├── assets
│   │   └── option-search.png
│   ├── faq.md
│   ├── installation.md
│   ├── options.md
│   ├── troubleshooting.md
│   └── upgrading.md
├── flake.lock
├── flake.nix
├── hardware-configuration.nix
└── modules
    ├── hm
    │   ├── default.nix
    │   └── programs
    │       ├── *.nix files
    └── system
        └── default.nix
```

## notes

### wild linker

Rust プロジェクトで高速な wild リンカーを使用する開発環境の設定例[^1]：

```flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wild = {
      url = "github:davidlattimore/wild";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      rust-overlay,
      wild,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            rust-overlay.overlays.default
            (import wild)
          ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.rust-bin.stable.latest.default
            pkgs.wild
          ];

          # wildリンカーをデフォルトのリンカーとして使用
          RUSTFLAGS = "-C linker=wild";
        };
      }
    );
}
```

[^1]: https://zenn.dev/asa1984/books/nix-hands-on/viewer/ch04-02-rust-project

このように設定することで、プロジェクトの devShell 環境で wild リンカーが自動的に使用される。

## license 

MIT License
