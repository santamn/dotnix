# Git とその周辺ツール
{...}: {
  programs.git = {
    enable = true;
    # settings は ~/.gitconfig の内容をそのまま表す (旧 userName / userEmail / extraConfig の統合先)
    settings.user = {
      name = "santamn";
      email = "cle.neige@gmail.com";
    };
  };

  # diff の見た目を改善する delta
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
}
