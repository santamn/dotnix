# Hyprland 本体の設定 (Hyprland 0.55 以降の Lua 設定形式)
#
# Hyprland は 0.55 で設定言語を hyprlang から Lua へ移行し、hyprlang は非推奨になった。
# Home Manager 側も `configType = "lua"` で hypr/hyprland.lua を生成できるため、そちらを使う。
# settings の各属性は `hl.<属性名>(...)` という Lua 関数呼び出しとして出力される
# (例: settings.bind の各要素 → hl.bind(...)、settings.config → hl.config({...}))。
# ディスパッチャなど「Lua の式そのもの」を渡したい箇所は lua (mkLuaInline) で包む。
#
# キーバインドは HyDE (hydenix) の既定配置をほぼ踏襲している
# HyDE の Keybinds Hint (SUPER+/) に倣い、バインド一覧を rofi で表示する機能も用意している
{
  config,
  lib,
  pkgs,
  ...
}: let
  # stylix のカラースキーム (壁紙から自動生成) を "#" なしの16進で参照できる
  colors = config.lib.stylix.colors;

  # Lua の式をそのまま設定に埋め込むためのマーカ
  lua = lib.generators.mkLuaInline;
  # Nix の文字列を Lua の文字列リテラルへ変換する (エスケープ込み)
  luaStr = lib.generators.toLua {};

  # 主修飾キーとよく使うアプリ (旧 hyprlang の $mainMod / $terminal などの変数に相当)
  mainMod = "SUPER";
  terminal = "ghostty";
  editor = "ghostty -e nvim";
  explorer = "dolphin";
  # zen-browser flake の default (beta) はバイナリ名・desktop ファイル名とも "zen-beta"
  browser = "zen-beta";

  # スクラッチパッドとして使う special workspace の名前
  # (Lua API の toggle_special は名前を要求するため、旧設定の無名 special から名前付きに変えている)
  scratchpad = "scratchpad";

  # シェルコマンドを実行するディスパッチャ式を組み立てる (exec_cmd は sh -c 経由で実行される)
  execCmd = cmd: "hl.dsp.exec_cmd(${luaStr cmd})";

  # ---- キーバインド定義とチートシート生成 ----
  # 「実際の Hyprland バインド」と「SUPER+/ で表示するチートシート」が
  # 二重管理にならないよう、説明文つきのデータを1箇所にまとめてここから両方を導出する
  # mods は修飾キー名のリスト、dispatcher は hl.dsp.* の Lua 式
  mkEntry = category: mods: key: dispatcher: desc: {inherit category mods key dispatcher desc;};

  # hl.bind(キー文字列, ディスパッチャ, フラグ) の引数列を組み立てる
  # (フラグが空のときは第3引数ごと省略する)
  mkBind = flags: keys: dispatcher: {
    _args = [keys (lua dispatcher)] ++ lib.optional (flags != {}) flags;
  };

  # entry から hl.bind() の引数列を組み立てる (キーは "SUPER + SHIFT + Q" 形式)
  toLuaBind = flags: e:
    mkBind flags (lib.concatStringsSep " + " (e.mods ++ [e.key])) e.dispatcher;

  # ワークスペース 1〜10 の移動・ウィンドウ送りバインドを生成
  # (キー 0 はワークスペース 10 に対応)
  workspaceBinds = builtins.concatLists (builtins.genList (
      i: let
        ws = toString (i + 1);
        key = toString (lib.mod (i + 1) 10);
      in [
        # ワークスペースへ移動
        (mkBind {} "${mainMod} + ${key}" "hl.dsp.focus({ workspace = ${ws} })")
        # ウィンドウを送って移動
        (mkBind {} "${mainMod} + SHIFT + ${key}" "hl.dsp.window.move({ workspace = ${ws} })")
        # ウィンドウだけ送る (follow = false がフォーカスを移動しない指定)
        (mkBind {} "${mainMod} + ALT + ${key}" "hl.dsp.window.move({ workspace = ${ws}, follow = false })")
      ]
    )
    10);

  # チートシート表示用にキー名を読みやすい表記へ変換する対応表
  keyLabels = {
    comma = ",";
    slash = "/";
    Print = "PrintScreen";
    mouse_down = "MouseWheel↓";
    mouse_up = "MouseWheel↑";
    "mouse:272" = "LeftClick";
    "mouse:273" = "RightClick";
    XF86AudioMute = "Mute";
    XF86AudioMicMute = "MicMute";
    XF86AudioPlay = "Play";
    XF86AudioPause = "Pause";
    XF86AudioNext = "Next";
    XF86AudioPrev = "Prev";
    XF86AudioLowerVolume = "Vol-";
    XF86AudioRaiseVolume = "Vol+";
    XF86MonBrightnessUp = "Bright+";
    XF86MonBrightnessDown = "Bright-";
  };
  keyLabel = key: keyLabels.${key} or key;

  # 修飾キー名を表示用の表記へ変換する対応表
  modLabels = {
    CTRL = "Ctrl";
    ALT = "Alt";
    SHIFT = "Shift";
  };

  # 修飾キーとキーの組み合わせをチートシート用の1文字列にする (例: "SUPER+Shift+Q")
  toCheatLine = e:
    "${lib.concatStringsSep "+" ((map (m: modLabels.${m} or m) e.mods) ++ [(keyLabel e.key)])} → ${e.desc}";

  # 実際にバインドされ、チートシートにも表示される主要バインド (フラグなし)
  mainEntries = [
    (mkEntry "ウィンドウ管理" [mainMod] "Q" "hl.dsp.window.close()" "ウィンドウを閉じる")
    (mkEntry "ウィンドウ管理" ["ALT"] "F4" "hl.dsp.window.close()" "ウィンドウを閉じる")
    (mkEntry "ウィンドウ管理" [mainMod] "Delete" "hl.dsp.exit()" "Hyprland セッションを終了する")
    (mkEntry "ウィンドウ管理" [mainMod] "W" ''hl.dsp.window.float({ action = "toggle" })'' "フローティング表示を切り替える")
    (mkEntry "ウィンドウ管理" [mainMod] "G" "hl.dsp.group.toggle()" "ウィンドウをグループ化する")
    (mkEntry "ウィンドウ管理" ["SHIFT"] "F11" ''hl.dsp.window.fullscreen({ mode = "fullscreen" })'' "全画面表示を切り替える")
    (mkEntry "ウィンドウ管理" [mainMod] "F" ''hl.dsp.window.fullscreen({ mode = "fullscreen" })'' "全画面表示を切り替える")
    (mkEntry "ウィンドウ管理" [mainMod] "L" (execCmd "loginctl lock-session") "画面をロックする")
    (mkEntry "ウィンドウ管理" [mainMod "SHIFT"] "F" ''hl.dsp.window.pin({ action = "toggle" })'' "最前面に固定する")
    # 6ボタン横一列 (HyDE style_1 相当、スタイルは desktop/wlogout.nix)
    (mkEntry "ウィンドウ管理" ["CTRL" "ALT"] "Delete" (execCmd "pkill -x wlogout || wlogout -b 6 -p layer-shell") "ログアウトメニューを開く")
    (mkEntry "ウィンドウ管理" [mainMod] "J" ''hl.dsp.layout("togglesplit")'' "分割方向を切り替える")

    (mkEntry "グループ内の移動" [mainMod "CTRL"] "H" "hl.dsp.group.prev()" "グループ内の前のウィンドウへ")
    (mkEntry "グループ内の移動" [mainMod "CTRL"] "L" "hl.dsp.group.next()" "グループ内の次のウィンドウへ")

    (mkEntry "フォーカス移動" [mainMod] "Left" ''hl.dsp.focus({ direction = "left" })'' "左のウィンドウへフォーカス移動")
    (mkEntry "フォーカス移動" [mainMod] "Right" ''hl.dsp.focus({ direction = "right" })'' "右のウィンドウへフォーカス移動")
    (mkEntry "フォーカス移動" [mainMod] "Up" ''hl.dsp.focus({ direction = "up" })'' "上のウィンドウへフォーカス移動")
    (mkEntry "フォーカス移動" [mainMod] "Down" ''hl.dsp.focus({ direction = "down" })'' "下のウィンドウへフォーカス移動")
    (mkEntry "フォーカス移動" ["ALT"] "Tab" "hl.dsp.window.cycle_next()" "ウィンドウを順に切り替える")

    (mkEntry "ウィンドウ移動" [mainMod "SHIFT" "CTRL"] "Left" ''hl.dsp.window.move({ direction = "left" })'' "ウィンドウを左へ移動")
    (mkEntry "ウィンドウ移動" [mainMod "SHIFT" "CTRL"] "Right" ''hl.dsp.window.move({ direction = "right" })'' "ウィンドウを右へ移動")
    (mkEntry "ウィンドウ移動" [mainMod "SHIFT" "CTRL"] "Up" ''hl.dsp.window.move({ direction = "up" })'' "ウィンドウを上へ移動")
    (mkEntry "ウィンドウ移動" [mainMod "SHIFT" "CTRL"] "Down" ''hl.dsp.window.move({ direction = "down" })'' "ウィンドウを下へ移動")

    (mkEntry "アプリ起動" [mainMod] "T" (execCmd terminal) "ターミナルを開く")
    (mkEntry "アプリ起動" [mainMod] "E" (execCmd explorer) "ファイルマネージャを開く")
    (mkEntry "アプリ起動" [mainMod] "C" (execCmd editor) "エディタを開く")
    (mkEntry "アプリ起動" [mainMod] "B" (execCmd browser) "ブラウザを開く")
    (mkEntry "アプリ起動" ["CTRL" "SHIFT"] "Escape" (execCmd "${terminal} -e btm") "システムモニタを開く")

    # ランチャー系は HyDE style_1 相当のテーマ、dmenu 系はドロップダウン型テーマを使う
    # (テーマ定義は desktop/rofi.nix)
    (mkEntry "rofi メニュー" [mainMod] "A" (execCmd "pkill -x rofi || rofi -show drun -theme hyde-launcher") "アプリランチャーを開く")
    (mkEntry "rofi メニュー" [mainMod] "Tab" (execCmd "pkill -x rofi || rofi -show window -theme hyde-launcher") "ウィンドウ切り替えメニューを開く")
    (mkEntry "rofi メニュー" [mainMod "SHIFT"] "E" (execCmd "pkill -x rofi || rofi -show filebrowser -theme hyde-launcher") "ファイル検索を開く")
    (mkEntry "rofi メニュー" [mainMod] "V" (execCmd "pkill -x rofi || cliphist list | rofi -dmenu -p 󰅍 -theme hyde-dropdown | cliphist decode | wl-copy") "クリップボード履歴を開く")
    (mkEntry "rofi メニュー" [mainMod "SHIFT"] "V" (execCmd "pkill -x rofi || cliphist list | rofi -dmenu -p 󰆴 -theme hyde-dropdown | cliphist delete") "クリップボード履歴から削除")
    (mkEntry "rofi メニュー" [mainMod] "comma" (execCmd "rofimoji") "絵文字ピッカーを開く")

    (mkEntry "スクリーンショット・カラーピッカー" [mainMod] "P" (execCmd "${screenshot}/bin/hypr-screenshot s") "範囲を選択して撮影し注釈を付ける")
    (mkEntry "スクリーンショット・カラーピッカー" [mainMod "CTRL"] "P" (execCmd "${screenshot}/bin/hypr-screenshot sf") "画面を停止して範囲を撮影し注釈を付ける")
    (mkEntry "スクリーンショット・カラーピッカー" [mainMod "ALT"] "P" (execCmd "${screenshot}/bin/hypr-screenshot m") "アクティブモニタを撮影し注釈を付ける")
    (mkEntry "スクリーンショット・カラーピッカー" [] "Print" (execCmd "${screenshot}/bin/hypr-screenshot p") "モニタ全体を撮影して保存")
    (mkEntry "スクリーンショット・カラーピッカー" [mainMod "SHIFT"] "P" (execCmd "hyprpicker -an") "色を取得してクリップボードへコピー")

    (mkEntry "ワークスペース" [mainMod "CTRL"] "Right" ''hl.dsp.focus({ workspace = "r+1" })'' "次のワークスペースへ")
    (mkEntry "ワークスペース" [mainMod "CTRL"] "Left" ''hl.dsp.focus({ workspace = "r-1" })'' "前のワークスペースへ")
    (mkEntry "ワークスペース" [mainMod "CTRL"] "Down" ''hl.dsp.focus({ workspace = "empty" })'' "空きワークスペースへ")
    (mkEntry "ワークスペース" [mainMod "CTRL" "ALT"] "Right" ''hl.dsp.window.move({ workspace = "r+1" })'' "次のワークスペースへウィンドウを送る")
    (mkEntry "ワークスペース" [mainMod "CTRL" "ALT"] "Left" ''hl.dsp.window.move({ workspace = "r-1" })'' "前のワークスペースへウィンドウを送る")
    (mkEntry "ワークスペース" [mainMod] "mouse_down" ''hl.dsp.focus({ workspace = "e+1" })'' "次のワークスペースへ (ホイール)")
    (mkEntry "ワークスペース" [mainMod] "mouse_up" ''hl.dsp.focus({ workspace = "e-1" })'' "前のワークスペースへ (ホイール)")

    (mkEntry "スクラッチパッド" [mainMod] "S" "hl.dsp.workspace.toggle_special(${luaStr scratchpad})" "スクラッチパッドの表示を切り替える")
    (mkEntry "スクラッチパッド" [mainMod "SHIFT"] "S" "hl.dsp.window.move({ workspace = ${luaStr "special:${scratchpad}"} })" "スクラッチパッドへウィンドウを送る")
    (mkEntry "スクラッチパッド" [mainMod "ALT"] "S" "hl.dsp.window.move({ workspace = ${luaStr "special:${scratchpad}"}, follow = false })" "スクラッチパッドへウィンドウだけ送る")
  ];

  # リサイズ (押しっぱなしで連続動作、repeating フラグ)
  resizeEntries = [
    (mkEntry "リサイズ" [mainMod "SHIFT"] "Right" "hl.dsp.window.resize({ x = 30, y = 0, relative = true })" "右へ拡大")
    (mkEntry "リサイズ" [mainMod "SHIFT"] "Left" "hl.dsp.window.resize({ x = -30, y = 0, relative = true })" "左へ縮小")
    (mkEntry "リサイズ" [mainMod "SHIFT"] "Up" "hl.dsp.window.resize({ x = 0, y = -30, relative = true })" "上へ縮小")
    (mkEntry "リサイズ" [mainMod "SHIFT"] "Down" "hl.dsp.window.resize({ x = 0, y = 30, relative = true })" "下へ拡大")
  ];

  # マウス・ドラッグ操作 (mouse フラグ: 押している間ドラッグ操作になる)
  dragEntries = [
    (mkEntry "マウス操作" [mainMod] "mouse:272" "hl.dsp.window.drag()" "ウィンドウをドラッグ移動")
    (mkEntry "マウス操作" [mainMod] "mouse:273" "hl.dsp.window.resize()" "ウィンドウをドラッグリサイズ")
    (mkEntry "マウス操作" [mainMod] "Z" "hl.dsp.window.drag()" "ウィンドウをドラッグ移動")
    (mkEntry "マウス操作" [mainMod] "X" "hl.dsp.window.resize()" "ウィンドウをドラッグリサイズ")
  ];

  # メディア・音量 (ロック画面でも効く、locked フラグ)
  mediaEntries = [
    (mkEntry "メディア・音量" [] "F10" (execCmd "${osd}/bin/hypr-osd volume mute") "ミュート切り替え")
    (mkEntry "メディア・音量" [] "XF86AudioMute" (execCmd "${osd}/bin/hypr-osd volume mute") "ミュート切り替え")
    (mkEntry "メディア・音量" [] "XF86AudioMicMute" (execCmd "${osd}/bin/hypr-osd mic mute") "マイクミュート切り替え")
    (mkEntry "メディア・音量" [] "XF86AudioPlay" (execCmd "playerctl play-pause") "再生・一時停止")
    (mkEntry "メディア・音量" [] "XF86AudioPause" (execCmd "playerctl play-pause") "再生・一時停止")
    (mkEntry "メディア・音量" [] "XF86AudioNext" (execCmd "playerctl next") "次の曲")
    (mkEntry "メディア・音量" [] "XF86AudioPrev" (execCmd "playerctl previous") "前の曲")
  ];

  # 音量・輝度 (押しっぱなしで連続動作、ロック画面でも効く: locked + repeating)
  # hypr-osd 経由で変更し、進捗バー付きの通知を表示する (HyDE の volumecontrol.sh 相当)
  sliderEntries = [
    (mkEntry "音量・輝度" [] "F11" (execCmd "${osd}/bin/hypr-osd volume down") "音量を下げる")
    (mkEntry "音量・輝度" [] "F12" (execCmd "${osd}/bin/hypr-osd volume up") "音量を上げる")
    (mkEntry "音量・輝度" [] "XF86AudioLowerVolume" (execCmd "${osd}/bin/hypr-osd volume down") "音量を下げる")
    (mkEntry "音量・輝度" [] "XF86AudioRaiseVolume" (execCmd "${osd}/bin/hypr-osd volume up") "音量を上げる")
    (mkEntry "音量・輝度" [] "XF86MonBrightnessUp" (execCmd "${osd}/bin/hypr-osd brightness up") "輝度を上げる")
    (mkEntry "音量・輝度" [] "XF86MonBrightnessDown" (execCmd "${osd}/bin/hypr-osd brightness down") "輝度を下げる")
  ];

  # ワークスペース 1〜10 の一括バインド (workspaceBinds) はチートシートには要約だけを載せる
  workspaceCheatOnly = [
    (mkEntry "ワークスペース" [mainMod] "1〜0" "" "該当ワークスペースへ移動")
    (mkEntry "ワークスペース" [mainMod "SHIFT"] "1〜0" "" "ウィンドウを送って移動")
    (mkEntry "ワークスペース" [mainMod "ALT"] "1〜0" "" "ウィンドウだけ送る (フォーカスは移動しない)")
  ];

  # キーバインド一覧を表示するバインド自体もチートシートに含める
  # (実際のバインドは keybindsHint の store path に依存するため下記で別途組み立てる)
  keybindsHintCheatEntry = mkEntry "rofi メニュー" [mainMod] "slash" "" "キーバインド一覧を表示する";

  cheatEntries =
    mainEntries
    ++ resizeEntries
    ++ dragEntries
    ++ mediaEntries
    ++ sliderEntries
    ++ workspaceCheatOnly
    ++ [keybindsHintCheatEntry];

  # チートシートでの見出し表示順 (Nix の属性集合は挿入順を保持しないため明示的に順序を持たせる)
  categoryOrder = [
    "ウィンドウ管理"
    "グループ内の移動"
    "フォーカス移動"
    "ウィンドウ移動"
    "アプリ起動"
    "rofi メニュー"
    "スクリーンショット・カラーピッカー"
    "ワークスペース"
    "スクラッチパッド"
    "リサイズ"
    "マウス操作"
    "メディア・音量"
    "音量・輝度"
  ];

  cheatSheetText = lib.concatStringsSep "\n\n" (map (
      cat:
        lib.concatStringsSep "\n" (
          ["── ${cat} ──"]
          ++ map toCheatLine (builtins.filter (e: e.category == cat) cheatEntries)
        )
    )
    categoryOrder);

  # SUPER+/ で起動する、キーバインド一覧を rofi に表示するスクリプト (HyDE の Keybinds Hint 相当)
  # 見た目は desktop/rofi.nix の hyde-keybinds テーマ (HyDE clipboard スタイルの横長版)
  keybindsHint = pkgs.writeShellApplication {
    name = "hypr-keybinds-hint";
    runtimeInputs = [pkgs.rofi];
    text = ''
      rofi -dmenu -i -p "󰌌" -theme hyde-keybinds \
        -theme-str 'entry { placeholder: "󰌌  キーバインドを検索..."; }' <<'EOF'
      ${cheatSheetText}
      EOF
    '';
  };

  # スクリーンショット (HyDE の screenshot.sh 相当)
  # s/sf/m は撮影後に satty が開き、注釈を付けてから保存・クリップボードへコピーできる
  screenshot = pkgs.writeShellApplication {
    name = "hypr-screenshot";
    runtimeInputs = with pkgs; [coreutils hyprshot satty wl-clipboard];
    text = ''
      mode="''${1:-s}"
      save_dir="''${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
      save_file="$(date +'%y%m%d_%Hh%Mm%Ss_screenshot.png')"
      mkdir -p "$save_dir"

      # 撮影結果を satty で開き、注釈後に保存とクリップボードコピーを行う
      annotate() {
        satty --filename - --output-filename "$save_dir/$save_file" \
          --early-exit --copy-command wl-copy
      }

      case "$mode" in
      s) hyprshot -m region --raw | annotate ;; # 範囲を選択して撮影
      sf) hyprshot -m region -z --raw | annotate ;; # 画面を停止して範囲を撮影
      m) hyprshot -m output -m active --raw | annotate ;; # アクティブモニタを撮影
      p) hyprshot -m output -o "$save_dir" -f "$save_file" ;; # 全モニタを撮影して保存のみ
      *)
        echo "usage: hypr-screenshot [s|sf|m|p]" >&2
        exit 1
        ;;
      esac
    '';
  };

  # 音量・マイク・輝度の変更と通知表示 (HyDE の volumecontrol.sh / brightnesscontrol.sh 相当)
  # mako が -h int:value を進捗バーとして描画する
  osd = pkgs.writeShellApplication {
    name = "hypr-osd";
    runtimeInputs = with pkgs; [brightnessctl coreutils gawk libnotify wireplumber];
    text = ''
      target="''${1:?usage: hypr-osd volume|mic|brightness up|down|mute}"
      action="''${2:?usage: hypr-osd volume|mic|brightness up|down|mute}"

      # 同じ ID で通知を置き換えることで、連打してもバーが1つだけ更新される
      notify() { # 引数: 通知ID アイコン名 本文 進捗値(0-100)
        notify-send -a "hypr-osd" -r "$1" -t 1500 -i "$2" -h "int:value:$4" "$3"
      }

      case "$target" in
      volume)
        case "$action" in
        up) wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ ;;
        down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
        mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
        esac
        status="$(wpctl get-volume @DEFAULT_AUDIO_SINK@)" # 例: "Volume: 0.45 [MUTED]"
        vol="$(awk '{print int($2 * 100)}' <<<"$status")"
        if [[ "$status" == *MUTED* ]]; then
          notify 91190 audio-volume-muted "󰝟 ミュート" 0
        elif ((vol < 34)); then
          notify 91190 audio-volume-low "󰕿 音量 $vol%" "$vol"
        elif ((vol < 67)); then
          notify 91190 audio-volume-medium "󰖀 音量 $vol%" "$vol"
        else
          notify 91190 audio-volume-high "󰕾 音量 $vol%" "$vol"
        fi
        ;;
      mic)
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
        status="$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@)"
        vol="$(awk '{print int($2 * 100)}' <<<"$status")"
        if [[ "$status" == *MUTED* ]]; then
          notify 91191 microphone-sensitivity-muted "󰍭 マイク: ミュート" 0
        else
          notify 91191 microphone-sensitivity-high "󰍬 マイク: オン" "$vol"
        fi
        ;;
      brightness)
        case "$action" in
        up) brightnessctl set 5%+ ;;
        down) brightnessctl set 5%- ;;
        esac
        pct="$(brightnessctl -m | awk -F, '{print $4}' | tr -d '%')"
        notify 91192 display-brightness "󰃟 輝度 $pct%" "$pct"
        ;;
      esac
    '';
  };
