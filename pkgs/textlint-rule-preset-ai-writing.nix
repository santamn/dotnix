# AI が書いた文章の構造 (リストの形、見出しの強調、コロンの使い方) を検出する textlint プリセット
# ai-words-ja が単語を見るのに対し、こちらは構造を見る。作者自身が補完関係だと書いている
#
# .textlintrc でのルール名はスコープ付きの "@textlint-ja/preset-ai-writing" になる
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs,
  runCommand,
}:
buildNpmPackage (finalAttrs: {
  pname = "textlint-rule-preset-ai-writing";
  version = "1.7.0";

  # srcを取得した段階で package-lock.json を書き換え、Fetcher にも修正を反映させる
  src = runCommand "source" {} ''
    cp -R ${fetchFromGitHub {
      owner = "textlint-ja";
      repo = "textlint-rule-preset-ai-writing";
      tag = "v${finalAttrs.version}";
      hash = "sha256-mEi17KZLic5Uzr7NthAM47TqQsCUy6RyknBWB7tTZBc=";
    }} $out
    chmod -R +w $out

    substituteInPlace $out/package-lock.json \
      --replace-fail '"node_modules/zwitch": {' \
      '"node_modules/zwitch": {
      "resolved": "https://registry.npmjs.org/zwitch/-/zwitch-1.0.5.tgz",
      "integrity": "sha512-V50KMwwzqJV0NpZIZFwfOD5/lyny3WlSzRiXgA0G7VUnRlqttta1L6UQIHzd6EuBY/cHGfwTIck7w1yH6Q5zUw==",'
  '';

  npmDepsHash = "sha256-RgrbVG/j3sxSgs/lsBqUs6hdnQwKr9+ofj8BZJ1UARU=";
  # npmDepsFetcherVersion = 2;

  # npm のピア依存関係エラーやキャッシュ書き込みエラーを防ぐための安定化オプション
  # makeCacheWritable = true;
  # npmFlags = ["--legacy-peer-deps"];

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
