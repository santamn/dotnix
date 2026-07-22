# Git とその周辺ツール
{...}: {
  programs.git = {
    enable = true;
    userName = "santamn";
    userEmail = "cle.neige@gmail.com";
  };

  # diff の見た目を改善する delta
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
}
