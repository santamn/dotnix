# 自分の vim 設定を踏まえてコマンドを提案する CLI
#
# エージェントのハーネスを経由せず、Haiku へ単発の API コールを投げるだけ。
# config-summary.md は go:embed でバイナリに入るので、ラッパは要らない
{
  buildGoModule,
  go_1_26,
}:
buildGoModule.override {go = go_1_26;} {
  pname = "vq";
  version = "1.0.0";

  src = ../ai/vq;

  vendorHash = "sha256-3fnoG9P/FAWwiGENdvM7Od+7BBpli83SL5NIcQ0Nnpo=";

  meta = {
    description = "自分の vim 設定を踏まえてコマンドを提案する CLI";
    mainProgram = "vq";
  };
}
