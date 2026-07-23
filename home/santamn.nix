# ユーザ santamn の Home Manager 設定のエントリポイント
{inputs, ...}: {
  imports = [
    # command-not-found の代替 (nix-index) と comma
    inputs.nix-index-database.homeModules.nix-index
    ../modules/home
  ];

  # Home Manager 自身を Home Manager で管理する
  programs.home-manager.enable = true;

  # 初回セットアップ時のバージョン。変更してはいけない
  home.stateVersion = "25.05";
}
