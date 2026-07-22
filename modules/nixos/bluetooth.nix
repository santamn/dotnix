# Bluetooth
{...}: {
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        # A2DP (高音質オーディオ) などのプロファイルを有効化
        Enable = "Source,Sink,Media,Socket";
        # バッテリー残量表示などの実験的機能
        Experimental = true;
      };
    };
  };

  # Bluetooth 管理 GUI (トレイアプレットは Home Manager 側で起動)
  services.blueman.enable = true;
}
