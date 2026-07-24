-- LSP のセマンティックリネーム (textDocument/rename) を強化するプラグイン
-- 新しい名前を入力している間、バッファ内の全参照に改名結果がライブプレビューされる
-- (キーマップは astrolsp.lua の <Leader>lr に定義してある)
---@type LazySpec
return {
  "smjonas/inc-rename.nvim",
  cmd = "IncRename", -- :IncRename 実行時に遅延ロード
  opts = {},
}
