{...}: {
  programs.ssh = {
    enable = true;

    # よく使うホストの設定
    matchBlocks = {
      "github.com" = {
        identityFile = "~/.ssh/github";
        user = "git";
      };
    };
  };
}
