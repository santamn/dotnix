# デスクトップセッションの常駐サービスと周辺ツール
{pkgs, ...}: {
  # 壁紙デーモン (壁紙画像は stylix が設定する)
  services.hyprpaper.enable = true;

  # polkit 認証ダイアログ (sudo 相当の GUI プロンプト)
  services.hyprpolkitagent.enable = true;

  # クリップボード履歴 (Super+V で rofi から呼び出す)
  services.cliphist = {
    enable = true;
    allowImages = true;
  };

  # リムーバブルメディアの自動マウント
  services.udiskie.enable = true;

  # ネットワークと Bluetooth のトレイアプレット
  services.network-manager-applet.enable = true;
  services.blueman-applet.enable = true;

  # ログアウト・電源メニュー (Ctrl+Alt+Delete)
  programs.wlogout.enable = true;

  home.packages = with pkgs; [
    hyprshot # スクリーンショット (Super+P)
    hyprpicker # カラーピッカー (Super+Shift+P)
    satty # スクリーンショットの注釈付け
    rofimoji # 絵文字ピッカー (Super+,)
    wtype # rofimoji が絵文字を入力するのに使用
    wl-clip-persist # コピー元アプリ終了後もクリップボードを保持
  ];

  # クリップボードの内容をコピー元終了後も保持する
  systemd.user.services.wl-clip-persist = {
    Unit = {
      Description = "Keep Wayland clipboard even after programs close";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Install.WantedBy = ["graphical-session.target"];
    Service = {
      ExecStart = "${pkgs.wl-clip-persist}/bin/wl-clip-persist --clipboard regular";
      Restart = "on-failure";
    };
  };
}
