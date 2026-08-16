# ターミナルエミュレータ (ghostty)
# hydenix.hm.terminals は kitty のみを対象とするため、配色・フォントはここで個別に設定する
{...}: {
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      theme = "TokyoNight Moon";
      background-opacity = "0.70";

      font-size = 10;
      # FiraCode に日本語グリフが無いため、明示しないと中華フォント Noto Sans CJK SC になる
      font-family = [
        "FiraCode Nerd Font"
        "Noto Sans Mono CJK JP"
      ];
    };
  };
}
