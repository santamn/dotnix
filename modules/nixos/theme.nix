# stylix によるテーマの一括管理
#
# hydenix/HyDE のテーマシステムの代替。1つのカラースキームと壁紙から
# GTK / Qt / waybar / rofi / ghostty / mako / hyprlock などの配色を統一生成する。
#
# - 配色: 壁紙 (stylix.image) から自動生成される
#   固定スキームに戻したい場合は base16Scheme に themes/ の yaml を指定する
#   (例: base16Scheme = ../../themes/decay-green.yaml;)
# - 壁紙: 好みの画像に変えるには stylix.image を差し替える
#
# 個別アプリでの微調整 (対象から外す等) は modules/home/theme.nix で行う
{pkgs, ...}: {
  stylix = {
    enable = true;
    polarity = "dark";

    # 壁紙 (nixpkgs 収録の NixOS 公式アートワーク)。配色はこの画像から自動生成される。
    # 手元の画像を使う場合はリポジトリに置いてそのパスを指定する
    image = pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath;

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.fira-code;
        name = "FiraCode Nerd Font";
      };
      sansSerif = {
        package = pkgs.noto-fonts-cjk-sans;
        name = "Noto Sans CJK JP";
      };
      serif = {
        package = pkgs.noto-fonts-cjk-serif;
        name = "Noto Serif CJK JP";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        terminal = 10; # 旧 ghostty 設定の font-size を踏襲
        applications = 11;
      };
    };

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
    };

    # Tela Circle (green) アイコンテーマ: HyDE の Decay Green が使っていたもの
    iconTheme = {
      enable = true;
      package = pkgs.tela-circle-icon-theme.override {colorVariants = ["green"];};
      dark = "Tela-circle-green-dark";
      light = "Tela-circle-green";
    };

    # ターミナルの背景透過 (旧 ghostty 設定の background-opacity を踏襲)
    opacity.terminal = 0.7;
  };
}
