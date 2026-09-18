-- 保存時フォーマットの一元管理
--
-- AstroLSP 側の format_on_save は無効化してあり (plugins/astrolsp.lua)、
-- 保存時のフォーマットはすべてここを通る。
-- formatters_by_ft に載っていないファイルタイプは lsp_format = "fallback" で
-- LSP の textDocument/formatting に落ちる。
--
-- フォーマッタのバイナリは Nix 側で供給する:
-- 常用のものは modules/home/programs/neovim.nix、
-- 言語プロジェクト固有のもの (rustfmt など) は各プロジェクトの devShell。

---@type LazySpec
return {
  "stevearc/conform.nvim",
  event = "BufWritePre", -- ファイル保存時にロード
  opts = {
    -- ここに無いファイルタイプは lsp_format = "fallback" で LSP の整形に落ちる。
    -- Haskell (HLS) と Clojure (clojure-lsp) は LSP 側が整形できるので書かない
    formatters_by_ft = {
      lua = { "stylua" },
      nix = { "alejandra" },
      rust = { "rustfmt" },
      go = { "goimports" }, -- gofmt の整形に import の整理を足したもの
      python = { "ruff_organize_imports", "ruff_format" },
    },
    format_on_save = {
      -- タイムアウトを少し長めに設定 (Nix 環境での初回起動時などを考慮)
      timeout_ms = 1000,
      lsp_format = "fallback",
    },
  },
}
