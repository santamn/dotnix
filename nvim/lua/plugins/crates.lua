-- ref: https://syu-m-5151.hatenablog.com/entry/2026/01/29/130742

---@type LazySpec
return {
  "saecki/crates.nvim",
  -- Cargo.toml を開いたときのみ読み込む（遅延読み込み）
  event = { "BufRead Cargo.toml" },
  -- 依存プラグイン
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    -- 補完機能の設定
    -- (AstroNvim の補完は blink.cmp。nvim-cmp は入っていないので cmp 連携は設定しない)
    completion = {
      crates = {
        enabled = true,  -- クレート自体の補完を有効化
        max_results = 8, -- 補完候補の最大表示数
        min_chars = 3,   -- 補完を開始する文字数
      },
    },
    -- LSPのような機能（定義ジャンプやホバー表示など）の設定
    lsp = {
      enabled = true,
      actions = true,    -- コードアクション（修正提案）を有効化
      completion = true, -- LSP経由の補完を有効化
      hover = true,      -- ホバー表示（Kキーなど）を有効化

      -- バッファにアタッチされたとき（Cargo.tomlを開いたとき）に実行される関数
      on_attach = function(_, bufnr)
        -- キーマッピング登録用のヘルパー関数
        local function set_key(mode, key, func, desc)
          vim.keymap.set(mode, key, func, { buffer = bufnr, silent = true, desc = desc })
        end

        local crates = require("crates")
        -- === キーマッピング設定 ===
        -- 表示・操作系
        set_key("n", "<leader>ct", crates.toggle, "クレート情報の表示切替 (Toggle)")
        set_key("n", "<leader>cr", crates.reload, "クレート情報の再読み込み (Reload)")

        -- ポップアップ表示系
        set_key("n", "<leader>cv", crates.show_versions_popup, "バージョン一覧を表示")
        set_key("n", "<leader>cf", crates.show_features_popup, "機能(Features)一覧を表示")
        set_key("n", "<leader>cd", crates.show_dependencies_popup, "依存関係を表示")

        -- 更新・アップグレード系
        set_key("n", "<leader>cu", crates.update_crate, "カーソル下のクレートを更新 (Update)")
        set_key("v", "<leader>cu", crates.update_crates, "選択したクレートを更新")
        set_key("n", "<leader>cU", crates.upgrade_crate, "カーソル下のクレートをアップグレード")
        set_key("v", "<leader>cU", crates.upgrade_crates, "選択したクレートをアップグレード")
        set_key("n", "<leader>cA", crates.upgrade_all_crates, "全クレートをアップグレード")

        -- リンクを開く系
        set_key("n", "<leader>cH", crates.open_homepage, "ホームページを開く")
        set_key("n", "<leader>cR", crates.open_repository, "リポジトリを開く")
        set_key("n", "<leader>cD", crates.open_documentation, "ドキュメント(docs.rs)を開く")
        set_key("n", "<leader>cC", crates.open_crates_io, "crates.io のページを開く")
      end,
    },
    -- ポップアップウィンドウの見た目設定
    -- (枠線は AstroNvim v6 が設定する winborder = "rounded" に従う)
    popup = {
      show_version_date = true, -- バージョンの公開日を表示する
      max_height = 30,
      min_width = 20,
    },
  },
}
