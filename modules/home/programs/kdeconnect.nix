# KDE Connect のユーザ側デーモンとトレイ常駐
# (ファイアウォール開放はシステム側 modules/nixos/kdeconnect.nix)
{...}: {
  services.kdeconnect = {
    enable = true;
    indicator = true; # システムトレイアイコンを有効化
  };
}
