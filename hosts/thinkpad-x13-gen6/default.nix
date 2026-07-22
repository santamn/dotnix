# ThinkPad X13 Gen 6 のホスト固有設定
# 全ホスト共通の設定は modules/nixos/ にあり、ここにはこのマシンでしか
# 意味を持たない設定 (ハードウェア構成・バッテリー閾値など) だけを置く
{inputs, ...}: {
  imports = [
    ./hardware-configuration.nix # nixos-generate-config が生成したハードウェア設定

    # nixos-hardware によるハードウェア別チューニング
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  # ThinkPad のバッテリー充電閾値 (寿命を延ばすため 40-80% の間で運用する)
  services.tlp.settings = {
    START_CHARGE_THRESH_BAT0 = 40;
    STOP_CHARGE_THRESH_BAT0 = 80;
  };

  # 最初にこのマシンへ NixOS をインストールしたときのバージョン。
  # アップグレードしても変更してはいけない (ステートフルなデータの互換性維持に使われる)
  system.stateVersion = "25.05";
}
