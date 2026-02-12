----------------------------------------------------------------------------------
-- File:          treesitter.lua
-- Created:       Saturday, 24 January 2026 - 08:36 AM
-- Author:        AhmdHosni (ahmdhosny@gmail.com)
-- Description:   A treesitter attempt using lazyvim configurations
----------------------------------------------------------------------------------

return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		version = false,
		lazy = true,
		event = "VeryLazy",

		-- Use a function for build that handles first-time installation
		build = function()
			local install_dir = vim.fn.stdpath("data") .. "/lazy/nvim-treesitter"
			if vim.fn.isdirectory(install_dir .. "/parser") == 0 then
				-- First install - skip TSUpdate, will be handled in config
				return
			end
			-- Don't auto-update on every sync
		end,

		opts = {
			highlight = { enable = true },
			indent = { enable = true },
			auto_install = true,

			ensure_installed = {
				"rust",
				"zig",
				"bash",
				"c",
				"diff",
				"html",
				"java",
				"javascript",
				"jsdoc",
				"json",
				"jsonc",
				"lua",
				"luadoc",
				"luap",
				"markdown",
				"markdown_inline",
				"printf",
				"python",
				"query",
				"regex",
				"toml",
				"tsx",
				"typescript",
				"vim",
				"vimdoc",
				"xml",
				"yaml",
			},

			-- Text objects configuration
			textobjects = {
				select = {
					enable = true,
					lookahead = true,
					keymaps = {
						["af"] = "@function.outer",
						["if"] = "@function.inner",
						["ac"] = "@class.outer",
						["ic"] = "@class.inner",
						["aa"] = "@parameter.outer",
						["ia"] = "@parameter.inner",
						["ab"] = "@block.outer",
						["ib"] = "@block.inner",
					},
				},
				move = {
					enable = true,
					set_jumps = true,
					goto_next_start = {
						["]f"] = "@function.outer",
						["]c"] = "@class.outer",
						["]a"] = "@parameter.inner",
					},
					goto_next_end = {
						["]F"] = "@function.outer",
						["]C"] = "@class.outer",
						["]A"] = "@parameter.inner",
					},
					goto_previous_start = {
						["[f"] = "@function.outer",
						["[c"] = "@class.outer",
						["[a"] = "@parameter.inner",
					},
					goto_previous_end = {
						["[F"] = "@function.outer",
						["[C"] = "@class.outer",
						["[A"] = "@parameter.inner",
					},
				},
				swap = {
					enable = true,
					swap_next = {
						["<leader>sp"] = "@parameter.inner",
					},
					swap_previous = {
						["<leader>sP"] = "@parameter.inner",
					},
				},
			},
		},

		config = function(_, opts)
			-- Setup treesitter with options first
			require("nvim-treesitter").setup(opts)

			-- Path to store the hash of ensure_installed list
			local cache_file = vim.fn.stdpath("cache") .. "/treesitter_ensure_installed.txt"

			-- Create a sorted string representation of ensure_installed
			local current_list = vim.tbl_map(function(lang)
				return lang
			end, opts.ensure_installed or {})
			table.sort(current_list)
			local current_hash = table.concat(current_list, ",")

			-- Check if cache file exists
			local cache_exists = vim.fn.filereadable(cache_file) == 1

			-- Read previous hash if file exists
			local previous_hash = ""
			if cache_exists then
				local file = io.open(cache_file, "r")
				if file then
					previous_hash = file:read("*all")
					file:close()
				end
			end

			-- Determine if we need to run install
			local should_install = false
			local install_reason = ""

			if not cache_exists then
				should_install = true
				install_reason = "First time setup"
			elseif current_hash ~= previous_hash then
				should_install = true
				install_reason = "Language list changed"
			end

			-- Only run install if needed
			if should_install then
				vim.defer_fn(function()
					pcall(function()
						local TS = require("nvim-treesitter")
						vim.notify("Treesitter: " .. install_reason .. ", installing parsers...", vim.log.levels.INFO)
						TS.install(opts.ensure_installed, { summary = true })

						-- Save current hash to cache file after successful install
						local f = io.open(cache_file, "w")
						if f then
							f:write(current_hash)
							f:close()
						end
					end)
				end, 100)
			end
		end,
	},

	-- Treesitter text objects plugin
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		lazy = true,
		event = "VeryLazy",
	},
}
