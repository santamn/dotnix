-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

-- 中クリックペーストを無効化
-- ノーマル(n), 挿入(i), ビジュアル(v), コマンドライン(c) モードを対象
vim.keymap.set({ "n", "i", "v", "c" }, "<MiddleMouse>", "<Nop>", { silent = true })
vim.keymap.set({ "n", "i", "v", "c" }, "<2-MiddleMouse>", "<Nop>", { silent = true })
vim.keymap.set({ "n", "i", "v", "c" }, "<3-MiddleMouse>", "<Nop>", { silent = true })
vim.keymap.set({ "n", "i", "v", "c" }, "<4-MiddleMouse>", "<Nop>", { silent = true })
