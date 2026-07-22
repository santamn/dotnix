-- NixOS では Mason を使わない
--
-- Mason が配布するビルド済みバイナリは FHS 前提 (動的リンク) のため
-- NixOS ではそのまま動かないことが多い。LSP サーバー・フォーマッタ・リンタは
-- Nix 側 (modules/home/programs/neovim.nix と各プロジェクトの devShell) で
-- インストールし、PATH 上のバイナリを使わせる。

---@type LazySpec
return {
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },
  { "jay-babu/mason-nvim-dap.nvim", enabled = false },
  { "WhoIsSethDaniel/mason-tool-installer.nvim", enabled = false },
}
