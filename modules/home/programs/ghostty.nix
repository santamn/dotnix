# ターミナルエミュレータ (ghostty)
# 配色・フォント・背景透過は stylix が自動設定する (modules/nixos/theme.nix)
{...}: {
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
  };
}
