---@type LazySpec
-- lua/plugins/rustaceanvim.lua
return {
  "mrcjkb/rustaceanvim",
  version = "^5", -- 推奨: バージョン5系を固定
  lazy = false,   -- ファイルタイプで自動起動するため false で良い
  init = function()
    -- rustaceanvim は vim.g.rustaceanvim に設定テーブルを代入する方式で設定を行う
    vim.g.rustaceanvim = {
      -- ツール全般の設定
      tools = {
        hover_actions = { replace_builtin_hover = false },
        float_win_config = { border = "rounded" },
        inlay_hints = {
          auto = true,
          show_parameter_hints = true,
          parameter_hints_prefix = "<- ",
          other_hints_prefix = "=> ",
        },
      },

      -- LSPサーバー (rust-analyzer) の設定
      server = {
        -- Flake環境の rust-analyzer バイナリを強制的に使用
        cmd = function()
          local ra_binary = vim.fn.exepath("rust-analyzer")
          if ra_binary == "" then
            -- パスが見つからない場合はmasonなどをフォールバック（通常はここに来ないはず）
            return { "rust-analyzer" }
          end
          return { ra_binary }
        end,

        -- キーマッピング設定 (on_attach)
        on_attach = function(client, bufnr)
          local opts = { silent = true, buffer = bufnr }
          -- ヘルパー関数: 説明付きでキーマップを設定
          local function map(mode, keys, func, desc)
            vim.keymap.set(mode, keys, func, vim.tbl_extend("force", opts, { desc = "Rust: " .. desc }))
          end

          map("n", "<leader>ra", function() vim.cmd.RustLsp("codeAction") end, "Code Action")
          map("n", "<leader>rd", function() vim.cmd.RustLsp("debuggables") end, "Debuggables")
          map("n", "<leader>rr", function() vim.cmd.RustLsp("runnables") end, "Runnables")
          map("n", "<leader>rt", function() vim.cmd.RustLsp("testables") end, "Testables")
          map("n", "<leader>rm", function() vim.cmd.RustLsp("expandMacro") end, "Expand Macro")
          map("n", "<leader>rc", function() vim.cmd.RustLsp("openCargo") end, "Open Cargo.toml")
          map("n", "<leader>rp", function() vim.cmd.RustLsp("parentModule") end, "Parent Module")
          map("n", "<leader>rj", function() vim.cmd.RustLsp("joinLines") end, "Join Lines")
          map("n", "<leader>rs", function() vim.cmd.RustLsp("ssr") end, "SSR (Search Replace)")
          map("n", "<leader>re", function() vim.cmd.RustLsp("explainError") end, "Explain Error")
          map("n", "<leader>rD", function() vim.cmd.RustLsp("renderDiagnostic") end, "Render Diagnostic")
          -- 'K' は通常LSPのHoverだが、rustaceanvimのアクション付きHoverに上書き
          map("n", "K", function() vim.cmd.RustLsp({ "hover", "actions" }) end, "Hover Actions")
        end,

        -- rust-analyzer の設定
        default_settings = {
          ["rust-analyzer"] = {
            checkOnSave = true,
            check = {
              command = "clippy",
              extraArgs = { "--all", "--", "-W", "clippy::all" },
            },
            cargo = {
              allFeatures = true,
              loadOutDirsFromCheck = true,
              buildScripts = { enable = true },
            },
            procMacro = {
              enable = true,
              attributes = { enable = true },
            },
            -- インレイヒントの詳細設定
            inlayHints = {
              enable = true,
              chainingHints = { enable = true },
              typeHints = { enable = true, hideClosureInitialization = true },
              parameterHints = { enable = true },
              closureReturnTypeHints = { enable = "with_block" },
              lifetimeElisionHints = { enable = "skip_trivial", useParameterNames = true },
              maxLength = 25,
              bindingModeHints = { enable = true },
              closureCaptureHints = { enable = true },
              discriminantHints = { enable = "fieldless" },
              expressionAdjustmentHints = { enable = "reborrow" },
              rangeExclusiveHints = { enable = true },
            },
            completion = {
              autoimport = { enable = true },
              postfix = { enable = true },
              callable = { snippets = "fill_arguments" },
              fullFunctionSignatures = { enable = true },
              privateEditable = { enable = true },
            },
            imports = {
              granularity = { group = "module" },
              prefix = "self",
            },
            diagnostics = {
              enable = true,
              experimental = { enable = true },
              styleLints = { enable = true },
            },
            semanticHighlighting = {
              operator = { specialization = { enable = true } },
              punctuation = { enable = true, specialization = { enable = true } },
              strings = { enable = true },
            },
            hover = {
              actions = {
                enable = true,
                references = { enable = true },
                run = { enable = true },
                debug = { enable = true },
                gotoTypeDef = { enable = true },
                implementations = { enable = true },
              },
              documentation = { enable = true, keywords = { enable = true } },
              links = { enable = true },
            },
            typing = {
              autoClosingAngleBrackets = { enable = true },
            },
            lens = {
              enable = true,
              references = { enable = true, adt = { enable = true }, enumVariant = { enable = true }, method = { enable = true }, trait = { enable = true } },
              implementations = { enable = true },
              run = { enable = true },
              debug = { enable = true },
            },
            workspace = {
              symbol = { search = { kind = "all_symbols" } },
            },
          },
        },
      },

      -- DAP (デバッグアダプター) の設定
      dap = {
        adapter = function(cfg)
          -- Flakeで定義した環境変数を使って codelldb をロード
          local codelldb_path = os.getenv("CODELLDB_PATH")
          local liblldb_path = os.getenv("LIBLLDB_PATH")

          if codelldb_path and liblldb_path then
            return require("rustaceanvim.config").get_codelldb_adapter(codelldb_path, liblldb_path)
          else
            -- Flake環境以外の場合のフォールバック
            return require("rustaceanvim.config").get_codelldb_adapter(nil, nil)
          end
        end,
      },
    }
  end,
}
