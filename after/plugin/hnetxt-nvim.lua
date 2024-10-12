local ui = require("htn.ui")

local args = {silent = true, buffer = true}

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

vim.api.nvim_create_autocmd({"TermOpen"}, {pattern = "term://*", callback = map_terminal_openers})
