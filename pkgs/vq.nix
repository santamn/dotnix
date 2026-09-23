# 自分の vim 設定を踏まえてコマンドを提案する CLI
#
# エージェントのハーネスを経由せず、Haiku へ単発の API コールを投げるだけ。
# config-summary.md は go:embed でバイナリに入るので、ラッパは要らない
{buildGoModule}:
buildGoModule {
  pname = "vq";
  version = "1.0.0";

  src = ../ai/vq;

  vendorHash = "sha256-8Y0GdcXLASsXyhgWLl7Z23Khiu6At10geetNeXliQkY=";

  meta = {
    description = "自分の vim 設定を踏まえてコマンドを提案する CLI";
    mainProgram = "vq";
  };
}
