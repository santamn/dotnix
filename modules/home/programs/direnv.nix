# direnv: プロジェクトごとに devShell を自動で切り替える
# (.envrc と flake.nix を置いたディレクトリに cd すると開発環境が有効になる)
{...}: {
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
    nix-direnv.enable = true; # devShell の評価結果をキャッシュして高速化
  };
}
