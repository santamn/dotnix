# KDE Connect (スマートフォン連携)
# ファイアウォールの開放を伴うためシステム側で有効化する
# (トレイ常駐は Home Manager 側の services.kdeconnect が行う)
{...}: {
  programs.kdeconnect.enable = true;
}
