-- AstroLSP allows you to customize the features in AstroNvim's LSP configuration engine
-- Configuration documentation can be found with `:h astrolsp`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

---@type LazySpec
return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = {
    -- Configuration table of features provided by AstroLSP
    features = {
      codelens = true,        -- enable/disable codelens refresh on start
      inlay_hints = true,     -- VSCode 風に型や引数名のヒントをインラインで表示
      semantic_tokens = true, -- enable/disable semantic token highlighting
    },
    -- customize lsp formatting options
    formatting = {
      -- control auto formatting on save
      format_on_save = {
        enabled = true,     -- enable or disable format on save globally
        allow_filetypes = { -- enable format on save for specified filetypes only
          -- "go",
        },
        ignore_filetypes = { -- disable format on save for specified filetypes
          -- "python",
        },
      },
      disabled = { -- disable formatting capabilities for the listed language servers
        -- disable lua_ls formatting capability if you want to use StyLua to format your lua code
        -- "lua_ls",
      },
      timeout_ms = 1000, -- default format timeout
      -- filter = function(client) -- fully override the default formatting function
      --   return true
      -- end
    },
    -- Mason を使わず、PATH 上のバイナリで起動する LSP サーバー一覧
    -- (常用のものは Nix の home.packages で、言語ツールチェーンは各プロジェクトの devShell で導入する)
    -- NOTE: rust_analyzer をここに書いてはいけない。Rust は rustaceanvim が LSP を
    --       管理しており、lspconfig 側でも起動すると二重起動して補完や診断が壊れる
    servers = {
      "lua_ls",  -- Lua (この設定ファイル自身の編集用)
      "nil_ls",  -- Nix
      "gopls",   -- Go (devShell からバイナリを供給)
    },
    -- `vim.lsp.config(server, opts)` に渡す設定。["*"] は全サーバー共通の既定値になる
    config = {
      -- ["*"] = { capabilities = { textDocument = { foldingRange = { dynamicRegistration = false } } } },
      -- clangd = { capabilities = { offsetEncoding = "utf-8" } },
    },
    -- サーバーの起動方法をサーバー単位で差し替える。["*"] が既定 (vim.lsp.enable)
    handlers = {
      -- ["*"] = function(server) vim.lsp.enable(server) end
      -- 解決済みの設定テーブルが要るときは vim.lsp.config[server] を読む
      -- rust_analyzer = false, -- false にするとそのサーバーの起動を止められる
    },
    -- Configure buffer local auto commands to add when attaching a language server
    autocmds = {
      -- first key is the `augroup` to add the auto commands to (:h augroup)
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
      lsp_codelens_refresh = {
        -- Optional condition to create/delete auto command group
        -- can either be a string of a client capability or a function of `fun(client, bufnr): boolean`
        -- condition will be resolved for each client on each execution and if it ever fails for all clients,
        -- the auto commands will be deleted for that buffer
        cond = "textDocument/codeLens",
        -- cond = function(client, bufnr) return client.name == "lua_ls" end,
        -- list of auto commands to set
        {
          -- events to trigger
          event = { "InsertLeave", "BufEnter" },
          -- the rest of the autocmd options (:h nvim_create_autocmd)
          desc = "Refresh codelens (buffer)",
          callback = function(args)
            if require("astrolsp").config.features.codelens then
              vim.lsp.codelens.refresh({ bufnr = args.buf })
            end
          end,
        },
      },
    },
    -- mappings to be set up on attaching of a language server
    mappings = {
      n = {
        -- a `cond` key can provided as the string of a server capability to be required to attach, or a function with `client` and `bufnr` parameters from the `on_attach` that returns a boolean
        gD = {
          function()
            vim.lsp.buf.declaration()
          end,
          desc = "Declaration of current symbol",
          cond = "textDocument/declaration",
        },
        ["<Leader>uY"] = {
          function()
            require("astrolsp.toggles").buffer_semantic_tokens()
          end,
          desc = "Toggle LSP semantic highlight (buffer)",
          cond = function(client)
            return client:supports_method("textDocument/semanticTokens/full")
                and vim.lsp.semantic_tokens ~= nil
          end,
        },
        -- LSP による意味ベースのリネーム: カーソル下のシンボルの全参照を一括改名する
        -- inc-rename.nvim (plugins/inc-rename.lua) を使い、入力中に結果をライブプレビューする
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
    -- A custom `on_attach` function to be run after the default `on_attach` function
    -- takes two parameters `client` and `bufnr`  (`:h lspconfig-setup`)
    on_attach = function(client, bufnr)
      -- this would disable semanticTokensProvider for all clients
      -- client.server_capabilities.semanticTokensProvider = nil
    end,
  },
}
