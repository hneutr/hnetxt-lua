local fzf = require("fzf-lua")
local ui = require("htn.ui")

local M = {}

M.operation_actions = {
    goto = {
        default = ui.fuzzy_goto_map_fn("edit"),
        ["ctrl-j"] = ui.fuzzy_goto_map_fn("split"),
        ["ctrl-l"] = ui.fuzzy_goto_map_fn("vsplit"),
        ["ctrl-t"] = ui.fuzzy_goto_map_fn("tabedit"),
    },
    put = {default = ui.fuzzy_put},
    insert = {default = ui.fuzzy_insert},
}

function M.goto()
    M._do("goto")
end

function M.put()
    M._do("put")
end
function M.insert()
    M._do("insert")
end

function M._do(operation)
    local dir = Path.this():parent()

    if vim.b.htn_project then
        dir = vim.b.htn_project.path
    end

    fzf.fzf_exec(DB.urls:get_fuzzy_paths(dir), {actions = M.operation_actions[operation]})
end

-- function M.fuzzy_map(operation, from_root)
-- end

return M
