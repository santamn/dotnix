# Home Manager を NixOS モジュールとして組み込む設定
{inputs, ...}: {
  home-manager = {
    useGlobalPkgs = true; # システムと同じ nixpkgs (overlay / allowUnfree 込み) を使う
    useUserPackages = true;
    extraSpecialArgs = {inherit inputs;};

    # ユーザごとの Home Manager 設定は home/<ユーザ名>.nix に置く
    users.santamn = import ../../home/santamn.nix;
  };
}
