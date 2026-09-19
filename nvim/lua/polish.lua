-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

-- 中クリックペーストを無効化
-- ノーマル(n), 挿入(i), ビジュアル(v), コマンドライン(c) モードを対象
vim.keymap.set({ "n", "i", "v", "c" }, "<MiddleMouse>", "<Nop>", { silent = true })
vim.keymap.set({ "n", "i", "v", "c" }, "<2-MiddleMouse>", "<Nop>", { silent = true })
vim.keymap.set({ "n", "i", "v", "c" }, "<3-MiddleMouse>", "<Nop>", { silent = true })
vim.keymap.set({ "n", "i", "v", "c" }, "<4-MiddleMouse>", "<Nop>", { silent = true })

-- vim から離れずにコマンドを尋ねる。結果をポップアップに出す
-- systemlist は完了を待つのでストリーミングの恩恵は受けない。体感が悪ければ jobstart に変える
vim.api.nvim_create_user_command("Vq", function(opts)
  local lines = vim.fn.systemlist({ "vq", opts.args })
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_open_win(buf, false, {
    relative = "cursor",
    row = 1,
    col = 0,
    width = 60,
    height = math.min(#lines, 10),
    border = "rounded",
    style = "minimal",
  })
end, { nargs = "+", desc = "vq に vim コマンドを尋ねる" })
