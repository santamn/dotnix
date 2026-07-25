{...}: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # よく使うホストの設定
    # 属性名がそのまま Host パターンになり、値は ssh_config(5) のディレクティブ名で書く
    settings."github.com" = {
      IdentityFile = "~/.ssh/github";
      User = "git";
    };
  };
}
