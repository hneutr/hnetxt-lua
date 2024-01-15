local List = require("htn.text.list")

local args = {silent = true}

-- remove list characters when joining lines
vim.keymap.set("n", "J", List.join, args)

-- continue lists
vim.keymap.set("i", "<cr>", List.continue, args)
vim.keymap.set("n", "o", List.continue_cmd, args)
