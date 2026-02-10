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
