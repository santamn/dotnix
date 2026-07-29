# dotnix を santamn/hydenix ベースに戻す

> このファイルは AI エージェントへの作業指示書です。作業完了後は削除して構いません。
> 作業ディレクトリは `/Users/miyake/Documents/dotnix`（このファイルのある場所）です。

---

## 0. 前提と制約

- **この Mac は対象の NixOS マシンではありません。** `nix` コマンドも入っていません。
  ビルド確認・動作確認はできないので、**実機での検証が必要な段階になったら作業を止めて報告してください。**
- 最終的な動作確認はユーザーが実機で行います。
- 対象マシンは ThinkPad X13 Gen6（`hosts/thinkpad-x13-gen6/`）。将来他のマシンも追加予定。

---

## 1. ゴール

1. **hydenix 時代の使用感（HyDE の見た目・操作感）を取り戻す**
   - 依存先を停止した本家 `richen604/hydenix` ではなく、自分のフォーク **`github:santamn/hydenix`** にする
2. **移行時に新しく入れた資産は維持する**（nh、指紋認証、多ホスト構成、Neovim、Ghostty など。詳細は §4）
3. `mutableGeneration` 不一致の修正を自分のフォークに入れ、問題なければ上流にも PR を送る（§5）

---

## 2. なぜこの作業が必要なのか（背景）

このリポジトリは元々 hydenix のテンプレートから作られており、
`modules/hm/default.nix` 約 250 行の個人設定だけで HyDE デスクトップが成立していました。

2026-07-22 のコミット `39be51d`「hydenixを切り離し」で hydenix 依存を外し、
素の NixOS + Home Manager + stylix に移行しました。**ビルドは通りますが、使用感が全く別物になりました。**

原因ははっきりしています。**stylix が代替できるのは「配色」だけ**で、HyDE の正体はそれ以外だからです。

| HyDE の構成要素 | stylix で代替できたか |
|---|---|
| 配色の統一 | ✅ できた |
| waybar のレイアウトとモジュール群（80 個超の jsonc） | ❌ 手書きになった |
| rofi の rasi テーマ（launcher / 壁紙選択 / テーマ選択 UI） | ❌ 手書きになった |
| wlogout / hyprlock のレイアウト | ❌ 手書きになった |
| Keybinds Hint、スクショ、音量 OSD 等のスクリプト群 | ❌ 手書きになった |
| wallbash（壁紙 → 全アプリ配色の生成パイプライン） | △ 別方式・別の見た目 |

現在 `modules/home/desktop/` には **1,787 行**の手書きデスクトップ設定があります。
さらに直近のコミット `91bba87`「hydenixとの差異を解消」で **672 行**（rofi +340 / wlogout +146 / hyprland +191）を追加しており、
**HyDE を手作業で再実装するトレッドミルに入っている状態**です。これを止めるのが今回の目的です。

---

## 3. リポジトリの関係

```
richen604/hydenix          本家。2026-01-23 を最後に停止（メンテナンスモード）
        ↓ fork
florianvazelle/hydenix     実質的な後継。本家より 109 コミット先行・0 コミット遅れ
        ↓ fork
santamn/hydenix            ← 今回使うのはこれ（あなたのフォーク）
        ↑ inputs.hydenix.url
dotnix                     ← このリポジトリ
```

**なぜ自分のフォークを挟むのか**: florianvazelle 氏は 1 人で保守しており（star 2）、
止まった場合に即座に自分で前へ進めるようにするためです。普段は `git merge upstream/main` するだけで、
追加コストはほぼありません。

**フォークの鮮度（本家との比較）**

| | richen604（本家） | florianvazelle |
|---|---|---|
| 最終 push | 2026-01-23 | 2026-07-27 |
| nixpkgs | 2025-04-13 | 2026-06-06 |
| home-manager | 2025-12-30 | 2026-07-18 |
| Hyprland | 古い nixpkgs 由来 | v0.55.4 を flake input で pin + cachix |
| HyDE | 2025-10-29 で固定 | v26.03.30 |

