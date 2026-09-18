-- Tree-sitter のパーサとクエリは Nix (modules/home/programs/neovim.nix) が
-- ~/.local/share/nvim/site 以下に配置する (nvim-treesitter.withAllGrammars)。
--
-- nvim-treesitter main ブランチの install_dir 既定値が stdpath("data")/site で
-- ちょうど同じ場所を指すため、置き場所に関する設定は要らない。
-- 実行時のダウンロードとコンパイルは行わない (astrocore.lua の auto_install = false)。

---@type LazySpec
return {
  "nvim-treesitter/nvim-treesitter",
  build = false, -- AstroNvim 既定の `:TSUpdate` を止める。パーサは Nix 管理のため
}
