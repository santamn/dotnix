# タイムゾーン・ロケール・コンソールのキーボード設定
# 日本語入力 (fcitx5) は modules/home/programs/fcitx5.nix にある
{...}: {
  time.timeZone = "Asia/Tokyo";
  i18n.defaultLocale = "ja_JP.UTF-8";

  # CapsLock と Ctrl の入れ替え (Hyprland 側にも同じ設定があるが、
  # これは TTY コンソールと X 系アプリのための設定)
  services.xserver.xkb.options = "ctrl:swapcaps";
  console.useXkbConfig = true;
}
