----------------------------------------------------------------------------------
-- File:          kanagawa.lua
-- Created:       Thursday, 12 February 2026 - 01:35 PM
-- Author:        AhmdHosni (ahmdhosny@gmail.com)
-- Link:
-- Description:   Kanagawa colorScheme plugin for neovim
----------------------------------------------------------------------------------

return {
	"rebelot/kanagawa.nvim",
	branch = "master",
	config = function()
		require("kanagawa").setup({
			transparent = true,
			colors = {
				theme = {
					all = {
						ui = {
							bg_gutter = "none",
						},
					},
				},
			},
			overrides = function(colors)
				return {
					["@markup.link.url.markdown_inline"] = { link = "Special" }, -- (url)
					["@markup.link.label.markdown_inline"] = { link = "WarningMsg" }, -- [label]
					["@markup.italic.markdown_inline"] = { link = "Exception" }, -- *italic*
					["@markup.raw.markdown_inline"] = { link = "String" }, -- `code`
					["@markup.list.markdown"] = { link = "Function" }, -- + list
					["@markup.quote.markdown"] = { link = "Error" }, -- > blockcode
					["@markup.list.checked.markdown"] = { link = "WarningMsg" }, -- - [X] checked list item
				}
			end,
		})
		vim.cmd("colorscheme kanagawa")
	end,
}
