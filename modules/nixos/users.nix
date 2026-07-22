# ユーザアカウント
{pkgs, ...}: {
  users.users.santamn = {
    isNormalUser = true;
    # 新しいマシンの初回起動用パスワード。初回ログイン後に必ず `passwd` で変更すること
    # (既にユーザが存在するマシンでは無視される)
    initialPassword = "changeme";
    extraGroups = [
      "wheel" # sudo
      "networkmanager"
      "video" # 画面輝度の操作
      "docker"
    ];
    shell = pkgs.zsh; # ログインシェルは zsh (対話シェルは zsh から nushell に切り替わる)
  };

  # zsh をシステムに登録 (/etc/shells への追加など)
  programs.zsh.enable = true;
}
