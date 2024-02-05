local Path = require("hl.Path")

local db = require("htl.db")

local BufferLines = require("hn.buffer_lines")

local ui = require("htn.ui")

local fuzzy_actions = {
    ["default"] = "edit",
    ["ctrl-j"] = "split",
    ["ctrl-l"] = "vsplit",
    ["ctrl-t"] = "tabedit",
}

M = {sink = {}}

function M._do(fn)
    local actions = {}
    for key, action in pairs(fuzzy_actions) do
        actions[key] = function(selected) fn(selected[1], action) end
    end

    local dir = Path.this():parent()

    if vim.b.htn_project then
        dir = vim.b.htn_project.path
    end

    require('fzf-lua').fzf_exec(db.get().urls:get_fuzzy_paths(dir), {actions = actions})
end

function M.goto()
    M._do(function(path, action) ui.goto(action, path) end)
end

function M.put()
    M._do(function(path)
        vim.api.nvim_put({ui.get_reference(path)} , 'c', 1, 0)
    end)
end

function M.insert()
    M._do(M.insert_selection)
end

function M.insert_selection(path)
    local line = BufferLines.cursor.get()
    local line_number, column = unpack(vim.api.nvim_win_get_cursor(0))

    local insert_command = 'i'

    if column == #line - 1 then
        column = column + 1
        insert_command = 'a'
    elseif column == 0 then
        insert_command = 'a'
    end

    local content = ui.get_reference(path)

    local new_line = line:sub(1, column) .. content .. line:sub(column + 1)
    local new_column = column + #content

    BufferLines.cursor.set({replacement = {new_line}})

    vim.api.nvim_win_set_cursor(0, {line_number, new_column})
    vim.api.nvim_input(insert_command)
end

return M
