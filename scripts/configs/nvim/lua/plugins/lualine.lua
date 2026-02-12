----------------------------------------------------------------------------------
-- File:          lualine.lua
-- Created:       Saturday, 24 January 2026 - 08:06 AM
-- Author:        AhmdHosni (ahmdhosny@gmail.com)
-- Link:          https://github.com/nvim-lualine/lualine.nvim   
-- Description:   A blazing fast and easy to configure Neovim statusline written in Lua.
----------------------------------------------------------------------------------

return {
    "nvim-lualine/lualine.nvim",
    version = "*",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
        theme = "catppuccin",
        icons_enabled = true,
        section_separators = { left = "", right = "" },
        component_separators = "|",
    }
}

