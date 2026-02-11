----------------------------------------------------------------------------------
-- File:          noice.lua
-- Created:       Sunday, 25 January 2026 - 02:49 PM
-- Author:        AhmdHosni (ahmdhosny@gmail.com)
-- Link:          https://github.com/rcarriga/nvim-notify   (Notify plugin)
--                https://github.com/folke/noice.nvim       (Noice plugin)
-- Description:  A beutiful Cli for neovim with notification plugin
--              (2 plugins working together)
----------------------------------------------------------------------------------

return {

	{
		-- notify plugin if needed

		"rcarriga/nvim-notify",
		version = "*",
		opts = {
			stages = "static", -- Faster performance in 2026
			timeout = 3000,
			background_colour = "#000000",
			render = "compact", -- Clean look for high-resolution displays
		},
		config = function(_, opts)
			require("notify").setup(opts)
			vim.notify = require("notify") -- Redirect standard notifications

			-- -- Send welcome message
			-- vim.notify("Welcome back Ahmed!", vim.log.levels.INFO, {
			-- 	title = "Neovim",
			-- 	timeout = 3000,
			-- })
		end,
	},

	-- Noice plugin
	{
		"folke/noice.nvim",
		version = "*",
		event = "VeryLazy",

		-- dependancies
		dependencies = {
			-- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
			"MunifTanjim/nui.nvim",
			-- OPTIONAL:
			--   `nvim-notify` is only needed, if you want to use the notification view.
			--   If not available, we use `mini` as the fallback
			"rcarriga/nvim-notify",
		},

		-- options
		opts = {
			-- add any options here

			notify = {
				enabled = true,
				view = "notify",
			},

			lsp = {
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
					["cmp.entry.get_documentation"] = true,
				},
			},
			presets = {
				bottom_search = true,
				command_palette = true,
				long_message_to_split = true,
			},
		},

		-- keys
		keys = {
			-- History integration with fzf-lua
			{
				"<leader>nh",
				function()
					vim.cmd("Noice fzf")
				end,
				desc = "Noice/Notify History",
			},
			{
				"<leader>nd",
				function()
					require("noice").cmd("dismiss")
				end,
				desc = "Dismiss All",
			},
		},
	},
}
