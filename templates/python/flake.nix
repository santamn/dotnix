# Python プロジェクト用の devShell
# 使い方:
#   nix flake init -t ~/dotnix#python
#   direnv allow   # .envrc により、cd するだけで開発環境が有効になる
#   uv init && uv add <package>
#
# パッケージの管理は uv に任せ、Nix はインタプリタと開発ツールだけを供給する。
# uv が作る .venv を basedpyright が見つけるので、追加の設定は要らない。
{
  description = "Python development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    systems = ["x86_64-linux" "aarch64-darwin"];
    forAllSystems = f:
      nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
  in {
    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          python3
          uv # 依存関係と仮想環境の管理
          basedpyright # LSP (astrolsp の servers に登録済み)
          ruff # リンタ兼フォーマッタ。conform が保存時に呼ぶ
        ];

        env = {
          # uv が Nix の Python を使い、自前でインタプリタを落としてこないようにする
          UV_PYTHON = "${pkgs.python3}/bin/python3";
          UV_PYTHON_DOWNLOADS = "never";
        };
      };
    });
  };
}
