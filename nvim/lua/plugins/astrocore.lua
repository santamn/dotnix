-- AstroCore は vim のオプション・キーマップ・autocmd をまとめて設定する層
-- 設定項目の一覧は `:h astrocore`
--
-- ここには AstroNvim の既定値と異なるものだけを書く。
-- 既定値は lua/astronvim/plugins/_astrocore*.lua を参照

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    features = {
      -- 大きいファイルで treesitter などを切る閾値。既定 (1.5MB / 10万行) より厳しくする
      large_buf = { size = 1024 * 256, lines = 10000 },
    },
    -- Neovim の Tree-sitter 機能 (ハイライト・インデント・textobjects) の設定。
    -- パーサとクエリは Nix が供給するため、実行時のダウンロードとコンパイルは行わない
    treesitter = {
      auto_install = false,
    },
    options = {
      opt = {
        spell = true, -- スペルチェックを有効化
      },
    },
    mappings = {
      n = {
        -- 既定の update_packages() は lazy の後に treesitter.update() まで走らせる。
        -- パーサは Nix 管理で site/parser-info に revision が無いため全言語が「要更新」と判定され、
        -- tree-sitter CLI も無いので約300言語分のエラーが出るだけになる。プラグイン更新だけに絞る
        ["<Leader>pa"] = { "<Cmd>Lazy sync<CR>", desc = "Update Plugins" },
      },
    },
  },
}
