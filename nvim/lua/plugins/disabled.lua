-- AstroNvim が既定で入れるプラグインのうち、無効化するもの

---@type LazySpec
return {
  -- NixOS では Mason を使わない
  --
  -- Mason が配布するビルド済みバイナリは FHS 前提 (動的リンク) のため
  -- NixOS ではそのまま動かないことが多い。LSP サーバー・フォーマッタ・リンタは
  -- Nix 側 (modules/home/programs/neovim.nix と各プロジェクトの devShell) で
  -- インストールし、PATH 上のバイナリを使わせる。
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },
  { "jay-babu/mason-nvim-dap.nvim", enabled = false },
  { "WhoIsSethDaniel/mason-tool-installer.nvim", enabled = false },

  -- jk / jj での挿入モード脱出。<Esc> で足りるため使わない
  { "max397574/better-escape.nvim", enabled = false },

  -- 外部コマンドを LSP に見せかける層。フォーマットは conform.nvim に一本化している
  { "nvimtools/none-ls.nvim", enabled = false },
}
