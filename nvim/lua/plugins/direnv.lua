---@type LazySpec
return {
  "direnv/direnv.vim",
  lazy = false,    -- 遅延読み込みを無効化し、起動時に即座に読み込む
  priority = 1000, -- 他のプラグイン（LSPなど）より先に読み込む
}
