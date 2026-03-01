-- ~/.config/nvim/lua/plugins/colorizer.lua
-- handles the colored circle ● beside every color code

return {
	"NvChad/nvim-colorizer.lua",
	event = { "BufReadPre", "BufNewFile" },
	opts = {
		-- default options applied to all filetypes
		user_default_options = {
			RGB = true, -- #RGB
			RRGGBB = true, -- #RRGGBB
			RRGGBBAA = true, -- #RRGGBBAA
			names = false, -- "blue", "red" etc. — set true if you want named colors
			rgb_fn = true, -- rgb() and rgba()
			hsl_fn = true, -- hsl() and hsla()
			css = true, -- enable all css features
			css_fn = true, -- css functions

			-- THIS is what gives you the colored circle beside the code
			-- "virtualtext" inserts a virtual symbol; the color code itself is untouched
			mode = "virtualtext",

			-- The circle character — swap to ■ / ⬤ / ◉ if you prefer a different shape
			virtualtext = "●",

			-- Show circle BEFORE the color code ("before") or AFTER ("after")
			virtualtext_inline = true, -- inline = right before the hex code

			-- ── suppress the deprecation warning ────────────────────────────
			-- The "new structured format" (parser/display/hooks) is not yet fully
			-- implemented — using it breaks highlighting. This silences the notice
			-- while keeping the flat format that actually works.
			suppress_deprecation = true,
		},

		-- enable for all filetypes by default
		filetypes = { "*" },

		-- per-filetype overrides (optional)
		-- filetypes = {
		--   css  = { names = true },
		--   html = { names = true },
		-- },
	},

	keys = {
		{
			"<leader>ct",
			function()
				require("colorizer").toggle()
			end,
			desc = "Toggle Color Highlighter",
		},
	},
}
