# ブートローダとカーネル
{pkgs, ...}: {
  boot = {
    # デスクトップ用途向けにチューニングされた zen カーネルを使用
    kernelPackages = pkgs.linuxPackages_zen;

    loader = {
      systemd-boot = {
        enable = true;
        consoleMode = "auto";
        editor = false; # 起動時のカーネルパラメータ編集を無効化 (セキュリティ対策)
      };
      efi.canTouchEfiVariables = true;
    };

    # NTFS / exFAT の外部ストレージをマウントできるようにする
    supportedFilesystems = ["ntfs" "exfat"];
  };
}
