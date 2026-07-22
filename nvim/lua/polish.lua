-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

-- 中クリックペーストを無効化
-- ノーマル(n), 挿入(i), ビジュアル(v), コマンドライン(c) モードを対象
vim.keymap.set({ "n", "i", "v", "c" }, "<MiddleMouse>", "<Nop>", { silent = true })
vim.keymap.set({ "n", "i", "v", "c" }, "<2-MiddleMouse>", "<Nop>", { silent = true })
vim.keymap.set({ "n", "i", "v", "c" }, "<3-MiddleMouse>", "<Nop>", { silent = true })
vim.keymap.set({ "n", "i", "v", "c" }, "<4-MiddleMouse>", "<Nop>", { silent = true })

-- Tree-sitter ハイライトの有効化
-- パーサは Nix が ~/.local/share/nvim/site/parser に配置済み (nvim-treesitter.withAllGrammars)。
-- パーサが存在しないファイルタイプでは pcall が失敗し、従来のハイライトのままになる
vim.api.nvim_create_autocmd("FileType", {
  desc = "Enable Tree-sitter highlighting when a parser is available",
  callback = function(args) pcall(vim.treesitter.start, args.buf) end,
})
