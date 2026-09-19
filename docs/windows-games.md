# Windows の exe ゲームを動かす

[modules/nixos/hydenix.nix](../modules/nixos/hydenix.nix) で `hydenix.gaming.enable = true` にしてあるので、wine やランチャーを自分で足す必要はない。hydenix 側の [modules/system/gaming.nix](https://github.com/santamn/hydenix/blob/main/modules/system/gaming.nix) がまとめて入れている。

## 入っているもの

| パッケージ | 用途 |
| --- | --- |
| `wineWow64Packages.staging` | wine 本体。staging パッチ入り |
| `winetricks` | prefix への DLL やフォントの追加 |
| `lutris` | ゲーム管理 GUI。libadwaita と gtk4 を足した override |
| `heroic` | GOG と Epic と Amazon のランチャー |
| `umu-launcher` | Steam の外から Proton を使う (`umu-run`) |
| `mangohud` | FPS や温度のオーバーレイ |

システム側では Steam (`proton-ge-bin` 付き) と gamescope が有効になっていて、Xbox コントローラ用の xone と xpadneo、DualSense のタッチパッドを libinput から隠す udev ルールも入る。

環境変数も向こうで設定済み:

- `STEAM_EXTRA_COMPAT_TOOLS_PATHS` が `~/.steam/root/compatibilitytools.d` を指す
- `MANGOHUD_CONFIG` に縦並びレイアウトの設定が入る

## どれを使うか

Steam で買ったゲームは Steam をそのまま起動すればいい。GOG と Epic のゲームは Heroic に任せる。

問題は残りの exe、インストーラや zip で配られている同人ゲームや古い市販ゲームのほうだ。これは Lutris を使う。理由は2つある。

1つは、prefix とロケールと Windows バージョンを GUI で指定できて、あとの管理も Lutris が持ってくれること。日本語のゲームは `LC_ALL` を `ja_JP.utf8` にしないと文字化けするものがあるが、Lutris は追加のときにロケールを訊いてくる。

もう1つは NixOS 側の事情で、nixpkgs の lutris が `buildFHSEnv` でラップされていて `multiArch = true` になっている。Lutris が自前でダウンロードしてくる wine-GE ランナーや DXVK は普通の Linux のパスを前提にしたバイナリなので、NixOS に素で置くと動的リンクで死ぬ。FHS の中なら動く。

wine を直に叩くのは、GUI を経由したくないときと、一度きりのインストーラを走らせるときだけでいい。gamescope は最初から付けなくていい ([後述](#gamescope-で包む))。

## Lutris

### ゲームの追加

`lutris` で起動すると、ウィンドウ左上のヘッダーバーに「+」のアイコンが出ている (ツールチップは "Add Game")。ゲームを入れる入口はここだけなので、まずこれを押す。

なお Lutris 0.5.22 には日本語訳が入っていないので、ロケールが `ja_JP.UTF-8` でも画面は英語のままだ。以下の項目名は実際の表示と同じものを書いている。

「+」を押すと "Add games to Lutris" というダイアログが開いて、5つ並ぶ:

| 項目 | 何をするか |
| --- | --- |
| Search the Lutris website for installers | lutris.net にある有志のインストールスクリプトを検索する |
| Install a Windows game from an executable | exe のインストーラを wine で走らせる |
| Install from a local install script | 手元の YAML インストールスクリプトを実行する |
| Import ROMs | エミュレータ用の ROM を取り込む |
| Add locally installed game | すでにインストール済みのものを手で登録する |

### インストーラ配布のゲームを入れる

"Install a Windows game from an executable" を選ぶ。次の画面で入力するのは3つ:

- **Game name**: 好きな名前。prefix を置くディレクトリ名にもなる
- **Installer preset**: Windows のバージョン。既定は Windows 10 64-bit
- **Locale**: ゲームに渡す `LC_ALL`。日本語のゲームなら Japanese (`ja_JP.utf8`) を選ぶ

"Install" を押すとファイル選択が出るので setup.exe を指定する。あとは Windows のインストーラの画面をそのまま進めればいい。

prefix は Lutris がゲームごとのディレクトリ (`$GAMEDIR`) に作るので、自分で分ける必要はない。インストールが終わったあとの本体 exe も Lutris が prefix の中を探して自動で見つける。

> [!NOTE]
> Installer preset に Windows XP 32-bit と Windows 98 32-bit が出るのは、wine ランナーのバージョンが GE-Proton でも Proton でもないときだけ。古い 32bit のゲームを入れるつもりなら、ランナーは素の wine のままにしておく。

zip で配られていてインストーラが無いゲームは、展開してから "Add locally installed game" で登録する。ランナーに wine、実行ファイルに exe を指定する。

### ランナーの管理

ランナーはシステムの wine ではなく Lutris 側に管理させたほうがいい。ヘッダーバー右のハンバーガーメニューから Preferences を開き、左の Runners を選ぶと wine の行に "Manage wine versions" がある。ここから lutris.net の一覧を取ってきて Install する。Lutris 管理のランナーなら DXVK も一緒に面倒を見てくれる。

## wine を直に叩く

prefix はゲームごとに分ける。混ぜると片方に入れた winetricks の DLL が他方を壊す。

```bash
export WINEPREFIX=~/games/prefixes/foo
wine setup.exe    # prefix が無ければ自動で作られる
```

初回の prefix 作成時に wine-mono と wine-gecko のダウンロードを促すダイアログが出る。nixpkgs の wine は `embedInstallers` が既定で `false` で、MSI インストーラを同梱していないからだ。.NET を使うゲームなら入れる。内蔵ブラウザも .NET も使わないなら両方キャンセルして構わない。

インストールが終わったら本体を起動する:

```bash
wine "$WINEPREFIX/drive_c/Program Files/Foo/foo.exe"
```

Windows のバージョンや画面設定をいじりたいときは `winecfg`。prefix を作り直すときは `$WINEPREFIX` のディレクトリを消してからやり直す (`wineboot -u` は既存 prefix の更新なので、壊れた prefix は直らない)。

## umu-launcher で Proton を使う

wine では動かないが Proton なら動くゲームがときどきある。`GAMEID` は必須で、Steam のゲームでなければ `0` を渡せばいい。

```bash
GAMEID=0 WINEPREFIX=~/games/prefixes/foo umu-run setup.exe
```

`PROTONPATH` で使う Proton を指定できる。指定しなければ umu が自前で落としてくる。

## Steam に非 Steam ゲームとして登録する

ライブラリの「ゲームを追加」から「非 Steam ゲームを追加」で exe を選び、プロパティの「互換性」で Proton を強制指定する。`proton-ge-bin` が `extraCompatPackages` に入っているので一覧に出る。

コントローラ設定とオーバーレイをそのまま使えるのが利点。

## gamescope で包む

必須ではない。まず付けずに起動して、問題が出たときだけ足せばいい。次のどれかに当たったら効く:

- ゲームが解像度を変えた瞬間に他のワークスペースまで巻き込んでウィンドウが並び替わる
- フルスクリーンにできない、あるいはフルスクリーンにすると表示が崩れる
- ゲーム側に解像度の選択肢が無くて、画面の解像度に合わない
- フレームレートを絞って発熱とバッテリーを抑えたい
- 重いので内部解像度を落として引き伸ばしたい

gamescope を挟むとゲームは専用の小さな Wayland セッションの中で動くので、Hyprland 側に影響しない。内部解像度と出力解像度を別に持てるのもここから来ている。

### Lutris から使う

Lutris で管理しているゲームなら、コマンドを組む必要はない。ゲームの設定の System options に Gamescope のセクションがあり、Enable Gamescope を入れると出力解像度、ゲーム側の解像度、ウィンドウモード (fullscreen / windowed / borderless)、FSR のシャープネス、HDR を GUI から指定できる。ゲーム中のフルスクリーン切り替えは `Super + F`。

このトグルは gamescope が PATH から見つからないと表示されない。`buildFHSEnv` が FHS 内の PATH の先頭に `/run/wrappers/bin` を置いているので、`capSysNice = true` で wrapper 側に入っていても Lutris から見える。

### コマンドラインから使う

```bash
gamescope -W 1920 -H 1200 -f -- wine game.exe
```

- `-W` と `-H` が gamescope 自身 (出力) の解像度。既定が 1280x720 なので、指定を省くとそこに落ちる
- `-w` と `-h` がゲーム側の解像度。省略すると `-W`/`-H` と同じ
- `-f` がフルスクリーン、`-b` がボーダーレスウィンドウ
- `-r` でフレームレート上限、`-o` で非フォーカス時の上限
- `-F fsr` で FSR アップスケーリング、`-S integer` で整数倍スケーリング

内部 1280x800 でレンダリングして画面いっぱいに FSR で引き伸ばすなら、こうなる:

```bash
gamescope -w 1280 -h 800 -W 1920 -H 1200 -F fsr -f -- wine game.exe
```

> [!NOTE]
> hydenix 側で `programs.gamescope.capSysNice = true` になっているため、gamescope は `environment.systemPackages` ではなく `security.wrappers` 経由で `/run/wrappers/bin/gamescope` に入る。PATH には含まれているのでそのまま呼べる。

## mangohud を重ねる

`MANGOHUD_CONFIG` は設定済みなので、コマンドの前に置くだけでいい。

```bash
mangohud wine game.exe
gamescope -W 1920 -H 1200 -f -- mangohud wine game.exe
```

既定では `Shift_R + F12` で表示を切り替えられる。

## 日本語表示

ロケールは `ja_JP.UTF-8` ([modules/nixos/locale.nix](../modules/nixos/locale.nix))、Noto CJK もシステムに入っている ([modules/nixos/fonts.nix](../modules/nixos/fonts.nix))。fontconfig を見るゲームならこれで日本語が出る。

MS ゴシックや MS UI ゴシックをフォント名で名指しする古いゲームは豆腐になる。その prefix に対して winetricks で別名を登録する:

```bash
WINEPREFIX=~/games/prefixes/foo winetricks fakejapanese
```

`fakejapanese` は Source Han Sans を入れて、MS Gothic と MS PGothic と MS Mincho、MS UI Gothic、Meiryo、Yu Gothic からの別名を張る。中国語と韓国語もまとめて面倒を見たいなら `cjkfonts` を使う (`fakechinese` と `fakejapanese` と `fakekorean` と `unifont` を順に実行する)。

## 詰まったとき

### 32bit のインストーラやゲームが落ちる

システムに入る wine は `wineWow64Packages.staging`、つまり wine の新しい WoW64 モードで、`--enable-archs=x86_64,i386` の単一ツリーになっている。32bit の Linux ライブラリを使わないので gecko32 も入らない。古い 32bit 専用のものは従来の multilib 版のほうが安定するらしい。Lutris のランナーに逃げるか、`modules/nixos/` 側に足す:

```nix
environment.systemPackages = [pkgs.wineWowPackages.staging];
```

### D3D のゲームで描画が出ない

DXVK を入れる。Lutris のランナーと Proton には同梱されているので、素の wine で動かしているときだけの話。

```bash
WINEPREFIX=~/games/prefixes/foo winetricks dxvk
```

### そもそも動くのか分からない

Steam のゲームなら [ProtonDB](https://www.protondb.com/)、それ以外は [WineHQ AppDB](https://appdb.winehq.org/) にタイトルごとの報告がある。Lutris にインストールスクリプトが用意されているタイトルは、まずそれを試すのが早い。
