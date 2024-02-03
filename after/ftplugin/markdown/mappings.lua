local args = {silent = true, buffer = true}

require("htn.text.list").map_toggles(vim.g.mapleader .. "t")

-- header jumping
local Fold = require("htn.ui.fold")
vim.keymap.set("n", "<c-p>", function() Fold.jump_to_header(-1) end, args)
vim.keymap.set("n", "<c-n>", function() Fold.jump_to_header(1) end, args)

if vim.b.htn_project then
    local Scratch = require("htn.project.scratch")
    local Fuzzy = require("htn.ui.fuzzy")
    local Location = require("htn.text.location")

    -- fuzzy
    vim.keymap.set("n", " df", Fuzzy.goto, args)
    vim.keymap.set("n", "<c-/>", Fuzzy.put, args)
    vim.keymap.set("i", "<c-/>", Fuzzy.insert, args)

    -- scratch
    vim.keymap.set("n", " s", function() Scratch('n') end, args)
    vim.keymap.set("v", " s", [[:'<,'>lua require('htn.project.scratch')('v')<cr>]], args)

    -- locations
    Dict({
        ["<M-l>"] = "vsplit",
        ["<M-j>"] = "split",
        ["<M-e>"] = "edit",
        ["<M-t>"] = "tabedit",
    }):foreach(function(lhs, open_cmd)
        vim.keymap.set("n", lhs, function() Location.goto(open_cmd) end, args)
    end)

    -- mirrors
    require("htn.ui.mirror")():foreach(function(lhs, rhs)
        vim.keymap.set("n", lhs, rhs, args)
    end)
end
