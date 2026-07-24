# 通知デーモン (mako)
# 配色・フォントは stylix が自動設定する
{...}: {
  services.mako = {
    enable = true;
    settings = {
      anchor = "top-right";
      # 画面端から 12px (margin 6 + outer-margin 6)、通知同士の間隔は margin で確保
      margin = "6";
      outer-margin = "6";
      border-radius = 10;
      border-size = 1;
      # nushell のコマンド完了通知などで使う既定のタイムアウト (ミリ秒)
      default-timeout = 8000;
    };
  };
}
