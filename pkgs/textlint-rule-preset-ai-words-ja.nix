# AI が書いた日本語に出やすい単語と言い回しを検出する textlint プリセット
# nixpkgs に無いので自前でパッケージ化する
{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs,
  pnpm_10,
  fetchPnpmDeps,
  pnpmConfigHook,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "textlint-rule-preset-ai-words-ja";
  version = "1.2.1";

  src = fetchFromGitHub {
    owner = "p1ass";
    repo = "textlint-rule-preset-ai-words-ja";
    tag = "v${finalAttrs.version}";
    hash = "sha256-0QgNPVyheFdPLCLq6JJy5AFIJ5txr1TOvzJ2VFC2C0I=";
  };

  # TODO: NixOS 機でビルドし、エラーに出る正しい値へ差し替える
  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_10;
    fetcherVersion = 4;
    hash = lib.fakeHash;
  };

  nativeBuildInputs = [nodejs pnpmConfigHook pnpm_10];

  # TypeScript を lib/ へコンパイルする。package.json の main が lib/index.js を指す
  buildPhase = ''
    runHook preBuild
    pnpm build
    runHook postBuild
  '';

  # textlint.withPackages は NODE_PATH に lib/node_modules を並べる
  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/node_modules/${finalAttrs.pname}
    cp -r lib package.json node_modules $out/lib/node_modules/${finalAttrs.pname}/
    runHook postInstall
  '';

  meta = {
    description = "AI が書いた日本語に出てきやすい単語と言い回しを見つける textlint のプリセット";
    homepage = "https://github.com/p1ass/textlint-rule-preset-ai-words-ja";
    license = lib.licenses.mit;
    platforms = nodejs.meta.platforms;
  };
})
