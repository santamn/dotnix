# nixpkgs へのオーバーレイ適用
{
  lib,
  inputs,
  ...
}: {
  # hydenix 側 (inputs.hydenix.overlays.default) より後に適用されるよう mkAfter を付ける
  nixpkgs.overlays = lib.mkAfter [
    # pkgs.firefoxAddons.* を提供する (Zen Browser の拡張機能インストールに使用)
    inputs.nix-firefox-addons.overlays.default

    # nixpkgs の glaze が 8.0.0 に上がった一方で、
    # Hyprland 0.56.2 の CMakeLists は `find_package(glaze 7...<8)` で 7 系しか受け付けない。
    # 見つからないと FetchContent で git clone を試みてサンドボックス内でビルドが落ちるため、Hyprland 用の glaze だけ 7 系最終版に固定
    # TODO: Hyprland 本体は main でバージョン制約を撤去済みなので、0.56.3 以降に上がったらこのオーバーレイは削除する
    (_final: prev: {
      glaze-hyprland = prev.glaze-hyprland.overrideAttrs (_old: rec {
        version = "7.9.1";
        src = prev.fetchFromGitHub {
          owner = "stephenberry";
          repo = "glaze";
          tag = "v${version}";
          hash = "sha256-NRRq5MGF2f5PW0teYnq58ELzson+U6KHVPaY6r30KLA=";
        };
      });
    })
  ];
}
