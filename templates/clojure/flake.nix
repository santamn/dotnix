# Clojure プロジェクト用の devShell
# 使い方:
#   nix flake init -t ~/dotnix#clojure
#   direnv allow   # .envrc により、cd するだけで開発環境が有効になる
#   # deps.edn を書いて clj -M:repl などで REPL を起動する
{
  description = "Clojure development environment";

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
          jdk # Clojure の実行には JVM が要る
          clojure # clj / clojure コマンド
          clojure-lsp # LSP (astrolsp に clojure_lsp として登録済み)。cljfmt による整形も担当
          clj-kondo # リンタ。clojure-lsp が内部から呼ぶほかコマンドラインでも使える
          babashka # 起動の速いスクリプト用 Clojure
        ];
      };
    });
  };
}
