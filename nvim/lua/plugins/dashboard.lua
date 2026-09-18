-- 起動画面 (snacks.nvim の dashboard) のカスタマイズ
--
-- ヘッダとその他のメニュー項目は AstroNvim の既定をそのまま使い、
-- ディレクトリを選んで開く項目だけを足す。
--
-- NOTE: キーは既定と重複させないこと。既定で n / f / o / w / ' / s が埋まっている
--       (o は Recents)。重複させると後に登録されたほうだけが動く

---@type LazySpec
return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    -- ディレクトリを選んで cwd を移し、そこで Neo-tree を開く
    local open_dir_key = {
      icon = "📂︎",
      key = "d",
      desc = "Open Directory",
      action = function()
        local has_fd = vim.fn.executable("fd") == 1
        require("snacks").picker.files({
          cmd = has_fd and "fd" or "find",
          args = has_fd and { "--type", "d", "--hidden", "--exclude", ".git" }
              or { ".", "-type", "d", "-not", "-path", "*/.*" },
          prompt_title = "Open Directory",
          confirm = function(picker, item)
            picker:close()
            if item then
              vim.fn.chdir(item.text)
              vim.cmd("Neotree show")
            end
          end,
        })
      end,
    }

    -- New File / Find File の次に差し込む (項目が少ない場合は末尾)
    local preset = opts.dashboard.preset
    preset.keys = preset.keys or {}
    table.insert(preset.keys, math.min(3, #preset.keys + 1), open_dir_key)

    return opts
  end,
}
