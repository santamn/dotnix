# hydenix のシステムモジュールをどこまで使うかの設定
{...}: {
  hydenix = {
    enable = true;
    # boot.kernelPackages が modules/nixos/boot.nix と二重定義になりビルドが落ちるため無効化
    boot.enable = false;
    # Steam(Proton GE)と lutris と wine staging、gamescope、コントローラ用ドライバ一式
    gaming.enable = true;
  };
}
