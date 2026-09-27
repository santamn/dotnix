# AI が書いた文章の構造 (リストの形、見出しの強調、コロンの使い方) を検出する textlint プリセット
# ai-words-ja が単語を見るのに対し、こちらは構造を見る。作者自身が補完関係だと書いている
#
# .textlintrc でのルール名はスコープ付きの "@textlint-ja/preset-ai-writing" になる
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs,
  stdenv,
  cacert, # npmのHTTPS通信のために必要
}: let
  version = "1.7.0";
  src = fetchFromGitHub {
    owner = "textlint-ja";
    repo = "textlint-rule-preset-ai-writing";
    tag = "v${version}";
    hash = "sha256-mEi17KZLic5Uzr7NthAM47TqQsCUy6RyknBWB7tTZBc=";
  };

  # Nix 内でネットワークに繋ぎ、完全な package-lock.json を自動生成する
  patchedLockfile = stdenv.mkDerivation {
    name = "patched-package-lock.json";
    inherit src;
    nativeBuildInputs = [nodejs];
    buildInputs = [cacert]; # httpsの証明書がないとnpmがエラーになるため

    # 既存の不完全な package-lock.json をベースに欠落データを補完する
    buildPhase = ''
      npm install --package-lock-only --ignore-scripts
    '';

    installPhase = ''
      cp package-lock.json $out
    '';

    outputHashMode = "flat";
    outputHashAlgo = "sha256";
    outputHash = "sha256-sJK5MfWT1Xm99Sfwq5YR2rUclJc6yUWzM39eVCFKIOA=";
  };
in
  buildNpmPackage rec {
    pname = "textlint-rule-preset-ai-writing";
    inherit version src;

    # ビルド開始直後に、上で自動生成した健全なロックファイルで上書きする
    postPatch = ''
      cp ${patchedLockfile} package-lock.json
    '';

    # 手順2: outputHashを埋めた後、次にここを空（""）にしてハッシュを取得し、貼る
    npmDepsHash = lib.fakeHash;

    meta = {
      description = "AI が書いた文章の構造的な癖を検出する textlint プリセット";
      homepage = "https://github.com/textlint-ja/textlint-rule-preset-ai-writing";
      license = lib.licenses.mit;
      platforms = nodejs.meta.platforms;
    };
  }
