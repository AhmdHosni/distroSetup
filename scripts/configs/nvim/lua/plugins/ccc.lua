----------------------------------------------------------------------------------
-- File:          ccc.lua
-- Created:       Monday, 26 January 2026 - 11:26 AM
-- Author:        AhmdHosni (ahmdhosny@gmail.com)
-- Link:
-- Description:   a nice plugin to show the color representing the hex color in any file.
--                Updated to show a color circle (virtual text) next to hex codes.
----------------------------------------------------------------------------------

-- ~/.config/nvim/lua/plugins/ccc.lua
-- ccc is used ONLY as a color picker — highlighter is OFF
-- the colored circle is handled by nvim-colorizer.lua (see colorizer.lua)

return {
	"uga-rosa/ccc.nvim",
	cmd = { "CccPick", "CccConvert" },
	opts = function()
		local ccc = require("ccc")
		local mapping = ccc.mapping

		return {
			-- disable the built-in highlighter entirely
			highlighter = {
				auto_enable = false,
				lsp = false,
			},

			default_color = "#ffffff",

			inputs = {
				ccc.input.rgb,
				ccc.input.hsl,
				ccc.input.cmyk,
			},

			outputs = {
				ccc.output.css_rgb,
				ccc.output.css_hsl,
				ccc.output.hex,
				ccc.output.hex_short,
			},

			recognize = {
				input = true,
				output = true,
			},

			mappings = {
				["q"] = mapping.quit,
				["<Esc>"] = mapping.quit,
				["<CR>"] = mapping.complete,
				["<Tab>"] = mapping.toggle_input_mode,
				["l"] = mapping.increase1,
				["L"] = mapping.increase5,
				["h"] = mapping.decrease1,
				["H"] = mapping.decrease5,
				["i"] = mapping.set_percent,
			},

			win_opts = {
				relative = "cursor",
				row = 1,
				col = 1,
				style = "minimal",
				border = "rounded",
			},
		}
	end,

	keys = {
		{ "<leader>cp", "<cmd>CccPick<cr>", desc = "Color Picker" },
		{ "<leader>cc", "<cmd>CccConvert<cr>", desc = "Convert Color Format" },
	},
}
