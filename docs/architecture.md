# 構成の全体像

## 設計方針

- **hydenix / HyDE への依存を持たない。** すべて nixpkgs・Home Manager 公式モジュール・stylix という、活発にメンテナンスされている汎用ツールだけで構成する
- **マシン固有の情報は `hosts/` に隔離する。** それ以外 (modules/, home/) はどのマシンでも同じものを使い、新しいマシンの追加を数ファイルで済ませる
- **見た目は stylix に一元化する。** 配色・フォント・カーソル・壁紙を1箇所で定義し、アプリごとの色設定を書かない

## 評価の流れ

```
flake.nix
 └─ mkHost "thinkpad-x13-gen6"
     ├─ hosts/thinkpad-x13-gen6/     ← ハードウェア構成・stateVersion (マシン固有)
     ├─ modules/nixos/               ← システム設定 (全マシン共通)
     │   ├─ theme.nix                ← stylix の基本設定 (スキーム・フォント・壁紙)
     │   └─ home-manager.nix         ← Home Manager を NixOS モジュールとして組み込み
     │       └─ home/santamn.nix    ← ユーザ設定のエントリポイント
     │           └─ modules/home/   ← デスクトップ・各アプリの設定
     └─ stylix (NixOS モジュール)    ← Home Manager 側にも自動で適用される
```

## hydenix からの置き換え対応表

| hydenix / HyDE の機能 | 置き換え先 |
|---|---|
| Hyprland 設定一式 | `wayland.windowManager.hyprland` ([modules/home/desktop/hyprland.nix](../modules/home/desktop/hyprland.nix)) |
| テーマシステム (wallbash) | stylix ([modules/nixos/theme.nix](../modules/nixos/theme.nix) + [themes/decay-green.yaml](../themes/decay-green.yaml)) |
| waybar 設定 | `programs.waybar` ([modules/home/desktop/waybar.nix](../modules/home/desktop/waybar.nix)) |
| rofi ランチャー | `programs.rofi` (テーマは stylix が生成) |
| hyprlock レイアウト (SF Pro) | `programs.hyprlock` の自前レイアウト ([modules/home/desktop/hyprlock.nix](../modules/home/desktop/hyprlock.nix)) |
| hypridle | `services.hypridle` |
| dunst (通知) | `services.dunst` (配色は stylix) |
| SDDM + astronaut テーマ | 同じものを直接定義 ([modules/nixos/desktop.nix](../modules/nixos/desktop.nix)) |
| スクリーンショットスクリプト | hyprshot + satty + hyprpicker |
| クリップボード履歴 | `services.cliphist` + rofi (Super+V) |
| Bibata カーソル / Tela アイコン | stylix の cursor / iconTheme 設定 |
| kitty | Ghostty (以前から独自設定) |

## テーマの変え方

配色は [themes/decay-green.yaml](../themes/decay-green.yaml) (HyDE の Decay Green を base16 に移植したもの) で決まっている。変更する場合は [modules/nixos/theme.nix](../modules/nixos/theme.nix) で:

- **別のスキームにする**: `base16Scheme` を [tinted-theming/schemes](https://github.com/tinted-theming/schemes) 収録の yaml や自作 yaml に差し替える
- **壁紙から自動生成する**: `base16Scheme` の行を削除すると `image` に指定した壁紙から配色が生成される (これが stylix の本来のモード)
- **壁紙を変える**: `image` を手元の画像パスに差し替える

waybar / hyprland / hyprlock は `config.lib.stylix.colors` 経由で同じスキームを参照しているので、yaml を替えるだけで全体の配色が追従する。

## 指紋認証の設計 ([modules/nixos/fingerprint.nix](../modules/nixos/fingerprint.nix))

指紋はあくまで補助手段で、**どの場面でも必ずパスワード入力にフォールバックできる**ようにしてある (指が荒れて指紋が読めなくなることがあるため)。

| 場面 | 挙動 |
|---|---|
| ログイン画面 (SDDM) | パスワードのみ。初回ログインをパスワードで行わないと gnome-keyring が解錠されないため意図的にこうしている |
| ロック画面 (hyprlock) | **指紋とパスワードを同時に受け付ける** (hyprlock 内蔵の指紋対応を使用) |
| sudo / polkit ダイアログ | まず指紋を試行し、読み取りに規定回数失敗するかタイムアウトすると自動でパスワード入力に切り替わる |

指紋の登録は `fprintd-enroll`、確認は `fprintd-verify`。

## 主要キーバインド (HyDE の既定配置をほぼ踏襲)

| キー | 動作 |
|---|---|
| Super+T / Super+B / Super+E / Super+C | ターミナル / ブラウザ / ファイラ / エディタ |
| Super+A | アプリランチャー (rofi) |
| Super+Tab | ウィンドウ切り替え (rofi) |
| Super+V | クリップボード履歴 |
| Super+, | 絵文字ピッカー |
| Super+Q / Alt+F4 | ウィンドウを閉じる |
| Super+W | フローティング切り替え |
| Super+F / Shift+F11 | フルスクリーン |
| Super+L | 画面ロック |
| Ctrl+Alt+Delete | ログアウトメニュー (wlogout) |
| Super+1〜0 | ワークスペース移動 (Shift 併用でウィンドウごと移動) |
| Super+P | 範囲スクリーンショット (Ctrl 併用で画面停止、Alt 併用でモニタ全体) |
| Super+Shift+P | カラーピッカー |
| Super+Z (ドラッグ) / Super+X (ドラッグ) | ウィンドウ移動 / リサイズ |
| 右Alt / 左Alt | 日本語入力オン / オフ (fcitx5 + Mozc) |

全キーバインドは [modules/home/desktop/hyprland.nix](../modules/home/desktop/hyprland.nix) を参照。
