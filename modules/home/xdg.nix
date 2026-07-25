# XDG ユーザディレクトリと既定アプリケーション
{config, ...}: {
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    # XDG_DESKTOP_DIR などをセッション環境変数としても設定する
    # (26.05 で既定値が false に変わるため明示。スクリプトからの参照を壊さないよう true を維持)
    setSessionVariables = true;
    desktop = "${config.home.homeDirectory}/Desktop";
    documents = "${config.home.homeDirectory}/Documents";
    download = "${config.home.homeDirectory}/Downloads";
    music = "${config.home.homeDirectory}/Music";
    pictures = "${config.home.homeDirectory}/Pictures";
    publicShare = "${config.home.homeDirectory}/Public";
    templates = "${config.home.homeDirectory}/Templates";
    videos = "${config.home.homeDirectory}/Videos";
  };

  # テキスト系ファイルは Neovim で開く (ブラウザ関係は programs/zen-browser.nix)
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/plain" = ["nvim.desktop"];
      "text/markdown" = ["nvim.desktop"];
      "application/json" = ["nvim.desktop"];
      "application/x-shellscript" = ["nvim.desktop"];
    };
  };
}
