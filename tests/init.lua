vim.opt.runtimepath:prepend(vim.fn.stdpath("data") .. "/site/pack/lazy/start/lazy.nvim")

require("lazy").setup({
  { "nvim-lua/plenary.nvim", lazy = false },
  { "L3MON4D3/LuaSnip" },
  { dir = vim.fn.getcwd() },
})
