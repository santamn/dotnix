# ユーザ santamn の Home Manager 設定のエントリポイント
{
  config,
  inputs,
  ...
}: {
  imports = [
    # command-not-found の代替 (nix-index) と comma
    inputs.nix-index-database.homeModules.nix-index
    ../modules/home
  ];

  # この flake リポジトリの置き場所。Neovim 設定のシンボリックリンク先などに使う
  # (新しいマシンでもリポジトリは ~/dotnix に clone する前提)
  _module.args.nixConfigPath = "${config.home.homeDirectory}/dotnix";

  # Home Manager 自身を Home Manager で管理する
  programs.home-manager.enable = true;

  # 初回セットアップ時のバージョン。変更してはいけない
  home.stateVersion = "25.05";
}