**注意**: HyDE 自体が 2025-10 → 2026-03 に進んでいるため、
**記憶にある見た目と完全一致はしません。** 差分が出た場合は「フォークが悪い」ではなく
「HyDE が変わった」可能性を先に疑ってください。

---

## 4. 作業 A: dotnix を santamn/hydenix ベースに戻す

### A-1. 基本方針

**リポジトリ構造は今のまま維持します。** 多ホスト構成（`mkHost` / `hosts/`）は今回の移行の最大の成果であり、
hydenix と完全に両立します。**変えるのは「デスクトップ UI 層」だけ**です。

> **重要: hydenix のテンプレートは使いません。**
> テンプレート（`nix flake new -t github:santamn/hydenix`）に戻す作業ではありません。
> 理由は次の A-1b を読んでください。**間違ってテンプレートを展開しないこと。**

### A-1b. なぜテンプレートを使わないのか

hydenix が提供している「契約」は flake の出力 3 つだけです。ファイル配置には関与しません。

```nix
inputs.hydenix.nixosModules.default   # システム側モジュール一式
inputs.hydenix.homeModules.default    # ユーザー側モジュール一式（フォークでは sharedModules 経由で自動配線）
inputs.hydenix.overlays.default       # pkgs.hyde などを追加
```

テンプレートはこれを使い始めるための足場であって、API ではありません。
実際、移行前の dotnix（ルートに `configuration.nix`、`modules/{hm,system}/default.nix`）は
テンプレートそのものでした。現在の構成はそれを多ホスト対応に展開したものです。

| hydenix テンプレート | 現在の dotnix での対応物 |
|---|---|
| `flake.nix` | `flake.nix`（`mkHost` ヘルパー付き） |
| `configuration.nix` | `hosts/<name>/default.nix` + `modules/nixos/` |
| `hardware-configuration.nix` | `hosts/<name>/hardware-configuration.nix` |
| `modules/system/default.nix` | `modules/nixos/default.nix` |
| `modules/hm/default.nix` | `home/santamn.nix` + `modules/home/default.nix` |

テンプレート構成に戻すと、
(1) ユーザーが移行時に明示的に要求した「標準的な NixOS プロジェクト構成」を捨てることになり、
(2) テンプレートは単一ホスト前提なので多ホスト対応と両立しません。

**フォークでの朗報**: `networking.hostName` / `time.timeZone` / `i18n.defaultLocale` が
`lib.mkIf cfg.enable (lib.mkDefault ...)` になりました（本家は `mkDefault` なし）。
そのため `mkHost` の `{networking.hostName = hostName;}` が素直に優先され、多ホスト構成と綺麗に噛み合います。
また `hydenix.hostname` / `timezone` / `locale` に既定値が付き、本家にあった必須アサーションも無くなりました。

### A-1c. 実際に書き換えるファイル（これだけ）

| ファイル | 変更内容 |
|---|---|
| `flake.nix` | hydenix input 追加、`nixpkgs.follows`、`mkHost` に `inputs.hydenix.nixosModules.default` 追加、stylix 削除 |
| `modules/nixos/default.nix` | imports から `./desktop.nix` `./fonts.nix` `./theme.nix` を削除 |
| `modules/home/default.nix` | imports から `./desktop` `./theme.nix` を削除（`./xdg.nix` は §A-6 参照） |
| `home/santamn.nix` | `inputs.nix-index-database.homeModules.nix-index` の import を削除（hydenix 側が入れるため重複）、`hydenix.hm` 設定を追加 |

`modules/nixos/home-manager.nix` は**変更不要**です（`useGlobalPkgs` / `useUserPackages` /
`extraSpecialArgs` / `users.santamn` はそのままでよい）。

### A-2. 削除するもの（hydenix が提供するため不要になる）

```
modules/home/desktop/          一式（hyprland/waybar/rofi/wlogout/hyprlock/hypridle/mako/services/default）
modules/nixos/desktop.nix      SDDM 等 → hydenix.sddm / hydenix.system が担当
modules/nixos/fonts.nix        → hydenix 側が担当
modules/nixos/theme.nix        stylix 基本設定
modules/home/theme.nix         stylix ターゲット調整
themes/                        base16 yaml（decay-green.yaml）
```

