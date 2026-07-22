# ネットワーク
{...}: {
  networking.networkmanager.enable = true;

  # SSH サーバ (ファイアウォールで 22 番を開けている)
  services.openssh.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22 # SSH
    ];
    allowedUDPPorts = [
      # DHCP クライアント
      68
      546
    ];
  };
}
