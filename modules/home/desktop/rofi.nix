# アプリランチャー (rofi)
#
# HyDE (hydenix) の rofi テーマの移植。stylix の自動生成テーマ (色のみで
# レイアウトは rofi 既定のまま) では表示が大きく崩れるため、
# stylix のターゲットは外し (modules/home/theme.nix)、配色だけを
# stylix のスキームから取った完全な rasi テーマを自前で持つ。
#
# テーマは3種類あり、HyDE と同様に用途ごとに使い分ける:
# - hyde-launcher: HyDE の style_1 相当。左に壁紙サイドバー + モード切替、右にリスト
#   (SUPER+A / SUPER+Tab / SUPER+Shift+E が -theme 指定で使用)
# - hyde-dropdown: HyDE の clipboard 相当の小型ドロップダウン。config.rasi の既定テーマ
#   (クリップボード履歴や rofimoji など dmenu 系の呼び出しが使用)
# - hyde-keybinds: hyde-dropdown の横長版 (SUPER+/ のキーバインド一覧が使用)
{
  config,
  pkgs,
  ...
}: let
  colors = config.lib.stylix.colors;

  # HyDE の swwwallcache.sh と同じ加工を stylix の壁紙に施した派生画像
  # (テーマ内のサイドバー背景などに使う。壁紙を変えると自動で追従する)
  wallThumbs =
    pkgs.runCommand "rofi-wall-thumbs" {
      nativeBuildInputs = [pkgs.imagemagick];
    } ''
      mkdir -p $out
      # サイドバー用の正方形サムネイル
      magick ${config.stylix.image} -strip -resize 1000 -gravity center -extent 1000 -quality 90 $out/wall-thmb.png
      # 入力欄の背景用のぼかし画像
      magick ${config.stylix.image} -strip -scale 10% -blur 0x3 -resize 100% $out/wall-blur.png
      # 右端を斜めに切り落とした正方形 (ドロップダウン左上の装飾用)
      magick ${config.stylix.image} -strip -thumbnail 500x500^ -gravity center -extent 500x500 $out/wall-sqre.png
      magick $out/wall-sqre.png \
        \( -size 500x500 xc:white -fill "rgba(0,0,0,0.7)" -draw "polygon 400,500 500,500 500,0 450,0" -fill black -draw "polygon 500,500 500,0 450,500" \) \
        -alpha Off -compose CopyOpacity -composite $out/wall-quad.png
    '';

  # HyDE の theme.rasi 相当の配色定義 (stylix のスキームから生成)
  # select-bg は waybar のアクティブワークスペースと同じアクセント色 (base0B)
  colorDefs = ''
    * {
        main-bg:            #${colors.base00}e6;
        main-fg:            #${colors.base05}ff;
        main-br:            #${colors.base0B}ff;
        main-ex:            #${colors.base06}ff;
        select-bg:          #${colors.base0B}ff;
        select-fg:          #${colors.base00}ff;
        separatorcolor:     transparent;
        border-color:       transparent;
    }
  '';

  # HyDE style_1 の移植: 左に壁紙 + モード切替ボタン、右にアプリ一覧
  launcherTheme = ''
    ${colorDefs}

    // Main //
    window {
        height:                      33em;
        width:                       63em;
        transparency:                "real";
        fullscreen:                  false;
        enabled:                     true;
        cursor:                      "default";
        spacing:                     0em;
        padding:                     0em;
        border:                      2px;
        border-radius:               15px;
        border-color:                @main-br;
        background-color:            @main-bg;
    }
    mainbox {
        enabled:                     true;
        spacing:                     0em;
        padding:                     0em;
        orientation:                 horizontal;
        children:                    [ "dummywall" , "listbox" ];
        background-color:            transparent;
    }
    dummywall {
        spacing:                     0em;
        padding:                     0em;
        width:                       37em;
        expand:                      false;
        orientation:                 horizontal;
        children:                    [ "mode-switcher" , "inputbar" ];
        background-color:            transparent;
        background-image:            url("${wallThumbs}/wall-thmb.png", height);
    }

    // Modes //
    mode-switcher {
        orientation:                 vertical;
        enabled:                     true;
        width:                       3.8em;
        padding:                     9.2em 0.5em 9.2em 0.5em;
        spacing:                     1.2em;
        background-color:            transparent;
        background-image:            url("${wallThumbs}/wall-blur.png", height);
    }
    button {
        cursor:                      pointer;
        border-radius:               2em;
        background-color:            @main-bg;
        text-color:                  @main-fg;
    }
    button selected {
        background-color:            @main-fg;
        text-color:                  @main-bg;
    }

    // Inputs //
    inputbar {
        enabled:                     true;
        children:                    [ "entry" ];
        background-color:            transparent;
    }
    entry {
        enabled:                     false;
    }

    // Lists //
    listbox {
        spacing:                     0em;
        padding:                     2em;
        children:                    [ "dummy" , "listview" , "dummy" ];
        background-color:            transparent;
    }
    listview {
        enabled:                     true;
        spacing:                     0em;
        padding:                     0em;
        columns:                     1;
        lines:                       8;
        cycle:                       true;
        dynamic:                     true;
        scrollbar:                   false;
        layout:                      vertical;
        reverse:                     false;
        expand:                      false;
        fixed-height:                true;
        fixed-columns:               true;
        cursor:                      "default";
        background-color:            transparent;
        text-color:                  @main-fg;
    }
    dummy {
        background-color:            transparent;
    }

    // Elements //
    element {
        enabled:                     true;
        spacing:                     0.8em;
        padding:                     0.4em 0.4em 0.4em 1.5em;
        border-radius:               10px;
        cursor:                      pointer;
        background-color:            transparent;
        text-color:                  @main-fg;
    }
    element selected.normal {
        background-color:            @select-bg;
        text-color:                  @select-fg;
    }
    element-icon {
        size:                        2.8em;
        cursor:                      inherit;
        background-color:            transparent;
        text-color:                  inherit;
    }
    element-text {
        vertical-align:              0.5;
        horizontal-align:            0.0;
        cursor:                      inherit;
        background-color:            transparent;
        text-color:                  inherit;
    }

    // Error message //
    error-message {
        text-color:                  @main-fg;
        background-color:            @main-bg;
        text-transform:              capitalize;
        children:                    [ "textbox" ];
    }
    textbox {
        text-color:                  inherit;
        background-color:            inherit;
        vertical-align:              0.5;
        horizontal-align:            0.5;
    }
  '';

  # HyDE clipboard の移植: 上部に壁紙付き入力欄を持つ小型ドロップダウン
  # (dmenu 系の呼び出し全般で使うため、寸法を引数で変えられる)
  mkDropdownTheme = {
    width,
    height,
    lines,
  }: ''
    ${colorDefs}

    // Main //
    window {
        width:                       ${width};
        height:                      ${height};
        transparency:                "real";
        fullscreen:                  false;
        enabled:                     true;
        cursor:                      "default";
        spacing:                     0em;
        padding:                     0em;
        border:                      2px;
        border-radius:               15px;
        border-color:                @main-br;
        background-color:            @main-bg;
    }
    mainbox {
        enabled:                     true;
        spacing:                     0em;
        padding:                     0.5em;
        orientation:                 vertical;
        children:                    [ "wallbox" , "listbox" ];
        background-color:            transparent;
    }
    wallbox {
        spacing:                     0em;
        padding:                     0em;
        expand:                      false;
        orientation:                 horizontal;
        background-color:            transparent;
        background-image:            url("${wallThumbs}/wall-blur.png", width);
        children:                    [ "wallframe" , "inputbar" ];
    }
    wallframe {
        width:                       5em;
        spacing:                     0em;
        padding:                     0em;
        expand:                      false;
        background-color:            @main-bg;
        background-image:            url("${wallThumbs}/wall-quad.png", width);
    }

    // Inputs //
    inputbar {
        enabled:                     true;
        padding:                     0em;
        children:                    [ "entry" ];
        background-color:            @main-bg;
        expand:                      true;
    }
    entry {
        enabled:                     true;
        padding:                     1.8em;
        border-radius:               10px;
        text-color:                  @main-fg;
        background-color:            transparent;
        placeholder:                 "検索...";
        placeholder-color:           @main-ex;
    }

    // Lists //
    listbox {
        spacing:                     0em;
        padding:                     0em;
        orientation:                 vertical;
        children:                    [ "dummy" , "listview" , "dummy" ];
        background-color:            transparent;
    }
    listview {
        enabled:                     true;
        padding:                     0.5em;
        columns:                     1;
        lines:                       ${toString lines};
        cycle:                       true;
        fixed-height:                true;
        fixed-columns:               false;
        expand:                      false;
        cursor:                      "default";
        background-color:            transparent;
        text-color:                  @main-fg;
    }
    dummy {
        spacing:                     0em;
        padding:                     0em;
        background-color:            transparent;
    }

    // Elements //
    element {
        enabled:                     true;
        padding:                     0.5em;
        border-radius:               10px;
        cursor:                      pointer;
        background-color:            transparent;
        text-color:                  @main-fg;
    }
    element selected.normal {
        background-color:            @select-bg;
        text-color:                  @select-fg;
    }
    element-icon {
        size:                        1.5em;
        cursor:                      inherit;
        background-color:            transparent;
        text-color:                  inherit;
    }
    element-text {
        vertical-align:              0.5;
        horizontal-align:            0.0;
        cursor:                      inherit;
        background-color:            transparent;
        text-color:                  inherit;
    }
  '';
