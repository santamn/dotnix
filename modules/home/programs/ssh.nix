{...}: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # よく使うホストの設定
    matchBlocks = {
      "github.com" = {
        identityFile = "~/.ssh/github";
        user = "git";
      };
    };
  };
}
