# AI が書いた文章の構造 (リストの形、見出しの強調、コロンの使い方) を検出する textlint プリセット
# ai-words-ja が単語を見るのに対し、こちらは構造を見る。作者自身が補完関係だと書いている
#
# .textlintrc でのルール名はスコープ付きの "@textlint-ja/preset-ai-writing" になる
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  runCommand,
  cacert,
  nodejs,
}:
let
  # ロックされたバージョンは変えず、欠けている resolved/integrity だけをレジストリから補う
  fillLock = builtins.toFile "fill-lock.mjs" ''
    import { readFileSync, writeFileSync } from "node:fs";

    const file = "package-lock.json";
    const lock = JSON.parse(readFileSync(file, "utf8"));

    const targets = Object.entries(lock.packages).filter(
      ([key, pkg]) => key !== "" && !pkg.link && !pkg.inBundle && !(pkg.resolved && pkg.integrity),
    );

    const fetchJson = async (url) => {
      for (let i = 1; ; i++) {
        try {
          const res = await fetch(url);
          if (!res.ok) throw new Error(res.status + " " + url);
          return await res.json();
        } catch (e) {
          if (i >= 5) throw e;
          await new Promise((r) => setTimeout(r, 500 * i));
        }
      }
    };

    const fill = async ([key, pkg]) => {
      const name = pkg.name ?? key.slice(key.lastIndexOf("node_modules/") + "node_modules/".length);
      const url = "https://registry.npmjs.org/" + name.replace("/", "%2f") + "/" + pkg.version;
      const { tarball, integrity, shasum } = (await fetchJson(url)).dist;
      pkg.resolved ??= tarball;
      pkg.integrity ??= integrity ?? "sha1-" + Buffer.from(shasum, "hex").toString("base64");
    };

    const queue = [...targets];
    await Promise.all(
      Array.from({ length: 16 }, async () => {
        for (let t = queue.shift(); t; t = queue.shift()) await fill(t);
      }),
    );

    writeFileSync(file, JSON.stringify(lock, null, 2) + "\n");
  '';
in
buildNpmPackage (finalAttrs: {
  pname = "textlint-rule-preset-ai-writing";
  version = "1.7.0";

  src = fetchFromGitHub {
    owner = "textlint-ja";
    repo = "textlint-rule-preset-ai-writing";
    tag = "v${finalAttrs.version}";
    hash = "sha256-mEi17KZLic5Uzr7NthAM47TqQsCUy6RyknBWB7tTZBc=";
  };

  # upstream のロックは 361 件で resolved/integrity が欠けているので、補完済みのものに差し替える
  # postPatch は依存キャッシュの取得側にも渡されるため、両者で同じロックが使われる
  postPatch = ''
    cp ${finalAttrs.passthru.lockfile} package-lock.json
  '';

  npmDepsHash = "sha256-ViEm6a85CIdGDFmtA239slCXMGhRJsOgIB4YWov1BGI=";

  # ライブラリなので bin は作らない。textlint.withPackages が NODE_PATH で拾う
  dontNpmInstall = true;

  installPhase = ''
    runHook preInstall
    npm prune --omit=dev --no-save
    mkdir -p $out/lib/node_modules/@textlint-ja/${finalAttrs.pname}
    cp -r lib package.json node_modules $out/lib/node_modules/@textlint-ja/${finalAttrs.pname}/
    runHook postInstall
  '';

  passthru.lockfile =
    runCommand "${finalAttrs.pname}-${finalAttrs.version}-package-lock.json"
      {
        nativeBuildInputs = [ nodejs ];
        # node の fetch は Nix のサンドボックス内の証明書を見ないので明示する
        NODE_EXTRA_CA_CERTS = "${cacert}/etc/ssl/certs/ca-bundle.crt";
        # fixed-output にしてネットワークを許可する
        outputHashMode = "flat";
        outputHashAlgo = "sha256";
        outputHash = "sha256-qy9OtOexQpiXa8HLxWdZK9n74pPQy4vJyjVqDorsLec=";
      }
      ''
        cp ${finalAttrs.src}/package-lock.json package-lock.json
        chmod +w package-lock.json
        node ${fillLock}
        cp package-lock.json $out
      '';

  meta = {
    description = "AI が書いた文章の構造的な癖を検出する textlint プリセット";
    homepage = "https://github.com/textlint-ja/textlint-rule-preset-ai-writing";
    license = lib.licenses.mit;
    platforms = nodejs.meta.platforms;
  };
})
