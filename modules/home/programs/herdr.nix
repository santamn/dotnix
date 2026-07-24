# herdr: AI コーディングエージェント用のターミナルマルチプレクサ: https://herdr.dev/
#
# tmux 風のワークスペース/タブ/ペイン管理に加えて、Claude Code などの
# エージェントの状態 (作業中・入力待ち・完了) をサイドバーで一覧できる。
# 「左にエディタ、右に AI」という VSCode 風の画面構成をターミナルで再現するには:
#
#   1. `herdr` を起動してワークスペースを作成 (プロジェクトのディレクトリで)
#   2. ペインを左右に分割し、左で `nvim`、右で `claude` などのエージェントを起動
#   3. Neovim からは <Leader>zf / <Leader>zl で右隣のエージェントに
#      ファイルパスや選択範囲を送れる (nvim/lua/plugins/herdr.lua)
{pkgs, ...}: {
  home.packages = [pkgs.herdr];
}
