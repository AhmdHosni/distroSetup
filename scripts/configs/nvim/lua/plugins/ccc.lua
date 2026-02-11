----------------------------------------------------------------------------------
-- File:          ccc.lua
-- Created:       Monday, 26 January 2026 - 11:26 AM
-- Author:        AhmdHosni (ahmdhosny@gmail.com)
-- Link:
-- Description:   a nice plugin to show the color representing the hex color in any file.
--                Updated to show a color circle (virtual text) next to hex codes.
----------------------------------------------------------------------------------

return {
	"uga-rosa/ccc.nvim",
	version = "*",
	opts = {

		highlighter = {
			auto_enable = true,
			lsp = true,
			-- This ensures the actual text color isn't changed
			updates = "insert",
		},
		-- "virtual" puts the color next to the code
		highlight_mode = "virtual",
		-- This defines the "circle" symbol (●)
		virtual_symbol = " ● ",
	},
}
