# このリポジトリ (flake) の作業ツリーの置き場所を宣言するオプション
#
# nix store の中にあるのはリポジトリの不変なコピーなので、
# 「編集したら rebuild なしで即反映される」設定 (mkOutOfStoreSymlink) は
# 作業ツリーの実体を指す必要がある。その場所は Nix からは知りようがないため規約として持つ
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
