----------------------------------------------------------------------------------
-- File:          lualine.lua
-- Created:       Thursday, 12 February 2026 - 07:33 PM
-- Author:        AhmdHosni (ahmdhosny@gmail.com)
-- Link:          https://github.com/nvim-lualine/lualine.nvim
-- Description:  a dynamic nvim bottom bar plugin that responds to any neovim theme (auto theme)
----------------------------------------------------------------------------------

return {
	"nvim-lualine/lualine.nvim",
	event = "VeryLazy",
	opts = {
		options = {
			-- "auto" works for Catppuccin, Gruvbox, and Kanagawa out of the box
			theme = "auto",
			--component_separators = { left = "", right = "" },
			section_separators = { left = "", right = "" },
			--icons_enabled = true,
			--section_separators = { left = "", right = "" },
			--component_separators = "|",
		},
	},
}