in {
  wayland.windowManager.hyprland = {
    enable = true;
    # Hyprland 0.55 以降の Lua 設定形式 (~/.config/hypr/hyprland.lua) を生成する
    configType = "lua";

    # Hyprland 本体とポータルはシステム側 (programs.hyprland) が提供するため、
    # Home Manager からは重複してインストールしない
    package = null;
    portalPackage = null;

    # waybar / hypridle などの systemd ユーザサービスが使う
    # graphical-session.target を提供する
    systemd = {
      enable = true;
      variables = ["--all"];
    };

    settings = {
      # モニタ: 接続されたものを推奨解像度・自動配置で使う
      monitor = {
        output = "";
        mode = "preferred";
        position = "auto";
        scale = 1;
      };

      env = [
        {_args = ["QT_QPA_PLATFORM" "wayland;xcb"];}
        {_args = ["QT_WAYLAND_DISABLE_WINDOWDECORATION" "1"];}
        {_args = ["QT_AUTO_SCREEN_SCALE_FACTOR" "1"];}
      ];

      # 起動時に実行するコマンド (旧 exec-once)
      # Home Manager の systemd 連携も別の hyprland.start ハンドラを生成するが、
      # ハンドラは複数登録できるため共存できる
      on = {
        _args = [
          "hyprland.start"
          (lua ''
            function()
              hl.exec_cmd("fcitx5 -d") -- 日本語入力
            end
          '')
        ];
      };

      # 3本指スワイプでワークスペースを切り替え
      gesture = {
        fingers = 3;
        direction = "horizontal";
        action = "workspace";
      };

      # 変数系の設定はまとめて hl.config({...}) として出力される
      config = {
        input = {
          kb_layout = "us";
          # CapsLock と Ctrl キーを入れ替える
          kb_options = "ctrl:swapcaps";
          follow_mouse = 1;

          touchpad = {
            # 指の上下とスクロール方向を逆にする
            natural_scroll = true;
            # スクロール速度を半分にする
            scroll_factor = 0.5;

            # タッチパッドの押し込みをクリックとして扱う
            # 1本:左クリック 2本:右クリック 3本:中クリック
            clickfinger_behavior = true;
            # タップでクリックを有効化
            tap_to_click = true;
            # タップは 1本:左クリック 2本:中クリック 3本:右クリック
            tap_button_map = "lmr";
          };
        };

        general = {
          gaps_in = 3;
          gaps_out = 8;
          border_size = 2;
          # ボーダー配色 (アクティブ: base0B→base0A / 非アクティブ: base0D→base0C のグラデーション)
          col = {
            active_border = {
              colors = ["rgba(${colors.base0B}ff)" "rgba(${colors.base0A}ff)"];
              angle = 45;
            };
            inactive_border = {
              colors = ["rgba(${colors.base0D}cc)" "rgba(${colors.base0C}cc)"];
              angle = 45;
            };
          };
          layout = "dwindle";
          resize_on_border = true;
        };

        decoration = {
          rounding = 10;
          shadow.enabled = false;
          blur = {
            enabled = true;
            size = 5;
            passes = 4;
            new_optimizations = true;
            ignore_opacity = true;
            xray = false;
          };
        };

        animations.enabled = true;

        dwindle.preserve_split = true;

        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          # 中クリックペーストを無効化
          middle_click_paste = false;
        };

        # vfr は 0.55 で misc から debug に移動した (本番環境向けの変数ではないため)
        debug.vfr = true; # 画面更新がないときの消費電力を抑える
      };

      # アニメーションの補間曲線 (旧 bezier)。hl.animation より先に出力される
      curve = [
        {
          _args = [
            "wind"
            {
              type = "bezier";
              points = [[0.05 0.9] [0.1 1.05]];
            }
          ];
        }
        {
          _args = [
            "winIn"
            {
              type = "bezier";
              points = [[0.1 1.1] [0.1 1.1]];
            }
          ];
        }
        {
          _args = [
            "winOut"
            {
              type = "bezier";
              points = [[0.3 (-0.3)] [0 1]];
            }
          ];
        }
        {
          _args = [
            "liner"
            {
              type = "bezier";
              points = [[1 1] [1 1]];
            }
          ];
        }
      ];

      animation = [
        {
          leaf = "windows";
          enabled = true;
          speed = 6;
          bezier = "wind";
          style = "slide";
        }
        {
          leaf = "windowsIn";
          enabled = true;
          speed = 6;
          bezier = "winIn";
          style = "slide";
        }
        {
          leaf = "windowsOut";
          enabled = true;
          speed = 5;
          bezier = "winOut";
          style = "slide";
        }
        {
          leaf = "windowsMove";
          enabled = true;
          speed = 5;
          bezier = "wind";
          style = "slide";
        }
        {
          leaf = "border";
          enabled = true;
          speed = 1;
          bezier = "liner";
        }
        {
          leaf = "fade";
          enabled = true;
          speed = 10;
          bezier = "default";
        }
        {
          leaf = "workspaces";
          enabled = true;
          speed = 5;
          bezier = "wind";
        }
      ];

      # ウィンドウルール (HyDE の windowrules.conf 相当)
      # 設定系のダイアログはフローティング + 半透明にする
      # (opacity は "アクティブ 非アクティブ フルスクリーン" の順、override は乗算でなく絶対値指定)
      window_rule = [
        {
          match.class = "^(org.pulseaudio.pavucontrol|pavucontrol)$";
          float = true;
          opacity = "0.80 override 0.70 override 1 override";
        }
        {
          match.class = "^(\\.?blueman-manager(-wrapped)?)$";
          float = true;
          opacity = "0.80 override 0.70 override 1 override";
        }
        {
          match.class = "^(nm-connection-editor)$";
          float = true;
          opacity = "0.80 override 0.70 override 1 override";
        }
        {
          match.class = "^(fcitx5-config-qt)$";
          float = true;
        }
        # ファイルマネージャ・アーカイバは半透明 (背景ぼかしと合わせて HyDE の質感になる)
        {
          match.class = "^(org.kde.dolphin)$";
          opacity = "0.80 override 0.80 override 1 override";
        }
        {
          match.class = "^(org.kde.ark)$";
          opacity = "0.80 override 0.80 override 1 override";
        }
        # 動画・音楽を全画面再生中は自動ロック・画面オフを抑止する
        {
          match.class = "^(zen.*|.*firefox.*|mpv|vlc|.*[Ss]potify.*)$";
          idle_inhibit = "fullscreen";
        }
        # ブラウザのピクチャインピクチャを右下に小さく配置して最前面に固定
        {
          match.title = "^(Picture-in-Picture|ピクチャーインピクチャー|ピクチャインピクチャ)$";
          float = true;
          pin = true;
          keep_aspect_ratio = true;
          move = "73% 72%";
          size = "25% 25%";
        }
      ];

      # レイヤールール: rofi / wlogout / 通知の背後をぼかす
      # (ignore_alpha = 0 は旧 ignorezero 相当)
      layer_rule = [
        {
          match.namespace = "rofi";
          blur = true;
          ignore_alpha = 0;
        }
        {
          match.namespace = "logout_dialog"; # wlogout
          blur = true;
          ignore_alpha = 0;
        }
        {
          match.namespace = "notifications"; # mako
          blur = true;
          ignore_alpha = 0;
        }
        {
          match.namespace = "waybar";
          blur = true;
          ignore_alpha = 0;
        }
      ];

      # ---- キーバインド ----
      # mainEntries などのデータから生成 (詳細は上の let ブロックを参照)
      # Lua 形式では binde/bindm/bindl/bindel の区別がなくなり、すべて hl.bind のフラグで表現する
      bind =
        (map (toLuaBind {}) mainEntries)
        ++ workspaceBinds
        # キーバインド一覧を表示 (HyDE の Keybinds Hint 相当)
        ++ [(mkBind {} "${mainMod} + slash" (execCmd "pkill -x rofi || ${keybindsHint}/bin/hypr-keybinds-hint"))]
        ++ map (toLuaBind {repeating = true;}) resizeEntries
        ++ map (toLuaBind {mouse = true;}) dragEntries
        ++ map (toLuaBind {locked = true;}) mediaEntries
        ++ map (toLuaBind {
          locked = true;
          repeating = true;
        })
        sliderEntries;
    };
  };

  home.packages = [keybindsHint osd screenshot];
}
