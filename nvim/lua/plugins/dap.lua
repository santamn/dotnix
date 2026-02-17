---@type LazySpec
return {
  "mfussenegger/nvim-dap",
  lazy = true,
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
    "theHamsta/nvim-dap-virtual-text",
  },
  keys = {
    { "<leader>db", function() require("dap").toggle_breakpoint() end,                                   desc = "Toggle breakpoint" },
    { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input "Breakpoint condition: ") end, desc = "Conditional breakpoint" },
    { "<leader>dc", function() require("dap").continue() end,                                            desc = "Continue" },
    { "<leader>dC", function() require("dap").run_to_cursor() end,                                       desc = "Run to cursor" },
    { "<leader>di", function() require("dap").step_into() end,                                           desc = "Step into" },
    { "<leader>do", function() require("dap").step_over() end,                                           desc = "Step over" },
    { "<leader>dO", function() require("dap").step_out() end,                                            desc = "Step out" },
    { "<leader>dp", function() require("dap").pause() end,                                               desc = "Pause" },
    { "<leader>dr", function() require("dap").repl.toggle() end,                                         desc = "Toggle REPL" },
    { "<leader>dt", function() require("dap").terminate() end,                                           desc = "Terminate" },
    { "<leader>du", function() require("dapui").toggle() end,                                            desc = "Toggle DAP UI" },
    { "<leader>de", function() require("dapui").eval() end,                                              desc = "Eval",                  mode = { "n", "v" } },
  },
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")

    -- DAP UI のレイアウト設定
    dapui.setup({
      icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
      layouts = {
        {
          elements = {
            { id = "scopes",      size = 0.25 },
            { id = "breakpoints", size = 0.25 },
            { id = "stacks",      size = 0.25 },
            { id = "watches",     size = 0.25 },
          },
          size = 40,
          position = "left",
        },
        {
          elements = {
            { id = "repl",    size = 0.5 },
            { id = "console", size = 0.5 },
          },
          size = 10,
          position = "bottom",
        },
      },
    })

    -- バーチャルテキストの設定 (行の横に変数の値を表示)
    require("nvim-dap-virtual-text").setup({
      enabled = true,
      commented = true, -- コメントのように表示
    })

    -- 自動的にUIを開閉する設定
    dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
    dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
    dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

    -- 4. アイコン (Signs) の設定
    vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint", linehl = "", numhl = "" })
    vim.fn.sign_define("DapBreakpointCondition",
      { text = "●", texthl = "DapBreakpointCondition", linehl = "", numhl = "" })
    vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DapStopped", linehl = "DapStoppedLine", numhl = "" })
  end,
}
