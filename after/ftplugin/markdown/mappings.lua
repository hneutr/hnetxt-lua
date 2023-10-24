local args = {silent = true, buffer = true}

require("htn.text.list").map_toggles(vim.g.mapleader .. "t")
require("htn.ui.opener").map()

-- header jumping
local Fold = require("htn.ui.fold")
vim.keymap.set("n", "<c-p>", function() Fold.jump_to_header(-1) end, args)
vim.keymap.set("n", "<c-n>", function() Fold.jump_to_header(1) end, args)

if vim.b.hnetxt_project_root then
    local Scratch = require("htn.project.scratch")
    local Fuzzy = require("htn.ui.fuzzy")

    -- fuzzy
    vim.keymap.set("n", " df", Fuzzy.goto, args)
    vim.keymap.set("n", "<c-/>", Fuzzy.put, args)
    vim.keymap.set("i", "<c-/>", Fuzzy.insert, args)

    -- scratch
    vim.keymap.set("n", " s", function() Scratch('n') end, args)
    vim.keymap.set("v", " s", [[:'<,'>lua require('htn.project.scratch')('v')<cr>]], args)

end
