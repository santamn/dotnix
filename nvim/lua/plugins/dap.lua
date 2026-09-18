-- デバッガ (nvim-dap) の設定
--
-- nvim-dap 本体・nvim-dap-ui・<Leader>d 配下のキーマップ・ブレークポイントの
-- アイコンは AstroNvim が既定で用意している (lua/astronvim/plugins/dap.lua)。
-- UI の自動開閉もそちらが設定済みなので、ここでは追加分だけを書く。

---@type LazySpec
return {
  "mfussenegger/nvim-dap",
  dependencies = {
    {
      -- 停止中の行の横に変数の値を表示する
      "theHamsta/nvim-dap-virtual-text",
      opts = { commented = true }, -- コメントのように表示する
    },
  },
}
