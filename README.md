# dotnix

NixOS + Home Manager によるOS環境設定。デスクトップ (Hyprland + HyDE) は自分のフォーク
[santamn/hydenix](https://github.com/santamn/hydenix) ([florianvazelle/hydenix](https://github.com/florianvazelle/hydenix) 経由の [richen604/hydenix](https://github.com/richen604/hydenix) フォーク) に依存し、
多ホスト構成・指紋認証・Neovim・シェルなど個人の資産は dotnix 側で管理する構成 (詳細は [architecture.md](docs/architecture.md))。

- デスクトップ: hydenix (Hyprland / waybar / rofi / wlogout / hyprlock / hypridle、テーマは "Decay Green")
- エディタ: Neovim (AstroNvim)
- シェル: nushell (ログインシェルの zsh から自動起動)

## 設定の適用

このリポジトリを NixOS マシンの `~/dotnix` に置いて次を実行:

```bash
sudo nixos-rebuild switch --flake ~/dotnix
```

ホスト名 (`thinkpad-x13-gen6` など) と同名の設定が自動で選択される。

## 更新 (flake inputs のアップデート)

```bash
cd ~/dotnix
nix flake update
sudo nixos-rebuild switch --flake .
```

## hydenix ベース構成への移行 (初回のみ)

素の NixOS + Home Manager + stylix で HyDE を手作業再現していた期間の残骸が
ホームディレクトリに残っている場合、初回 rebuild 前に消しておくと安全:

```bash
rm -rf ~/.config/hyde ~/.local/share/hyde ~/.cache/hyde
rm -rf ~/.config/waybar ~/.config/rofi ~/.config/wlogout ~/.config/hypr
```

1. `nix flake update` を実行して flake.lock を新しい inputs (hydenix 経由) で作り直す
2. `sudo nixos-rebuild switch --flake ~/dotnix` を実行する
3. うまく当たらないテーマ・レイアウトがあれば `rm -rf ~/.config/hyde ~/.local/share/hyde ~/.cache/hyde` の後に再度 switch する ([architecture.md](docs/architecture.md) の「既知の制約・落とし穴」参照)

## ディレクトリ構成

```
.
├── flake.nix                 # エントリポイント (inputs とホスト一覧、hydenix を依存に追加)
├── hosts/                    # ホスト (マシン) ごとの設定
│   └── thinkpad-x13-gen6/
│       ├── default.nix       # ホスト固有設定 (nixos-hardware, バッテリー閾値など)
│       └── hardware-configuration.nix
├── modules/
│   ├── nixos/                # 全ホスト共通のシステム設定 (boot, audio, network, 指紋認証, nh ...)
│   └── home/                 # ユーザ環境 (Home Manager) の設定 (Hyprland/waybar/rofi 等は hydenix が提供)
│       └── programs/         # 個別アプリ (neovim, ghostty, nushell, zen-browser ...)
├── home/
│   └── santamn.nix           # ユーザごとの Home Manager エントリポイント + hydenix.hm オプション
├── nvim/                     # Neovim の Lua 設定 (~/.config/nvim にシンボリックリンクされる)
├── templates/                # プロジェクト用 devShell の雛形 (nix flake init -t ~/dotnix#rust)
└── docs/                     # 構成の解説ドキュメント
```

## ドキュメント

- [architecture.md](docs/architecture.md): 構成の全体像・hydenix との役割分担・指紋認証の設計・既知の制約
- [new-machine.md](docs/new-machine.md): 新しいマシンに同じ環境を作る手順
- [neovim.md](docs/neovim.md): Neovim の運用方針 (Mason なし・devShell・Rust・Herdr)
