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
  stdenv,
  cacert,
}: let
  version = "1.7.0";

  # 1. GitHubから元ソースを取得
  originalSrc = fetchFromGitHub {
    owner = "textlint-ja";
    repo = "textlint-rule-preset-ai-writing";
    tag = "v${version}";
    hash = "sha256-mEi17KZLic5Uzr7NthAM47TqQsCUy6RyknBWB7tTZBc=";
  };

  # 2. 不完全なロックファイルを破棄し、npmに再計算させて完全なロックファイルを生成する
  patchedLockfile = stdenv.mkDerivation {
    name = "package-lock.json";
    src = originalSrc;
    nativeBuildInputs = [nodejs cacert];

    buildPhase = ''
      # Nixのサンドボックス内ではHOMEディレクトリがないとnpmが落ちるため設定
      export HOME=$TMPDIR
      # 完全なパッケージツリーを再計算して package-lock.json を出力
      npm install --package-lock-only --ignore-scripts --legacy-peer-deps
    '';

    installPhase = ''
      # 生成されたファイルのみを出力する
      cp package-lock.json $out
    '';

    outputHashMode = "flat";
    outputHashAlgo = "sha256";
    # 【手順 1】まずはここを "" にしてビルドし、取得できたハッシュを貼る
    outputHash = "sha256-sJK5MfWT1Xm99Sfwq5YR2rUclJc6yUWzM39eVCFKIOA=";
  };

  # 3. 元ソースの package-lock.json を、上記で生成したものにすり替えた「新しいソース」を作る
  patchedSrc = runCommand "patched-source" {} ''
    cp -R ${originalSrc} $out
    chmod -R +w $out
    cp ${patchedLockfile} $out/package-lock.json
  '';
in
  buildNpmPackage rec {
    pname = "textlint-rule-preset-ai-writing";
    inherit version;

    # すり替え済みの完全なソースツリーを buildNpmPackage に渡す！
    src = patchedSrc;

    # 【手順 2】手順1のハッシュを埋めた後、ここがエラーになるので、取得できたハッシュを貼る
    npmDepsHash = "sha256-0b5xmbWz5rJQBHNTeGE1YF3DKxaHw3ZIqoMsD80Zks0=";

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
