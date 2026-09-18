-- AstroUI は配色・アイコン・ステータスラインの土台を設定する層
-- 設定項目の一覧は `:h astroui`

---@type LazySpec
return {
  "AstroNvim/astroui",
  ---@type AstroUIOpts
  opts = {
    colorscheme = "astrodark",
  },
}
