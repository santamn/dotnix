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
    -- パーサは Nix が供給するため、実行時のダウンロードとコンパイルは行わない
    treesitter = {
      auto_install = false,
    },
    options = {
      opt = {
        spell = true, -- スペルチェックを有効化
      },
    },
  },
}
