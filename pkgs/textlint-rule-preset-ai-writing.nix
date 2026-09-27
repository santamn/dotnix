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
}: let
  version = "1.7.0";

  originalSrc = fetchFromGitHub {
    owner = "textlint-ja";
    repo = "textlint-rule-preset-ai-writing";
    tag = "v${version}";
    hash = "sha256-mEi17KZLic5Uzr7NthAM47TqQsCUy6RyknBWB7tTZBc=";
  };

  # package-lock.json 内で resolved が欠落している全依存関係に npm レジストリの標準 URL を補完する
  patchedSrc = runCommand "patched-source" {nativeBuildInputs = [nodejs];} ''
    cp -R ${originalSrc}$out
    chmod -R +w $out

    node -e '
      const fs = require("fs");
      const lockPath = "$out/package-lock.json";
      const lock = JSON.parse(fs.readFileSync(lockPath, "utf8"));

      if (lock.packages) {
        for (const [pkgPath, pkg] of Object.entries(lock.packages)) {
          // version が存在するのに resolved がない項目をすべて自動補完
          if (pkgPath && pkg.version && !pkg.resolved && !pkg.link) {
            const name = pkgPath.replace(/^.*node_modules\//, "");
            let url;
            if (name.startsWith("@")) {
              const [scope, subName] = name.split("/");
              url = `https://registry.npmjs.org/\${scope}/\${subName}/-/\${subName}-\${pkg.version}.tgz`;
            } else {
              url = `https://registry.npmjs.org/\${name}/-/\${name}-\${pkg.version}.tgz`;
            }
            pkg.resolved = url;
          }
        }
      }

      fs.writeFileSync(lockPath, JSON.stringify(lock, null, 2));
    '
  '';
in
  buildNpmPackage rec {
    pname = "textlint-rule-preset-ai-writing";
    inherit version;

    src = patchedSrc;

    # 1. まずはここを空（""）にしてビルドし、出たハッシュを貼り付ける
    npmDepsHash = "";

    npmDepsFetcherVersion = 2;
    makeCacheWritable = true;
    npmFlags = ["--legacy-peer-deps"];

    dontNpmInstall = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/node_modules/@textlint-ja/${pname}
      cp -r lib package.json node_modules \
        $out/lib/node_modules/@textlint-ja/${pname}/
      runHook postInstall
    '';

    meta = {
      description = "AI が書いた文章の構造的な癖を検出する textlint プリセット";
      homepage = "https://github.com/textlint-ja/textlint-rule-preset-ai-writing";
      license = lib.licenses.mit;
      platforms = nodejs.meta.platforms;
    };
  }
