# direnv: プロジェクトごとに devShell を自動で切り替える
{...}: {
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
    nix-direnv.enable = true; # devShell の評価結果をキャッシュして高速化
  };
}
