{...}: {
  programs.neovim.enable = true;
  xdg.configFile."nvim" = {
    # AstroNvim の設定を ~/.config/nvim に配置
    # 変更は　 `home-manager switch` で反映
    source = ./AstroNvim;
    recursive = true;
  };
}
