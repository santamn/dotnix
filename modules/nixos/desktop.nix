# デスクトップ環境 (Hyprland + SDDM) のシステム側設定
# ウィンドウマネージャ自体の設定 (キーバインドなど) は modules/home/desktop/ にある
{pkgs, ...}: {
  # Hyprland (Wayland コンポジタ)。ユーザごとの設定は Home Manager 側で行う
  programs.hyprland.enable = true;

  # Electron / Chromium アプリを Wayland ネイティブで動かす
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # ログイン画面 (SDDM + astronaut テーマ)
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
      theme = "sddm-astronaut-theme";
      extraPackages = with pkgs.kdePackages; [
        # astronaut テーマが必要とする Qt モジュール
        qtsvg
        qtmultimedia
        qtvirtualkeyboard
      ];
      settings = {
        Theme = {
          CursorTheme = "Bibata-Modern-Ice";
          CursorSize = "24";
        };
      };
    };
    defaultSession = "hyprland";
  };

  # スクリーンショット共有などに使われるデスクトップポータル
  # (Hyprland 用ポータルは programs.hyprland が自動で追加する)
  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };

  # 権限昇格ダイアログの基盤 (エージェントは Home Manager の hyprpolkitagent)
  security.polkit.enable = true;

  # SSH 鍵やアプリのパスワードを保存するキーリング
  services.gnome.gnome-keyring.enable = true;

  programs.dconf.enable = true; # GTK アプリの設定保存に必要
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  services = {
    upower.enable = true; # バッテリー情報 (waybar が参照)
    gvfs.enable = true; # ゴミ箱・MTP などの仮想ファイルシステム
    udisks2.enable = true; # リムーバブルメディアのマウント
    libinput.enable = true; # タッチパッド
  };

  environment.systemPackages = with pkgs; [
    # SDDM テーマとカーソル (ログイン画面はユーザ環境外なのでシステム側に置く)
    sddm-astronaut
    bibata-cursors

    # 基本ツール
    git
    wget
    curl
    jq
    psmisc # killall など
    pciutils # lspci
    usbutils # lsusb
    lm_sensors # 温度センサ
    brightnessctl # 画面輝度操作 (video グループのユーザが使用可)
    libnotify # notify-send
    wl-clipboard # Wayland クリップボード CLI
  ];
}
