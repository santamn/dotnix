# 個別モジュールを持たないパッケージ類
{pkgs, ...}: {
  home.packages = with pkgs; [
    # --- CLI tools ---
    wine64 # Windows アプリケーション互換レイヤー
    fastfetch # システム情報表示
    trash-cli # ゴミ箱操作 CLI

    # --- Alternative Commands ---
    bat # cat
    bottom # top alternative
    eza # ls
    fd # find
    fzf # interactive file search
    ripgrep # grep

    # --- Desktop Utilities ---
    kdePackages.dolphin # ファイルマネージャ
    kdePackages.ark # アーカイバ

    # --- Daily Software ---
    slack
    zoom-us
    thunderbird
    signal-desktop
    vesktop # Discord クライアント
    spotify
  ];
}
