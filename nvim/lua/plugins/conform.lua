---@type LazySpec
return {
  "stevearc/conform.nvim",
  event = "BufWritePre", -- ファイル保存時にロード
  opts = {
    -- フォーマッターの定義
    formatters_by_ft = {
      -- rustfmtコマンドがPATHに存在すればそれを使用
      rust = { "rustfmt", lsp_format = "fallback" },
    },
    -- 保存時の自動フォーマット設定
    format_on_save = {
      -- タイムアウトを少し長めに設定（Nix環境での初回起動時などを考慮）
      timeout_ms = 1000,
      lsp_fallback = true,
    },
    -- Masonで管理していないツールも警告を出さずに使うようにする微調整
    formatters = {
      rustfmt = {
        -- 必要であれば引数を追加できる e.g. args = { "--edition", "2021" },
        -- コマンドが見つからない場合に通知を出さないようにするには false
        command = "rustfmt",
      },
    },
  },
}
