# dotnix

## Project Overview

NixOS + Home Manager による個人環境の設定リポジトリ。かつては hydenix ベースだったが、現在は素の NixOS + Home Manager + stylix で構成されている (経緯と全体像は docs/architecture.md を参照)。

### Directory Structure

- `flake.nix` — エントリポイント。inputs とホスト一覧 (`mkHost`)
- `hosts/<name>/` — マシン固有設定 (hardware-configuration.nix, stateVersion など)。共通設定を書いてはいけない
- `modules/nixos/` — 全ホスト共通のシステム設定 (1ファイル1関心事)
- `modules/home/` — Home Manager 設定。`desktop/` に Hyprland 一式、`programs/` に個別アプリ
- `home/<user>.nix` — ユーザごとの Home Manager エントリポイント
- `nvim/` — Neovim の Lua 設定。`~/.config/nvim` にシンボリックリンクされ、rebuild なしで反映される (方針は docs/neovim.md)
- `themes/` — stylix 用 base16 カラースキーム
- `templates/` — `nix flake init -t` で使う devShell の雛形

### Conventions

- 配色は stylix に一元化する。アプリ個別の色指定を書かず、`config.lib.stylix.colors` を参照する
- マシン固有の値 (バッテリー閾値など) は `hosts/` へ、それ以外は `modules/` へ置く
- この Mac には Nix がインストールされていないため、`nix flake check` 等の検証は NixOS マシン側で行う

## Code Quality Practices

- Keep complexity under control through appropriate abstraction, concretization, and use of libraries
  - Remove code and libraries that are no longer needed
- When using a library, consult its documentation and use it correctly
  - Refer to the documentation for how to specify library versions
  - Unless the documentation instructs otherwise, use the latest stable version
- Refactor code following established best practices such as those in *The Art of Readable Code* to improve readability
- Always attach comments **in Japanese** explaining the meaning of functions, structs, and any other semantically cohesive pieces of code
