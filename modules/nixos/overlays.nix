# nixpkgs へのオーバーレイ適用
{inputs, ...}: {
  nixpkgs.overlays = [
    # pkgs.firefoxAddons.* を提供する (Zen Browser の拡張機能インストールに使用)
    inputs.nix-firefox-addons.overlays.default
  ];
}
