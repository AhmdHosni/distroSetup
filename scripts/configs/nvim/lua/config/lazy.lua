----------------------------------------------------------------------------------
-- File:          lazy.lua
-- Created:       Saturday, 24 January 2026 - 07:56 AM
-- Author:        AhmdHosni (ahmdhosny@gmail.com)
-- Link:          lazy.nvim github  : https://github.com/folke/lazy.nvim
--                lazy.nvim website : https://lazy.folke.io/installation

-- Description:   lazy.nvim package manager Bootstrap & Plugin Setup
--                bootstraps the 'lazy.nvim' plugin manager by cloning it if not present, prepends it to the
--                runtime path, and then loads core configuration files (globals, options, keymaps, autocmds).
--                Last, initialises 'lazy.nvim' with plugins.

----------------------------------------------------------------------------------

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
---@diagnostic disable-next-line: undefined-field (fs_stat)
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

require("config.globals")
require("config.options")
require("config.keymaps")
require("config.autocmds")

local plugins_dir = "plugins"

require("lazy").setup({

	spec = {
		{ import = plugins_dir },
		{ "folke/lazy.nvim", version = "*" },
	},

	rtp = {
		disabled_plugins = {
			"netrw",
			"netrwPlugin",
		},
	},

	install = {
		--colorscheme = {"catppuccin",},
		colorscheme = { "kanagawa" },
	},

	checker = { enabled = true },
})
