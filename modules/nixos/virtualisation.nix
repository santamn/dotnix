# コンテナ実行環境 (Podman)
{pkgs, ...}: {
  virtualisation.docker.enable = false;
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    extraPackages = [pkgs.docker-compose];
  };
}
