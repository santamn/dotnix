# オーディオ (PipeWire)
{pkgs, ...}: {
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true; # PulseAudio 互換レイヤー
    wireplumber.enable = true;
  };

  # オーディオプロセスにリアルタイム優先度を与える (音切れ防止)
  security.rtkit.enable = true;

  environment.systemPackages = with pkgs; [
    pavucontrol # 音量・デバイス管理 GUI
    pamixer # 音量操作 CLI
    playerctl # メディアプレイヤー操作 CLI (再生/停止キー用)
  ];
}
