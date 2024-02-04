local BufferLines = require("hn.buffer_lines")
local Path = require("hn.path")

local Location = require("htl.text.location")
local Link = require("htl.text.link")

function Location.goto(open_command, str)
    if not str then
        local current_line = BufferLines.cursor.get()
        local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
        str = Link.get_nearest(current_line, cursor_col).location
    end

    local project = vim.b.htn_project or {}
    local location = Location.from_str(str, {relative_to = project.path})

    if location.path ~= tostring(Path.this()) then
        Path.open(location.path, open_command)
    end

    if #location.label > 0 then
        local line = Link.find_label(label, BufferLines.get())

        if line then
            vim.api.nvim_win_set_cursor(0, {line, 0})
            vim.cmd("normal zz")
        end
    end
end

return Location