**stylix は完全に外してください。** hydenix の wallbash と役割が真正面から衝突します
（両方が同じ設定ファイルを奪い合う）。flake の `stylix` input と
`inputs.stylix.nixosModules.stylix` の読み込みも削除します。

`modules/home/dotfiles.nix` は中身を確認し、desktop 層に属するものだけ削ってください。

### A-3. 維持するもの（hydenix が持たない資産）

```
hosts/                            多ホスト構成（最重要・そのまま維持）
flake.nix の mkHost ヘルパー       同上
modules/nixos/fingerprint.nix     指紋 + パスワードフォールバックの設計
modules/nixos/nix.nix             nh によるガベージコレクト
modules/nixos/power.nix
modules/nixos/virtualisation.nix
modules/nixos/nix-ld.nix
modules/nixos/overlays.nix
modules/nixos/kdeconnect.nix / locale.nix / network.nix / users.nix
modules/home/programs/            全部（nushell/ghostty/zen-browser/fcitx5/herdr/neovim/direnv/ssh/starship/git/kdeconnect）
modules/home/packages.nix
modules/home/xdg.nix              ※ hydenix.hm.xdg と重複するので §A-6 参照
nvim/                             AstroNvim の Lua 設定（mkOutOfStoreSymlink 方式）
templates/rust
docs/                             new-machine.md / neovim.md は維持。architecture.md は書き直しが必要
```

### A-4. flake.nix の書き換え

フォークのテンプレートでは `nixosModules.default` が home-manager と `homeModules.default` を
**自動で配線する**ようになりました（`home-manager.sharedModules` 経由）。本家より記述が減ります。

```nix
inputs = {
  # hydenix が pin している nixpkgs に揃える。
  # 独自の nixos-unstable を使うと hydenix 側とパッケージが二重になり不具合が出る
  nixpkgs.follows = "hydenix/nixpkgs";
  hydenix.url = "github:santamn/hydenix";
  nixos-hardware.follows = "hydenix/nixos-hardware";

  # 以下は維持
  zen-browser = { ... };
  nix-firefox-addons = { ... };
  # nix-index-database は hydenix 側が持っているので重複に注意（§A-6）
  # stylix は削除
};
```

`mkHost` の modules には `inputs.hydenix.nixosModules.default` を追加します。
`inputs.home-manager.nixosModules.home-manager` は hydenix 側が読み込むため、
`modules/nixos/home-manager.nix` の内容と衝突しないか確認してください。

### A-5. hydenix.hm オプションの復元

移行前の設定が `git show 39be51d^:modules/hm/default.nix` で取り出せます。**これをベースにしてください。**
要点だけ再掲します（`hydenix.hm` 配下）:

```nix
hydenix.hm = {
  enable = true;

  theme = {
    enable = true;
    active = "Decay Green";
    themes = [ "AncientAliens" "BlueSky" "Catppuccin Mocha" "Catppuccin Latte"
               "Catppuccin-Macchiato" "Code Garden" "Decay Green" "Monokai"
               "Rain Dark" "Solarized Dark" "Tokyo Night" ];
  };

  hyprland = {
    extraConfig = ''
      input {
        kb_options = ctrl:swapcaps
        touchpad {
          natural_scroll = true
          scroll_factor = 0.5
          clickfinger_behavior = true
          tap-to-click = true
          tap_button_map = lmr
        }
      }
      misc { middle_click_paste = false }
    '';
    hypridle = {
      enable = true;
      overrideConfig = ''...'';  # 15分ロック / 20分画面オフ / 30分サスペンド。旧設定から流用
    };
  };

  editors = { enable = true; neovim = true; vim = false;
              vscode = { enable = false; wallbash = false; }; default = "nvim"; };
  firefox.enable = false;      # zen-browser を使う
  terminals = { enable = true; kitty.enable = false; };  # ghostty を使う
  social = { enable = true; discord.enable = false; vesktop.enable = true; };
};
```

**フォークでの変更点（要対応）:**

