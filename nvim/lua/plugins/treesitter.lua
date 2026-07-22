-- Tree-sitter 設定
--
-- パーサは Nix (modules/home/programs/neovim.nix) が全言語分を
-- ~/.local/share/nvim/site/parser に配置している (nvim-treesitter.withAllGrammars)。
-- そのため実行時のダウンロードや C コンパイルは基本的に発生しない。
--
-- 特定言語でハイライトが崩れる場合などは :TSInstall <lang> で
-- プラグイン側のバージョンに合わせたパーサを追加できる (下の install_dir に入り、
-- Nix 配置分より優先される。tree-sitter CLI と gcc は Nix 側で導入済み)。

---@type LazySpec
return {
  "nvim-treesitter/nvim-treesitter",
  build = false, -- :TSUpdate による一括更新は不要 (パーサは Nix 管理のため)
  opts = {
    -- Nix が読み取り専用で管理する site/ とは別の書き込み可能なディレクトリを
    -- :TSInstall の入れ先にする
    install_dir = vim.fn.stdpath "data" .. "/treesitter",
  },
}
