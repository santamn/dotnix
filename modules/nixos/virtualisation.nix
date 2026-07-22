# コンテナ実行環境 (Docker & Podman)
{...}: {
  virtualisation.docker.enable = true;
  virtualisation.podman = {
    enable = true;
    dockerCompat = false; # docker コマンドは本物の Docker を使う
  };
}