- **`hydenix.hm.git` は削除されました。** 旧設定の
  `git = { enable = true; name = "santamn"; email = "cle.neige@gmail.com"; };` は
  素の `programs.git` に書き換えてください（`modules/home/programs/git.nix` が既にあるのでそこへ統合）。
  これは本家 issue #169 の型バグを、モジュールごと削除して解決した結果です。
- **`hydenix.hm.hyprland.pyprland` は削除されました**（後述の未解決問題を参照）。
- `hydenix.hm.hyprland.hypridle` / `keybindings` / `windowrules` / `monitors` / `nvidia` の
  `enable` / `extraConfig` / `overrideConfig` は**そのまま使えます**
  （`mkHyprConfig.nix` が動的生成しています）。
- 新設: `hydenix.hm.hyprland.systemd.*`、`hydenix.hm.hyprland.hyprsunset.*`。

### A-6. 衝突しやすい箇所（必ず確認）

| 箇所 | 内容 |
|---|---|
| stylix vs wallbash | 両立不可。stylix を完全に外す |
| `nix-index-database` | hydenix 側が `sharedModules` で読み込む。dotnix 側の重複読み込みを外す |
| `modules/home/xdg.nix` | `hydenix.hm.xdg` と重複。片方に寄せる |
| ghostty vs kitty | `terminals.kitty.enable = false` で共存（旧設定と同じ） |
| mako vs dunst | hydenix は dunst。mako を捨てるか `hydenix.hm.notifications.enable = false` |
| zen-browser vs firefox | `firefox.enable = false` で共存（旧設定と同じ） |
| nushell / zsh | `hydenix.hm.shell` の設定と衝突しないか確認 |
| fcitx5 | 過去に重複で問題が出ている（コミット `c3fc5f2`）。再発に注意 |
| **`stateVersion` の二重定義** | 下記参照 |

**`stateVersion` について（要注意）**

hydenix は `system.stateVersion = "25.05"`（`modules/system/default.nix`）と
`home.stateVersion = "25.05"`（`modules/hm/default.nix`）を、**どちらも `lib.mkDefault` なしで**設定します。
一方 dotnix も `hosts/thinkpad-x13-gen6/default.nix` と `home/santamn.nix` で同じ値を設定しています。

型の merge が `mergeEqualOption`（値が全て等しければ通る）なので、
**両方が `"25.05"` である限りエラーになりません。** ただし片方でも変えた瞬間に定義衝突でビルドが落ちます。
実機の初期値は `"25.05"` なので現状は問題ありませんが、いじらないでください。

### A-7. かつて動かなかった waybar clock の件

旧設定にあった以下は**動きませんでした**:

```nix
home.file.".config/waybar/modules/clock.jsonc" = { text = ...; force = true; };
```

原因は、hydenix 側が同じパスを `mutable = true` で配置しており、
`mutableFileGeneration`（activation script の `cp`）が**後から上書きしていた**ためです。

対処は次のいずれか:
1. `mutable = true;` を併記する（`force = true` とセットが必須）
2. `.config/waybar/includes/includes.json` の参照先を独自パスに差し替える

同じ理由で `home.file.".config/hypr/hyprlock/theme.conf"` も動きませんでした。同様に対処してください。

### A-8. 進め方と検証

1. **作業ブランチを切る**（例: `feat/back-to-hydenix`）。main は壊さない
2. 削除より先に flake.nix と hydenix.hm 設定を書き、その後に不要ファイルを消す
3. `docs/architecture.md` を新構成に合わせて全面的に書き直す
4. `README.md` も更新する
5. **ビルド確認はこの Mac ではできません。** 変更が一通り済んだら
   「実機で `nixos-rebuild build --flake .#thinkpad-x13-gen6` を実行してほしい」と報告して止まってください
6. ロールバック手段（前の generation）をユーザーに案内してから switch してもらうこと

---

## 5. 作業 B: `mutableGeneration` 修正と PR

### B-1. 何を直すのか

`modules/hm/mutable.nix` が定義している activation エントリの名前は **`mutableFileGeneration`** ですが、
以下の 3 ファイルが存在しない **`mutableGeneration`** を待っています。

