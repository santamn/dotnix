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

  # 依存関係をフェッチする「前」に修正を反映させる完璧なアプローチ
  src = runCommand "source" {} ''
    cp -R ${
      fetchFromGitHub {
        owner = "textlint-ja";
        repo = "textlint-rule-preset-ai-writing";
        tag = "v${finalAttrs.version}";
        hash = "sha256-mEi17KZLic5Uzr7NthAM47TqQsCUy6RyknBWB7tTZBc=";
      }
    } $out
    chmod -R +w $out

    substituteInPlace $out/package-lock.json \
      --replace-fail '"node_modules/zwitch": {' \
      '"node_modules/zwitch": {
      "resolved": "https://registry.npmjs.org/zwitch/-/zwitch-1.0.5.tgz",
      "integrity": "sha512-V50KMwwzqJV0NpZIZFwfOD5/lyny3WlSzRiXgA0G7VUnRlqttta1L6UQIHzd6EuBY/cHGfwTIck7w1yH6Q5zUw==",' \
      --replace-warn '"node_modules/yocto-queue": {' \
      '"node_modules/yocto-queue": {
      "resolved": "https://registry.npmjs.org/yocto-queue/-/yocto-queue-0.1.0.tgz",
      "integrity": "sha512-rVksvsnNCdJ/ohGc6xgPwyN8eheCxsiLM8mxuE/t/mOVqJewPuO1miLpTHQiRgTKCLexL4MeAFVagts7HmNZ2Q==",' \
      --replace-warn '"node_modules/yn": {' \
      '"node_modules/yn": {
      "resolved": "https://registry.npmjs.org/yn/-/yn-3.1.1.tgz",
      "integrity": "sha512-Ux4ygGWsu2c7isFWe8Yu1YluJmqVhxqK2cLXNQA5AcC3QfbGNpM7fu0Y8b/z16pXLnFxZYvWhd3fhBY9DLmC6Q==",'
  '';

  npmDepsHash = lib.fakeHash;
  npmDepsFetcherVersion = 2;
  makeCacheWritable = true;
  npmFlags = ["--legacy-peer-deps"];

  # 通常のCLIツールとは異なり、プラグインとして特定の階層に配置するための処理
  dontNpmInstall = true;
  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/node_modules/@textlint-ja/${finalAttrs.pname}
    cp -r lib package.json node_modules $out/lib/node_modules/@textlint-ja/${finalAttrs.pname}/
    runHook postInstall
  '';

  meta = {
    description = "AI が書いた文章の構造的な癖を検出する textlint プリセット";
    homepage = "https://github.com/textlint-ja/textlint-rule-preset-ai-writing";
    license = lib.licenses.mit;
    platforms = nodejs.meta.platforms;
  };
})
