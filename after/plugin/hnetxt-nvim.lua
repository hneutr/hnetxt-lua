local List = require("htn.text.list")
local ui = require("htn.ui")

local args = {silent = true}

-- remove list characters when joining lines
vim.keymap.set("n", "J", List.join, args)

-- continue lists
vim.keymap.set("i", "<cr>", List.continue, args)
vim.keymap.set("n", "o", List.continue_cmd, args)

args = {silent = true, buffer = true}

local function map_terminal_openers()
    Dict({
        ["<M-l>"] = "vsplit",
        ["<M-j>"] = "split",
        ["<M-e>"] = "edit",
        ["<M-t>"] = "tabedit",
    }):foreach(function(rhs, opener)
        vim.keymap.set("n", rhs, ui.goto_map_fn(opener), args)
    end)
end

vim.api.nvim_create_autocmd({"TermOpen"}, {pattern="term://*", callback=map_terminal_openers})
