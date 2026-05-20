vim.g.mapleader = " "
local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.showmode = false
opt.updatetime = 100
opt.signcolumn = "yes"
opt.termguicolors = true
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.clipboard = "unnamedplus"
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup({
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
  { "ellisonleao/gruvbox.nvim" },
  { 'nvim-lualine/lualine.nvim', dependencies = { 'nvim-tree/nvim-web-devicons' }, opts = { options = { theme = 'gruvbox' } } },
  { 'akinsho/bufferline.nvim', opts = {} },
  { "nvim-tree/nvim-tree.lua", opts = {} },
  { 'neovim/nvim-lspconfig' },
  { 'williamboman/mason.nvim', opts = {} },
  { 
    'hrsh7th/nvim-cmp', 
    dependencies = { 'hrsh7th/cmp-nvim-lsp', 'hrsh7th/cmp-buffer' },
    config = function()
      local cmp = require('cmp')
      cmp.setup({
        mapping = cmp.mapping.preset.insert({
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
        }),
        sources = cmp.config.sources({{ name = 'nvim_lsp' }}, {{ name = 'buffer' }})
      })
    end
  },
  { 'akinsho/toggleterm.nvim', version = "*", opts = { open_mapping = [[<c-\>]] } },
})
vim.cmd.colorscheme "catppuccin"
