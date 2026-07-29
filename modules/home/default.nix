# ユーザ環境 (Home Manager) 設定のエントリポイント
{...}: {
  imports = [
    ./dotfiles.nix
    ./packages.nix

    ./programs/direnv.nix
    ./programs/fcitx5.nix
    ./programs/ghostty.nix
    ./programs/git.nix
    ./programs/herdr.nix
    ./programs/kdeconnect.nix
    ./programs/neovim.nix
    ./programs/nushell.nix
    ./programs/ssh.nix
    ./programs/starship.nix
    ./programs/zen-browser.nix
    ./programs/zsh.nix
  ];
}
