# 自分の vim 設定を踏まえてコマンドを提案する CLI
#
# エージェントのハーネスを経由せず、Haiku へ単発の API コールを投げるだけ。
# vq.py が隣の config-summary.md を読むので、2つを同じディレクトリへ置いてから
# ラッパを作る (writers.writePython3Bin はスクリプト1ファイルしか store に置かない)
{
  python3,
  runCommand,
  makeWrapper,
  aiDir ? ../ai,
}: let
  python = python3.withPackages (ps: [ps.anthropic]);
in
  runCommand "vq" {
    nativeBuildInputs = [makeWrapper];
    meta = {
      description = "自分の vim 設定を踏まえてコマンドを提案する CLI";
      mainProgram = "vq";
    };
  } ''
    mkdir -p $out/libexec/vq $out/bin
    cp ${aiDir}/vq/vq.py $out/libexec/vq/vq.py
    cp ${aiDir}/vq/config-summary.md $out/libexec/vq/config-summary.md
    makeWrapper ${python}/bin/python3 $out/bin/vq \
      --add-flags "$out/libexec/vq/vq.py"
  ''
