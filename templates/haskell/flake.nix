# Haskell プロジェクト用の devShell
# 使い方:
#   nix flake init -t ~/dotnix#haskell
#   direnv allow   # .envrc により、cd するだけで開発環境が有効になる
#   cabal init
#
# NOTE: haskell-language-server は GHC のバージョンと組で動く。
#       GHC を変える場合は pkgs.haskell.packages.ghcXXX 側から両方取ること。
{
  description = "Haskell development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
    forAllSystems = f:
      nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
  in {
    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          ghc
          cabal-install
          haskell-language-server # LSP (astrolsp には hls という名前で登録済み)
          hlint # リンタ。コマンドラインから使う
          ormolu # フォーマッタ。HLS 経由で保存時に走る
        ];
      };
    });
  };
}
