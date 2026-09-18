# Nix 自体とパッケージ全般の設定
{config, ...}: {
  # Slack / Zoom / Spotify などの非フリーソフトを許可
  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];

      # ストアの重複ファイルを自動でハードリンク化してディスクを節約
      auto-optimise-store = true;

      # GitHub 上の tarball （デスクトップのテーマなど）のダウンロードが途中で切れることがあるため、リトライ回数を増やす
      download-attempts = 10;
      connect-timeout = 10;
      stalled-download-timeout = 60;
    };
  };

  # nh (nix helper): rebuild や GC を使いやすくするラッパー CLI
  programs.nh = {
    enable = true;
    flake = config.home-manager.users.santamn.dotfiles.path;

    # --- Garbage Collection ---
    # 古い世代 (30日超) を毎日自動削除
    # nix.gc と違ってユーザープロファイルや gcroots になっている result シンボリックリンクもまとめて削除する
    clean = {
      enable = true;
      dates = "daily";
      extraArgs = "--keep-since 30d";
    };
  };
}
