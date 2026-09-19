# プロジェクトの Go バージョンに合わせた最新の書き方をエージェントへ渡す CLI
# use-modern-go skill がこのバイナリを呼ぶ
{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule (finalAttrs: {
  pname = "go-modern-guidelines";
  version = "1.1.1";

  src = fetchFromGitHub {
    owner = "JetBrains";
    repo = "go-modern-guidelines";
    rev = "155dc7ca10da5e1f6c841503086957b1b37f5815";
    hash = "sha256-Gm96NA55N2+YHH/3NW+qAeiqYkrsZeBT8EVgLP0Lx34=";
  };

  # TODO: NixOS 機でビルドし、エラーに出る正しい値へ差し替える
  vendorHash = lib.fakeHash;

  # skill 本体も同梱する。ai-agents.nix が $out/share/skills から張る
  postInstall = ''
    mkdir -p $out/share/skills
    cp -r ${finalAttrs.src}/plugin/skills/use-modern-go $out/share/skills/
    chmod -R u+w $out/share/skills
  '';

  meta = {
    description = "Help AI coding agents write modern Go";
    homepage = "https://github.com/JetBrains/go-modern-guidelines";
    license = lib.licenses.asl20;
    mainProgram = "go-modern-guidelines";
  };
})
