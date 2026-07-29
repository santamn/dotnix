# 全ホスト共通のシステム設定のエントリポイント
{...}: {
  imports = [
    ./audio.nix
    ./bluetooth.nix
    ./boot.nix
    ./fingerprint.nix
    ./fonts.nix
    ./home-manager.nix
    ./kdeconnect.nix
    ./locale.nix
    ./network.nix
    ./nix-ld.nix
    ./nix.nix
    ./overlays.nix
    ./power.nix
    ./users.nix
    ./virtualisation.nix
  ];
}
