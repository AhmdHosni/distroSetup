----------------------------------------------------------------------------------
-- File:          color-sep.lua
-- Created:       Sunday, 25 January 2026 - 02:35 PM
-- Author:        AhmdHosni (ahmdhosny@gmail.com)
-- Link:          https://github.com/nvim-zh/colorful-winsep.nvim
-- Description:   A colorful window separator for neovim windows (Panels)
----------------------------------------------------------------------------------

return {
	"nvim-zh/colorful-winsep.nvim",
	version = "*",
	config = function()
		require("colorful-winsep").setup()
	end,
}
