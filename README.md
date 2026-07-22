# dotnix

NixOS + Home Manager による個人環境の設定リポジトリです。
以前は [hydenix](https://github.com/richen604/hydenix) をベースにしていましたが、hydenix がメンテナンスモードに入ったため、素の NixOS + Home Manager + [stylix](https://github.com/nix-community/stylix) の構成に移行しました。

- デスクトップ: Hyprland (waybar / rofi / hyprlock / hypridle / dunst)
- テーマ: stylix による一括テーマ管理 (配色は HyDE の "Decay Green" を移植)
- エディタ: Neovim (AstroNvim ベース、設定は素の Lua、バイナリだけ Nix 管理)
- シェル: zsh (ログイン) → nushell (対話) + starship
- AI エージェント: [Herdr](https://herdr.dev/) で Claude Code などをターミナル内に並べて運用

## 設定の適用

このリポジトリを NixOS マシンの `~/dotnix` に置いて:

```bash
sudo nixos-rebuild switch --flake ~/dotnix
```

ホスト名 (`thinkpad-x13-gen6` など) と同名の設定が自動で選択されます。

## 更新 (flake inputs のアップデート)

```bash
cd ~/dotnix
nix flake update
sudo nixos-rebuild switch --flake .
```

## hydenix 構成からの移行 (初回のみ)

1. `nix flake update` を実行して flake.lock を新しい inputs で作り直す
2. `sudo nixos-rebuild switch --flake ~/dotnix` を実行する
3. 既存ファイルと衝突した場合は `.backup` を付けて退避される (エラーにはならない)
4. 動作確認後、HyDE が残した古い設定 (`~/.config/hyde`, `~/.config/waybar/*.backup` など) は削除してよい

## ディレクトリ構成

```
flake.nix              # エントリポイント (inputs とホスト一覧)
hosts/                 # ホスト (マシン) ごとの設定
  thinkpad-x13-gen6/
    default.nix        #   ホスト固有設定 (nixos-hardware, バッテリー閾値など)
    hardware-configuration.nix
modules/
  nixos/               # 全ホスト共通のシステム設定 (boot, audio, 指紋認証, stylix ...)
  home/                # ユーザ環境 (Home Manager) の設定
    desktop/           #   Hyprland / waybar / rofi / hyprlock などのデスクトップ一式
    programs/          #   個別アプリ (neovim, ghostty, nushell, zen-browser ...)
home/
  santamn.nix          # ユーザごとの Home Manager エントリポイント
nvim/                  # Neovim の Lua 設定 (~/.config/nvim にシンボリックリンクされる)
themes/                # stylix 用カラースキーム (decay-green.yaml)
templates/             # プロジェクト用 devShell の雛形 (nix flake init -t ~/dotnix#rust)
docs/                  # 構成の解説ドキュメント
```

## ドキュメント

| ドキュメント | 内容 |
|------|------|
| [docs/architecture.md](docs/architecture.md) | 構成の全体像・テーマの変え方・指紋認証の設計・主要キーバインド |
| [docs/new-machine.md](docs/new-machine.md) | 新しいマシンに同じ環境を作る手順 |
| [docs/neovim.md](docs/neovim.md) | Neovim の運用方針 (Mason なし・devShell・Rust・Herdr) |

## 主なパッケージ

### デスクトップアプリ

- Zen Browser
- Thunderbird
- Slack
- Zoom 
- Signal
- Discord (Vesktop)
- Spotify

### 開発ツール

- バージョン管理: git (+delta) / lazygit
- エディタ: Neovim (AstroNvim)
- ターミナル: Ghostty / Herdr
- シェル: zsh → nushell + starship + carapace + zoxide
- direnv + nix-direnv: プロジェクトごとに devShell を自動切り替え
- Docker / Podman

### ユーティリティ

- bat / bottom / eza / fd / fzf / ripgrep
- wine (Windows アプリ互換レイヤー)
- KDE Connect (スマートフォン連携)
