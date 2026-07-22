# アプリランチャー (rofi)
# 配色・フォントは stylix が自動でテーマを生成する
{...}: {
  programs.rofi = {
    enable = true;
    terminal = "ghostty";
    extraConfig = {
      modi = "drun,run,window,filebrowser";
      show-icons = true;
      display-drun = "󰀻 ";
      display-window = "󱂬 ";
      display-filebrowser = "󰉋 ";
      drun-display-format = "{name}";
      window-format = "{w} · {c} · {t}";
    };
  };
}
