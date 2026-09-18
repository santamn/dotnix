# このリポジトリ (flake) の作業ツリーの置き場所を宣言するオプション
#
# Neovim の設定で使っているハードリンクについては作業ツリーの実体を指す必要がある。
# その場所は Nix からは知りようがないため、規約として持つ。
{
  lib,
  config,
  ...
}: {
  options.dotfiles.path = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/dotnix";
    example = "/home/santamn/src/dotnix";
    description = "dotnix リポジトリを clone してある場所 (nix store の外にある実体)";
  };
}