| ファイル | 行 |
|---|---|
| `modules/hm/theme.nix` | 83 |
| `modules/hm/hyde.nix` | 40 |
| `modules/hm/hyprland/default.nix` | 39 |

home-manager は**存在しない依存名を黙って無視する**ため、エラーにはなりませんが
**順序制約が一切効いていません**。実行位置は toposort の実装依存で決まっており、
home-manager の更新で順番が変わり得る状態です。

修正は 3 箇所の文字列を `"mutableFileGeneration"` に変えるだけです。

```diff
- home.activation.setTheme = lib.hm.dag.entryAfter ["mutableGeneration"] ''
+ home.activation.setTheme = lib.hm.dag.entryAfter ["mutableFileGeneration"] ''
```

`mutable.nix` の `config` は無条件（enable フラグで囲われていない）なので、
このエントリは常に存在します。依存先が消えるリスクはありません。

### B-2. 手順

```bash
# 1. 自分のフォークを clone（dotnix とは別の場所に）
cd ~/Documents
git clone https://github.com/santamn/hydenix.git hydenix-fork
cd hydenix-fork

# 2. 上流を remote に登録（今後の追従用）
git remote add upstream https://github.com/florianvazelle/hydenix.git
git fetch upstream
git merge upstream/main    # 最新に揃える

# 3. ブランチを切る
git switch -c fix/mutable-generation-dag-name

# 4. 3 ファイルを修正（上記 B-1）

# 5. フォーマットを合わせる（このリポジトリは treefmt + alejandra を CI で強制している）
nix fmt        # ← 実機または nix のある環境で

# 6. コミット
#    このリポジトリは commitlint を CI で強制している。Conventional Commits 必須
git commit -am "fix: correct activation dependency name to mutableFileGeneration"

# 7. 自分のフォークへ push
git push -u origin fix/mutable-generation-dag-name
```

### B-3. 自分の環境で先に検証する

PR を送る前に、実機で動くことを確かめます。dotnix の flake.nix でブランチを指定します。

```nix
hydenix.url = "github:santamn/hydenix/fix/mutable-generation-dag-name";
```

`nix flake update hydenix` → `nixos-rebuild switch` で確認。
**特に初回相当の挙動（テーマが正しく当たるか）を見てください。**
問題なければ自分のフォークの `main` にマージし、flake.nix の URL を `github:santamn/hydenix` に戻します。

### B-4. 上流への PR

```bash
# GitHub の Web UI で
#   base: florianvazelle/hydenix  main
#   compare: santamn/hydenix  fix/mutable-generation-dag-name
```

PR 本文には次を含めてください（英語で）:

- **What**: 3 つの activation エントリが存在しない `mutableGeneration` を参照している
- **Why it matters**: home-manager は不明な依存名を silently ignore するため、
  意図された「mutable ファイルのコピー後に実行」という順序が保証されていない
- **Evidence**: `modules/hm/mutable.nix` が定義しているのは `mutableFileGeneration`
- **Risk**: なし（文字列 3 箇所。`mutable.nix` の config は無条件なのでエントリは常に存在する）
- **Testing**: 自分の NixOS 機で rebuild して確認済み、と書く（実際に確認してから）

### B-5. 補足（PR には含めないこと）

同じ 3 つのスクリプトは `$DRY_RUN_CMD` を使っておらず、`dry-activate` でも実際に
ファイルを作ってしまう問題もあります。**これは別 PR にしてください。**
最初の PR は小さく保つのが通りやすさの鉄則です。

---

## 6. 既知の未解決問題（フォークにも残っているもの）

本家の `TODO.md` と issue を、florianvazelle フォークの現状と突き合わせた結果です。
**このリストは「踏んでも仕様」と割り切るか、自分のフォークで直すかの判断材料**にしてください。

### 解決済み（フォークで対応された）

