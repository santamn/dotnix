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

  npmDepsHash = lib.fakeHash;

  # upstream の lockfile で欠落している zwitch の取得情報を補う
  postPatch = ''
    node -e '
      const fs = require("fs");
      const path = "package-lock.json";
      const lockfile = JSON.parse(fs.readFileSync(path, "utf8"));
      const dependency = lockfile.packages["node_modules/zwitch"];
      dependency.resolved = "https://registry.npmjs.org/zwitch/-/zwitch-1.0.5.tgz";
      dependency.integrity = "sha512-V50KMwwzqJV0NpZIZFwfOD5/lyny3WlSzRiXgA0G7VUnRlqttta1L6UQIHzd6EuBY/cHGfwTIck7w1yH6Q5zUw==";
      fs.writeFileSync(path, JSON.stringify(lockfile, null, 2) + "\n");
    '
  '';

  # lockfile に resolved がない依存の packument もキャッシュする
  npmDepsFetcherVersion = 2;

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
