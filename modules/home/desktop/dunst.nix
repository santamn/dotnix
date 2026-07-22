# 通知デーモン (dunst)
# 配色・フォントは stylix が自動設定する
{...}: {
  services.dunst = {
    enable = true;
    settings = {
      global = {
        origin = "top-right";
        offset = "(12, 12)";
        corner_radius = 10;
        gap_size = 6;
        frame_width = 1;
        # nushell のコマンド完了通知などで使う既定のタイムアウト
        timeout = 8;
      };
    };
  };
}