| 項目 | 状態 |
|---|---|
| nixpkgs / home-manager / Hyprland / HyDE の陳腐化 | ✅ 全て追従（自動化あり） |
| 本家 issue #169: `programs.git.settings.user.email` エラー | ✅ git モジュールごと削除 |
| 行番号決め打ちの `sed`（HyDE 更新で誤爆する） | ✅ コメントアウト |
| `feat: home-manager configuration in flake`（standalone HM） | ✅ `homeConfigurations.default` を追加 |
| `docs: nixosOptionsDoc によるドキュメント生成` | ✅ mdbook + options ページ |
| `refactor: overlay の名前空間ネスト解消` | ✅ `pkgs/` へ再編 |
| `demo video? fix demo-vm` | ✅ `demo/` を追加 |
| バイナリキャッシュ | △ `nixConfig` に hyprland cachix を追加（部分的） |

**フォーク独自の追加**: `hyprsunset` モジュール、`hydenix.hm.hyprland.systemd.*`、
`hyde-diff-home` / `hyde-diff-upstream`（自分のホームと HyDE 上流の差分を出すツール）、
treefmt / typos / zizmor による CI 強化、renovate による依存自動更新。

### 未解決（フォークにも残っている）

| 項目 | 詳細 | 影響 |
|---|---|---|
| **`mutableGeneration` 不一致** | §5 の件 | 潜在的。作業 B で対応 |
| **pyprland が使えない** | フォークでは `default.nix` で明示的にコメントアウトされ、オプションも削除。本家 issue #188（`hyde-shell pypr console` が動かない）は未解決 | scratchpad 等の pyprland 機能が使えない |
| **`hyde-gallery` の sha256 が空** | `pkgs/hyde-gallery/default.nix` の `sha256 = ""` | 誰も参照していないため表面化していない |
| **`mutable` の改善が未実装** | `mutable.enable` / `mutable.mode`（initOnly / replace）、設定から消したファイルの自動削除、generation ロールバック対応 | **設定から外したファイルがホームに残り続ける**。手動削除が必要 |
| **本家 issue #154: hist 環境変数の位置** | `HISTFILE` 等が `xdg.nix` にあり `shell.nix` に移されていない | 一貫性の問題のみ |
| **本家 issue #182: hypr windowrules errors** | 状態不明。HyDE bump で解消した可能性はある | 要確認 |
| `.config/waybar/modules` を設定している件 | 本家 TODO の「もう設定不要では」がそのまま残存 | 不明 |
| hyprlock を hyprland モジュールへ統合 | `lockscreen.nix` のまま。hyprlock と swaylock の排他 assertion も無い | 設計上の課題 |
| `hyde config.toml` のオプション化 | 未実装 | `config.toml` は mutable なので手で編集する必要がある |
| `nh` の標準採用 | 未採用（`future?` のまま） | **dotnix 側で持っているのでそのまま維持すればよい** |
| nixos-anywhere / disko 対応 | 未実装 | 新マシン構築時は手動 |
| コード内 TODO 各種 | stateful ファイルの見直し、`kdePackages.kconfig` の要否、waybar モジュールの Nix 互換性、`theme.set.sh` の Nix 再実装、GTK テーマ初回変更時のちらつき、fastfetch ロゴ、spicetify 対応 | 個別に軽微 |

**特に注意**: `mutable` の「消しても残る」問題は実運用で効きます。
テーマ関連がおかしくなったら以下でリセットできることを覚えておいてください。

```bash
rm -rf ~/.config/hyde ~/.local/share/hyde ~/.cache/hyde
# その後 nixos-rebuild switch で再配置される
```

---

## 7. 参考

- 自分のフォーク: https://github.com/santamn/hydenix
- 上流: https://github.com/florianvazelle/hydenix
- 上流のドキュメント: https://me.phlowrient.ovh/hydenix/
- 本家（停止中）: https://github.com/richen604/hydenix
- hydenix の設計解説（日本語・詳細）: `~/Documents/hydenix/docs-ja/`
  - `04-mutable-files.md` … `mutable` の仕組み（今回の作業に直結）
  - `05-theme-system.md` … テーマと wallbash、activation の 3 段構え
  - `06-hyprland-modules.md` … `extraConfig` / `overrideConfig` の設計
  - `07-reading-notes.md` … 落とし穴一覧
- 移行前の設定: `git show 39be51d^:modules/hm/default.nix`
