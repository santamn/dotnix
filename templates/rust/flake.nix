# Rust プロジェクト用の devShell
# 使い方:
#   nix flake init -t ~/dotnix#rust
#   direnv allow   # .envrc により、cd するだけで開発環境が有効になる
{
  description = "Rust development environment";

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
          # Rust ツールチェーン一式
          rustc
          cargo
          rust-analyzer
          rustfmt
          clippy

          # デバッガ (rustaceanvim / nvim-dap が使用)
          vscode-extensions.vadimcn.vscode-lldb
        ];

        env = let
          codelldb = pkgs.vscode-extensions.vadimcn.vscode-lldb;
          ext = "${codelldb}/share/vscode/extensions/vadimcn.vscode-lldb";
        in {
          # rustaceanvim (nvim/lua/plugins/rustaceanvim.lua) がデバッガを
          # 見つけるための環境変数 (Linux 用。macOS では liblldb.dylib になる点に注意)
          CODELLDB_PATH = "${ext}/adapter/codelldb";
          LIBLLDB_PATH = "${ext}/lldb/lib/liblldb.so";

          # rust-analyzer が標準ライブラリのソースを参照するための設定
          RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
        };
      };
    });
  };
}
