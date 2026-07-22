# 電源管理 (ノート PC 向け)
# バッテリー充電閾値などのハードウェア固有値は hosts/<name>/default.nix に置く
{lib, ...}: {
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    };
  };

  # TLP と power-profiles-daemon は競合するため無効化
  services.power-profiles-daemon.enable = lib.mkForce false;
}
