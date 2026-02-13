----------------------------------------------------------------------------------
-- File:          which-keys.lua
-- Created:       Tuesday, 27 January 2026 - 05:37 AM
-- Author:        AhmdHosni (ahmdhosny@gmail.com)
-- Link:
-- Description:   wichKey plugin for neovim shows the keymaps you have set.
----------------------------------------------------------------------------------

return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		win = {
			border = "rounded",
			title = " Keymaps ",
			title_pos = "center",
			padding = { 1, 2 },
			-- winblend = 0,
		},
	},
	config = function(_, opts)
		local wk = require("which-key")
		wk.setup(opts)

		-- Dynamic Color Syncing Function
		local function apply_theme_colors()
			local colors = {}

			-- 1. Try Catppuccin
			local has_cp, cp_palette = pcall(require, "catppuccin.palettes")
			if has_cp then
				local flavor = require("catppuccin").options.flavour or "mocha"
				local palette = cp_palette.get_palette(flavor)
				--colors.border = palette.mauve
				colors.border = palette.blue
				colors.key = palette.blue

			-- 2. Try Kanagawa
			else
				local has_kana, kana_colors = pcall(require, "kanagawa.colors")
				if has_kana then
					local palette = kana_colors.setup().palette
					colors.border = palette.springBlue
					colors.key = palette.oniViolet
				end
			end

			-- 3. Apply Colors or Fallback
			if colors.border then
				vim.api.nvim_set_hl(0, "WhichKeyBorder", { fg = colors.border })
				vim.api.nvim_set_hl(0, "WhichKey", { fg = colors.key, bold = true })
			else
				-- Default fallback if no theme detected
				vim.api.nvim_set_hl(0, "WhichKeyBorder", { link = "FloatBorder" })
			end
		end

		-- Run initially
		apply_theme_colors()

		-- Also run when switching themes mid-session
		vim.api.nvim_create_autocmd("ColorScheme", {
			callback = apply_theme_colors,
		})

		-- Register your groups
		wk.add({
			{ "<leader>f", group = "file" },
			{ "<leader>g", group = "git" },
			{ "<leader>c", group = "code" },
			{ "<leader>b", group = "buffer" },
			{ "<leader>d", group = "document" },
			{ "<leader>w", group = "workspace" },
			{ "<leader>n", group = "notify" },
			{ "<leader>s", group = "split" },
			{ "<leader>t", group = "toggle" },
			{ "<leader>q", group = "quit/session" },
		})
	end,
}
