# 通知デーモン (mako)
# 配色・フォントは stylix が自動設定する
{
  config,
  lib,
  ...
}: let
  colors = config.lib.stylix.colors;
in {
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
      # 音量・輝度通知 (hypr-osd) の進捗バーの色 (アクセント色を半透明で重ねる)
      # stylix の mako モジュールも progress-color を既定優先度で設定するため、衝突を避けて上書きする
      progress-color = lib.mkForce "over #${colors.base0B}66";
    };
  };
}
