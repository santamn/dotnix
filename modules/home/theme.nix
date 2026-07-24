# stylix のユーザ側調整
# 基本設定 (スキーム・フォント・壁紙) は modules/nixos/theme.nix にある
{...}: {
  stylix.targets = {
    # 以下は自前の設定で配色まで制御しているため、stylix の自動テーマを外す
    # (色は config.lib.stylix.colors 経由で同じスキームから取っている)
    hyprland.enable = false; # ボーダー色はスキーム色のグラデーションを自前設定
    hyprlock.enable = false; # ロック画面レイアウトは desktop/hyprlock.nix で定義
    waybar.enable = false; # スタイルは desktop/waybar.nix の CSS で定義

    # Neovim は AstroNvim 側のカラースキームを使う
    neovim.enable = false;

    # Firefox (Zen Browser) のテーマ対象プロファイル
    firefox.profileNames = ["default"];
  };
}
