----------------------------------------------------------------------------------
-- File:          autocmds.lua
-- Created:       Saturday, 24 January 2026 - 07:41 AM
-- Author:        AhmdHosni (ahmdhosny@gmail.com)
-- Link:
-- Description:  Auto Commands for neovim - automatically run command upon startup
----------------------------------------------------------------------------------

-- ##################################################
-- Restore last cursor position when reopening a file
-- ##################################################
--
local last_cursor_group = vim.api.nvim_create_augroup("LastCursorGroup", {})
vim.api.nvim_create_autocmd("BufReadPost", {
	group = last_cursor_group,
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		local lcount = vim.api.nvim_buf_line_count(0)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- ###################################
-- Highlight the yanked text for 500ms
-- ###################################
--
local highlight_yank_group = vim.api.nvim_create_augroup("HighlightYank", {})
vim.api.nvim_create_autocmd("TextYankPost", {
	group = highlight_yank_group,
	pattern = "*",
	callback = function()
		vim.hl.on_yank({
			higroup = "IncSearch",
			timeout = 500,
		})
	end,
})

-- ##########################################################
-- Auto create a template header for each file opened by nvim
-- ##########################################################
--
local template_group = vim.api.nvim_create_augroup("UserTemplates", { clear = true })

vim.api.nvim_create_autocmd({ "BufNewFile", "BufReadPost" }, {
	group = template_group,
	pattern = "*",
	callback = function()
		-- 1. Safety check: only proceed if the buffer is truly empty
		if vim.bo.buftype ~= "" or vim.fn.line("$") > 1 or vim.fn.getline(1) ~= "" then
			return
		end

		-- 2. Force Neovim to recognize file type to populate 'commentstring'
		vim.cmd("filetype detect")

		local template_dir = vim.fn.expand("~/.config/nvim/lua/templates/")

		local ext = vim.fn.expand("%:e")
		local global_path = template_dir .. "global.txt"
		local lang_path = template_dir .. ext .. ".txt"

		-- 3. Insert Language Specific Template (Shebangs go to line 1)
		if vim.fn.filereadable(lang_path) == 1 then
			vim.cmd("0r " .. lang_path)
		end

		-- 4. Insert Global Header
		-- If line 1 is a shebang (#!), insert global template at line 2
		if vim.fn.filereadable(global_path) == 1 then
			local insert_line = (vim.fn.getline(1):find("^#!")) and 1 or 0
			vim.cmd(insert_line .. "r " .. global_path)
		end

		-- 5. Prepare Placeholders
		local custom_date = os.date("%A, %d %B %Y - %I:%M %p")
		local filename = vim.fn.expand("%:t")
		local filename_no_ext = vim.fn.expand("%:t:r") -- For Java Class Names

		-- Extract comment prefix (e.g., "//", "#", or "--")
		local cs = vim.bo.commentstring
		local comment_prefix = "#" -- Default fallback
		if cs and cs:find("%%s") then
			comment_prefix = cs:gsub("%%s", ""):gsub("%s+$", "")
		end

		-- 6. SILENT Placeholder Replacements
		pcall(function()
			-- Replace universal comment prefix
			vim.cmd("silent! %s/%CS%/" .. vim.fn.escape(comment_prefix, "/") .. "/ge")
			-- Replace Date and Filenames
			vim.cmd("silent! %s/%DATE%/" .. custom_date .. "/ge")
			vim.cmd("silent! %s/%FILENAME%/" .. filename .. "/ge")
			vim.cmd("silent! %s/%FILENAME_NO_EXT%/" .. filename_no_ext .. "/ge")
		end)

		-- 7. Final Cleanup: Position cursor at the end
		vim.cmd("normal! G")
	end,
})

-- ###########################################################################
-- Auto update oil and fzf-lua if installed with the current working directory
-- ###########################################################################
--

vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
	pattern = "*",
	callback = function()
		-- 1. Ignore "special" buffers (like lazy, mason, or float windows)
		-- This prevents the crash when lazy.nvim is trying to install plugins
		if vim.bo.buftype ~= "" or vim.bo.filetype == "lazy" then
			return
		end

		-- 2. Check if oil is installed and fully initialized
		-- Checking for 'adapters' ensures the plugin is ready to be queried
		local has_oil, oil = pcall(require, "oil")
		if not (has_oil and oil.get_current_dir) then
			return
		end

		-- 3. Safely attempt to get the directory
		local success, current_dir = pcall(oil.get_current_dir)

		-- If we are in an Oil buffer, sync to Oil's directory
		if success and current_dir then
			vim.cmd("cd " .. vim.fn.fnameescape(current_dir))
		-- If we are in a normal file, sync to that file's folder
		elseif vim.fn.expand("%:p:h") ~= "" then
			pcall(function()
				vim.cmd("cd " .. vim.fn.fnameescape(vim.fn.expand("%:p:h")))
			end)
		end
	end,
	desc = "Sync CWD to current file or Oil directory safely",
})
