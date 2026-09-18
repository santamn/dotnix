-- 括弧の自動補完 (nvim-autopairs) の追加ルール
--
-- 既定の設定は AstroNvim が入れるので、その上にルールを足す形にする。

---@type LazySpec
return {
  "windwp/nvim-autopairs",
  config = function(plugin, opts)
    -- AstroNvim 既定の setup を先に通す
    require("astronvim.plugins.configs.nvim-autopairs")(plugin, opts)

    local Rule = require("nvim-autopairs.rule")
    local cond = require("nvim-autopairs.conds")

    -- TeX の数式 $...$ をペアにする
    require("nvim-autopairs").add_rules {
      Rule("$", "$", { "tex", "latex" })
      -- 直後が % のときはペアにしない (エスケープ済みの \% を壊さないため)
          :with_pair(cond.not_after_regex("%%"))
      -- $ を続けて打ったときに右へ飛ばさない
          :with_move(cond.none())
      -- <CR> で改行を挟まない
          :with_cr(cond.none()),
    }
  end,
}
