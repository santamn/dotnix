-- Herdr (https://herdr.dev/) との連携キーマップ
--
-- Herdr のワークスペースで「左に Neovim、右に AI エージェント (Claude Code など)」
-- を並べて使うとき、右隣のペインへファイルパスや選択範囲を送るためのもの。
-- Herdr のペイン内で Neovim を起動している場合のみ機能する。

---@type LazySpec
return {
  "AstroNvim/astrocore",
  opts = function(_, opts)
    if vim.fn.executable "herdr" == 0 then return end

    -- 右隣のペイン ID (例: "w1:p2") を取得する
    local function right_neighbor()
      local out = vim.fn.system { "herdr", "pane", "neighbor", "--direction", "right", "--current" }
      if vim.v.shell_error ~= 0 then return nil end
      out = vim.trim(out)
      if out == "" then return nil end
      return out
    end

    -- 右隣のペインにテキストを送る
    local function send_to_agent(text)
      local target = right_neighbor()
      if not target then
        vim.notify("右隣に Herdr のペインが見つかりません", vim.log.levels.WARN)
        return
      end
      vim.fn.system { "herdr", "pane", "send-text", target, text }
      if vim.v.shell_error ~= 0 then
        vim.notify("Herdr への送信に失敗しました", vim.log.levels.ERROR)
      end
    end

    local maps = opts.mappings
    maps.n = maps.n or {}
    maps.v = maps.v or {}

    maps.n["<Leader>zf"] = {
      function() send_to_agent(vim.fn.expand "%:p") end,
      desc = "現在のファイルパスをエージェントに送る (Herdr)",
    }
    maps.v["<Leader>zl"] = {
      function()
        -- ビジュアル選択中の範囲をそのまま取得して送る
        local lines = vim.fn.getregion(vim.fn.getpos "v", vim.fn.getpos ".", { type = vim.fn.mode() })
        send_to_agent(table.concat(lines, "\n"))
      end,
      desc = "選択範囲をエージェントに送る (Herdr)",
    }
  end,
}
