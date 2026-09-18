# Go プロジェクト用の devShell
# 使い方:
#   nix flake init -t ~/dotnix#go
#   direnv allow   # .envrc により、cd するだけで開発環境が有効になる
#   go mod init example.com/myproject
{
  description = "Go development environment";

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
          go
          gopls # LSP (astrolsp の servers に登録済み)
          gotools # goimports を含む。conform が保存時に呼ぶ
          golangci-lint # リンタ。コマンドラインから使う
          delve # デバッガ。`dlv dap` を nvim-dap から繋げる
        ];
      };
    });
  };
}
