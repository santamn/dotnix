# AI が書いた文章の構造 (リストの形、見出しの強調、コロンの使い方) を検出する textlint プリセット
# ai-words-ja が単語を見るのに対し、こちらは構造を見る。作者自身が補完関係だと書いている
#
# .textlintrc でのルール名はスコープ付きの "@textlint-ja/preset-ai-writing" になる
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs,
}:
buildNpmPackage (finalAttrs: {
  pname = "textlint-rule-preset-ai-writing";
  version = "1.7.0";

  src = fetchFromGitHub {
    owner = "textlint-ja";
    repo = "textlint-rule-preset-ai-writing";
    tag = "v${finalAttrs.version}";
    hash = "sha256-mEi17KZLic5Uzr7NthAM47TqQsCUy6RyknBWB7tTZBc=";
  };

  # TODO: NixOS 機でビルドし、エラーに出る正しい値へ差し替える
  npmDepsHash = lib.fakeHash;

  # ライブラリなので bin は作らない。textlint.withPackages が NODE_PATH で拾う
  dontNpmInstall = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/node_modules/@textlint-ja/${finalAttrs.pname}
    cp -r lib package.json node_modules \
      $out/lib/node_modules/@textlint-ja/${finalAttrs.pname}/
    runHook postInstall
  '';

  meta = {
    description = "AI が書いた文章の構造的な癖を検出する textlint プリセット";
    homepage = "https://github.com/textlint-ja/textlint-rule-preset-ai-writing";
    license = lib.licenses.mit;
    platforms = nodejs.meta.platforms;
  };
})
