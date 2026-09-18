-- AstroLSP は言語サーバーの起動・キーマップ・autocmd をまとめて設定する層
-- 設定項目の一覧は `:h astrolsp`
--
-- v6 から言語サーバーの設定は Neovim 組み込みの vim.lsp.config に載る。
-- config / handlers の ["*"] キーが全サーバー共通の既定値を表す。
--
-- ここには AstroNvim の既定値と異なるものだけを書く

---@type LazySpec
return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = {
    features = {
      inlay_hints = true,    -- VSCode 風に型や引数名のヒントをインラインで表示 (既定 false)
      signature_help = true, -- 挿入モードで引数のシグネチャを自動表示 (既定 false)
    },
    -- 保存時フォーマットは conform.nvim に任せる (plugins/conform.lua)。
    -- ここを既定の true のままにすると LSP と conform で二重にフォーマットが走る
    formatting = { format_on_save = false },
    -- Mason を使わず、PATH 上のバイナリで起動する LSP サーバー一覧
    -- (常用のものは Nix の home.packages で、言語ツールチェーンは各プロジェクトの devShell で導入する)
    -- NOTE: rust_analyzer をここに書いてはいけない。Rust は rustaceanvim が LSP を
    --       管理しており、二重に起動すると補完や診断が壊れる
    -- PATH にバイナリが無いサーバーは起動されずに黙って飛ばされるので、
    -- devShell でしか入らないものをここに並べても副作用はない
    servers = {
      "lua_ls",       -- Lua (この設定ファイル自身の編集用)
      "nil_ls",       -- Nix
      "gopls",        -- Go       (templates/go)
      "basedpyright", -- Python   (templates/python)
      "hls",          -- Haskell  (templates/haskell)
      "clojure_lsp",  -- Clojure  (templates/clojure)
    },
    -- 言語サーバーがアタッチしたバッファに設定する autocmd
    autocmds = {
      -- カーソルを止めたときに診断をフロートで出す
      -- (cond は付けない。publishDiagnostics は server_capabilities に現れないため
      --  Client:supports_method が常に true を返し、条件として機能しない)
      lsp_document_diagnostics = {
        {
          event = { "CursorHold" },
          desc = "Show diagnostics on cursor hold",
          callback = function()
            vim.diagnostic.open_float { focus = false, scope = "cursor" }
          end,
        },
      },
    },
    -- 言語サーバーがアタッチしたバッファに設定するキーマップ
    mappings = {
      n = {
        -- LSP による意味ベースのリネーム: カーソル下のシンボルの全参照を一括改名する
        -- 既定は vim.lsp.buf.rename だが、inc-rename.nvim (plugins/inc-rename.lua) に
        -- 差し替えて、入力中に結果をライブプレビューさせる
        ["<Leader>lr"] = {
          function()
            return ":IncRename " .. vim.fn.expand("<cword>")
          end,
          expr = true, -- 返り値のコマンド文字列をコマンドラインに展開する
          desc = "Rename current symbol",
          cond = "textDocument/rename",
        },
      },
    },
  },
}
