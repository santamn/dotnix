# 構成の全体像

## 歴史

このリポジトリはもともと [richen604/hydenix](https://github.com/richen604/hydenix) のテンプレートから作られており、
個人設定 (`modules/hm/default.nix` 相当) だけで HyDE デスクトップ (Hyprland + waybar + rofi + wlogout + hyprlock ...) が成立していた。

2026-07-22、本家 hydenix がメンテナンスモードに入ったのを機に hydenix 依存を切り離し、
素の NixOS + Home Manager + stylix で HyDE の見た目を手作業で再現する構成に移行した。
しかしこの構成は stylix では代替できない部分 (waybar のモジュール群、rofi のレイアウト、wlogout、
Keybinds Hint 等のスクリプト、wallbash) をすべて手書きする必要があり、HyDE を独力で再実装し続ける
トレッドミルに陥った。

2026-07-29、hydenix の実質後継である [florianvazelle/hydenix](https://github.com/florianvazelle/hydenix) を
フォークした **[santamn/hydenix](https://github.com/santamn/hydenix)** に依存する形へ戻した。
ただし多ホスト構成 (`hosts/` / `mkHost`) やこの間に追加した資産 (nh, 指紋認証, Neovim, Ghostty 等) は
hydenix と両立するため維持している。**変わったのは「デスクトップ UI 層」だけ**で、
hydenix 以前からのテンプレート形式のファイル配置 (`configuration.nix` 直下など) には戻していない。

## リポジトリの関係

```
richen604/hydenix          本家。メンテナンスモード
        ↓ fork
florianvazelle/hydenix     実質的な後継
        ↓ fork
santamn/hydenix            ← dotnix が依存しているのはこれ (自分のフォーク)
        ↑ inputs.hydenix.url
dotnix                     ← このリポジトリ
```

自分のフォークを挟んでいるのは、上流が止まった場合に自分で前へ進められるようにするため。
普段は `git merge upstream/main` するだけで追加コストはほぼない。運用の詳細は
`~/Documents/hydenix` (santamn/hydenix のクローン) の `docs-ja/09-fork-workflow.md` を参照。

## hydenix が提供するもの・dotnix が持つもの

hydenix が公開する契約は flake の出力 3 つだけで、ファイル配置には関与しない。

```nix
inputs.hydenix.nixosModules.default   # システム側モジュール一式 (Hyprland, SDDM, audio, network ...)
inputs.hydenix.homeModules.default    # ユーザー側モジュール一式 (waybar, rofi, wlogout, hyprlock, テーマ ...)
inputs.hydenix.overlays.default       # pkgs.hyde などを追加
```

`nixosModules.default` は home-manager 本体の読み込みと `homeModules.default` の配線
(`home-manager.sharedModules`) まで面倒を見てくれるため、dotnix 側で
`inputs.home-manager.nixosModules.home-manager` を明示的に import する必要はない。

| 役割 | 担当 |
|---|---|
| Hyprland / waybar / rofi / wlogout / hyprlock / hypridle / テーマ (wallbash) | hydenix (`hydenix.hm.*`) |
| SDDM (astronaut テーマ) / Hyprland 本体の有効化 / XDG ポータル 等 | hydenix (`modules/system/{sddm,system,nix}.nix`。`hydenix.enable` に関わらず常時有効) |
| 多ホスト構成 (`hosts/` / `mkHost`) | dotnix |
| 指紋認証 (fprintd + PAM のパスワードフォールバック設計) | dotnix ([modules/nixos/fingerprint.nix](../modules/nixos/fingerprint.nix)) |
| nh (rebuild / GC ラッパー) | dotnix ([modules/nixos/nix.nix](../modules/nixos/nix.nix)) |
| audio / boot / network / bluetooth / users | dotnix (hydenix 側の同等モジュールは `hydenix.enable` 未設定=false のため無効のまま) |
| nushell (対話シェル) / starship / zsh (ログインシェル) / git / delta | dotnix ([modules/home/programs/](../modules/home/programs/)) |
| Neovim (AstroNvim, Mason 不使用) | dotnix ([nvim/](../nvim/)、[neovim.md](neovim.md) 参照) |
| Ghostty / zen-browser / fcitx5 / kdeconnect / herdr | dotnix ([modules/home/programs/](../modules/home/programs/)) |

### `hydenix.enable` をあえて有効化していない理由

hydenix システム側の `nix.nix` / `sddm.nix` / `system.nix` は `hydenix.enable` に関わらず常時有効
(Hyprland 本体・SDDM astronaut テーマ・XDG ポータル等、HyDE の見た目に必須な部分はここに含まれる)。
一方 `audio.nix` / `network.nix` / `hardware.nix` / `boot.nix` / `gaming.nix` は
`hydenix.enable = true` にしないと有効化されない設計になっている。

dotnix は audio / boot / network を移行前から独自モジュールとして持っており (`modules/nixos/`)、
`hydenix.gaming` (Steam / Lutris 等) は元々使っていない。そのため `hydenix.enable` は
既定値の `false` のままにし、hydenix 側の audio/network/hardware/gaming モジュールは有効化していない。
必要になれば `hydenix.enable = true;` として `hydenix.gaming.enable = false;` のように
個別に絞り込むこともできる。

## 評価の流れ

```
flake.nix
 └─ mkHost "thinkpad-x13-gen6"
     ├─ hosts/thinkpad-x13-gen6/          ← ハードウェア構成・stateVersion (マシン固有)
     ├─ modules/nixos/                    ← dotnix 独自のシステム設定 (audio, network, 指紋認証, nh ...)
     └─ inputs.hydenix.nixosModules.default
         ├─ home-manager (NixOS モジュール)
         │   └─ home/santamn.nix          ← ユーザ設定のエントリポイント + hydenix.hm オプション
         │       └─ modules/home/         ← dotnix 独自のユーザ設定 (nushell, ghostty, neovim ...)
         └─ hydenix の system/*, hm/* モジュール群 (Hyprland, SDDM, waybar, rofi, wlogout ...)
```

## hydenix.hm の設定 ([home/santamn.nix](../home/santamn.nix))

| オプション | 値 | 理由 |
|---|---|---|
| `theme.active` | `"Decay Green"` | HyDE 時代からの既定テーマ |
| `firefox.enable` | `false` | zen-browser を使う |
| `terminals.kitty.enable` | `false` | Ghostty を使う |
| `social.discord.enable` | `false` | vesktop (Wayland 画面共有対応) を使う |
| `editors.default` | `"nvim"` | 既定エディタ、mimeApps もこれに追従 |
| `shell.enable` | `false` | zsh/nushell/starship は `modules/home/programs/` 側で管理しており衝突するため丸ごと無効化 |

`hydenix.hm.git` (本家 issue #169 のバグにより削除されたオプション) は
`modules/home/programs/git.nix` の素の `programs.git.settings.user` に統合済み。
`hydenix.hm.hyprland.pyprland` はフォーク側で削除されている (scratchpad 等が使えない、既知の制約)。

## mutable ファイルの上書き (waybar clock / hyprlock フォント)

HyDE はテーマ切り替え時にスクリプトが設定ファイルを書き換える前提のため、`mutable = true` を付けた
`home.file` は symlink ではなくコピーとして配置される (詳細は hydenix リポジトリの
`docs-ja/04-mutable-files.md`)。**この仕組みの上で個人カスタマイズを行う場合、hydenix 側が
同じパスに `mutable = true` を設定していると、上書きする側にも `mutable = true` を付けないと
activation の `cp` で結果が戻されてしまう。**

[home/santamn.nix](../home/santamn.nix) では waybar の時計フォーマットと hyprlock のフォントを
この方法で上書きしている。ただし waybar 側は `.config/waybar/modules` ディレクトリ全体が
`recursive` コピーで配置されるため、個別ファイルの上書きが確実に効く保証はない
(hydenix 本体の `modules/hm/waybar.nix` コメント参照)。**実機の rebuild で反映されない場合は、
`includes.json` の参照先を差し替える方法に切り替えること。**

## 指紋認証の設計 ([modules/nixos/fingerprint.nix](../modules/nixos/fingerprint.nix))

指紋はあくまで補助手段で、どの場面でも必ずパスワード入力にフォールバックできるようにしてある。

| 場面 | 挙動 |
|---|---|
| ログイン画面 (SDDM) | パスワードのみ。初回ログインをパスワードで行わないと gnome-keyring が解錠されないため意図的にこうしている |
| ロック画面 (hyprlock) | **指紋とパスワードを同時に受け付ける** (hyprlock 内蔵の指紋対応を使用。PAM 側では `fprintAuth` を設定しない) |
| sudo / polkit ダイアログ | まず指紋を試行し、読み取りに規定回数失敗するかタイムアウトすると自動でパスワード入力に切り替わる |

指紋の登録は `fprintd-enroll`、確認は `fprintd-verify`。

## 既知の制約・落とし穴

- **HyDE のバージョン差**: フォークの HyDE は本家より新しい (2026-03 時点)。記憶にある見た目と
  完全一致しない場合は「フォークが壊れている」より先に「HyDE 側の変更」を疑うこと
- **`mutable` ファイルは設定から消しても残る**: `home.file` から削除しても実体はホームに残り続ける。
  テーマ関連がおかしくなったら `rm -rf ~/.config/hyde ~/.local/share/hyde ~/.cache/hyde` の後に
  再度 `nixos-rebuild switch` でリセットできる
- **`stateVersion` の二重定義**: hydenix が `system.stateVersion` / `home.stateVersion` を
  `mkDefault` なしで `"25.05"` に設定しており、dotnix 側 (`hosts/*/default.nix`, `home/santamn.nix`)
  も同じ値を設定している。型が `mergeEqualOption` のため両方が `"25.05"` である限りエラーにならないが、
  **片方だけ値を変えると定義衝突でビルドが落ちる**。変更する場合は両方揃えること
- **`mutableGeneration` 依存名の不一致**: hydenix 本体の `theme.nix` / `hyde.nix` /
  `hyprland/default.nix` が存在しない activation エントリ名 `mutableGeneration` を参照しており
  (正しくは `mutableFileGeneration`)、順序制約が効いていない。上流 (santamn/hydenix) 側の
  修正候補として認識している既知の問題で、dotnix 側では対処不要
