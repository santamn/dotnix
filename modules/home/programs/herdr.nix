# herdr: AI コーディングエージェント用のターミナルマルチプレクサ: https://herdr.dev/
#
# 「左にエディタ、右に AI」 という VSCode 風の画面構成をターミナルで再現する方法:
#   1. `herdr` を起動してワークスペースを作成 (プロジェクトのディレクトリで)
#   2. ペインを左右に分割し、左で `nvim`、右で `claude` などのエージェントを起動
#  Neovim からは <Leader>zf / <Leader>zl で右隣のエージェントにファイルパスや選択範囲を送れる
{pkgs, ...}: {
  home.packages = [pkgs.herdr];
}
