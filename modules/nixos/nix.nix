# Nix 自体とパッケージ全般の設定
{...}: {
  # Slack / Zoom / Spotify などの非フリーソフトを許可
  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];

      # ストアの重複ファイルを自動でハードリンク化してディスクを節約
      auto-optimise-store = true;

      # GitHub の tarball ダウンロードがネットワークによっては途中で切れることが
      # あるため、フェッチを堅牢にする (リトライ回数を増やす)
      download-attempts = 10;
      connect-timeout = 10;
      stalled-download-timeout = 60;
    };

    # 古い世代を毎週自動削除
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}
