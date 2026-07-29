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
      font-family = "FiraCode Nerd Font";
    };
  };
}