in {
  programs.rofi = {
    enable = true;
    terminal = "ghostty";
    # フォントと配色は stylix のスキームに追従させる (ターゲット自体は無効化済み)
    font = "${config.stylix.fonts.monospace.name} ${toString config.stylix.fonts.sizes.popups}";
    # -theme 指定なしの呼び出し (rofimoji など) が使う既定テーマ
    theme = "hyde-dropdown";
    extraConfig = {
      modi = "drun,run,window,filebrowser";
      show-icons = true;
      icon-theme = config.stylix.icons.dark;
      display-drun = "󰀻 ";
      display-run = " ";
      display-window = "󱂬 ";
      display-filebrowser = "󰉋 ";
      drun-display-format = "{name}";
      window-format = "{w} · {c} · {t}";
    };
  };

  # rofi は ~/.local/share/rofi/themes/ を名前付きテーマとして検索する
  # (キーバインド側からは `-theme hyde-launcher` のように名前で指定)
  xdg.dataFile = {
    "rofi/themes/hyde-launcher.rasi".text = launcherTheme;
    "rofi/themes/hyde-dropdown.rasi".text = mkDropdownTheme {
      width = "25em";
      height = "30em";
      lines = 11;
    };
    "rofi/themes/hyde-keybinds.rasi".text = mkDropdownTheme {
      width = "52em";
      height = "36em";
      lines = 15;
    };
  };
}
