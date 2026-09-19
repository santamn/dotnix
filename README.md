# dotnix

NixOS + Home Manager によるOS環境設定。ベースのデスクトップ環境 (Hyprland + HyDE) としては [hydenix の自分用のフォーク](https://github.com/santamn/hydenix)を使い、個人用設定はこの dotnix で管理する構成。

- デスクトップ: hydenix (Hyprland / waybar / rofi / wlogout / hyprlock / hypridle)
- エディタ: Neovim (AstroNvim)
- シェル: nushell (ログインシェルの zsh から自動起動)

## 設定の適用

このリポジトリを NixOS マシンの `~/dotnix` に置いて次を実行:

```bash
nh os switch
```

flake のパスは `programs.nh.flake` (= `dotfiles.path`) 経由で `NH_FLAKE` に入っているので引数は要らない。ホスト名 (`thinkpad-x13-gen6` など) と同名の設定が自動で選択される。

> [!NOTE]
> `sudo nh os switch` としてはいけない。
> `sudo` なしでコマンドを実行しておけば、評価とビルドは自分のユーザー権限で、activation とシステムプロファイルの更新は権限昇格して実行される (昇格コマンドは doas → sudo → run0 → pkexec の順に PATH から自動検出される) 。

## 更新 (flake inputs のアップデート)

```bash
nh os switch --update
```

`--update` (`-u`) は flake inputs を全部更新してから切り替える。特定の input だけなら `--update-input some_input` (`-U`) 。

## テンプレートの利用

```bash
nix flake init -t ~/dotnix#template
```

## ディレクトリ構成

```text
.
├── flake.nix                 # エントリポイント 
├── hosts/                    # ホスト (マシン) ごとの設定
│   └── thinkpad-x13-gen6/
│       ├── default.nix       # ホスト固有設定 (nixos-hardware, バッテリー閾値など)
│       └── hardware-configuration.nix
├── modules/
│   ├── nixos/                # 全ホスト共通のシステム設定 (boot, audio, network, 指紋認証, nh ...)
│   └── home/                 # ユーザー環境 (Home Manager) の設定
│       └── programs/         # 個別アプリの設定 (neovim, ghostty, nushell, zen-browser ...)
├── home/
│   └── santamn.nix           # ユーザーごとの Home Manager エントリポイント + hydenix.hm オプション
├── nvim/                     # Neovim の Lua 設定 (~/.config/nvim にハードリンクされる)
├── templates/                # プロジェクト用 devShell の雛形
└── docs/                     # 構成の解説ドキュメント
```
