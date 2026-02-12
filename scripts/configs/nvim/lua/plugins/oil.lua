----------------------------------------------------------------------------------
-- File:          oil.lua
-- Created:       Saturday, 24 January 2026 - 08:16 AM
-- Author:        AhmdHosni (ahmdhosny@gmail.com)
-- Link:          https://github.com/stevearc/oil.nvim
-- Description:   an excellent file explorer plugin for neovim
----------------------------------------------------------------------------------

return {
	{
		"stevearc/oil.nvim",
		version = "*",
		dependencies = { { "nvim-tree/nvim-web-devicons", opts = {} } },
		lazy = false,

		---@module 'oil'
		---@type oil.SetupOpts
		opts = {
			default_file_explorer = true,
			view_options = {
				show_hidden = true,
			},
			float = {
				padding = 2,
				max_width = 0,
				max_height = 0,
				border = "rounded",
				preview_split = "right", -- Ensures preview window stays on the right
			},
			preview_win = {
				update_on_cursor_moved = true,
			},
		},

		-- Use config function to set up both the plugin and the autocmd
		config = function(_, opts)
			require("oil").setup(opts)

			-- Auto-open preview when entering an oil buffer
			vim.api.nvim_create_autocmd("User", {
				pattern = "OilEnter",
				callback = vim.schedule_wrap(function(args)
					local oil = require("oil")
					if vim.api.nvim_get_current_buf() == args.data.buf and oil.get_cursor_entry() then
						oil.open_preview()
					end
				end),
			})
		end,
	},
}
