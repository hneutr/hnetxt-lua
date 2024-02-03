local List = require("hl.List")
local db = require("htl.db")
local mirrors = db.get()['mirrors']

local M = {}

function M.get_statusline_path_string(path, project_root)
    if mirrors:is_mirror(path) then
        local mirror = mirrors:get_mirror(path)
        path = mirrors:get_source(path).path
        path = path:with_name(path:name() .. ": " .. mirrors.get_kind_string(mirror))
    end

    if path:is_relative_to(project_root) then
        path = path:relative_to(project_root)
    end

    return tostring(path)
end

function M.statusline(path, project_root)
    local statusline = M.get_statusline_path_string(path, project_root)
    local mirrors_string = mirrors:get_mirrors_string(path)

    if #mirrors_string > 0 then 
        statusline = statusline .. "%=mirrors: " .. mirrors_string
    end
    
    return statusline
end

function M.spellfile(root)
    local spellfile = root:join(".spell", "en.utf-8.add")
    spellfile:parent():mkdir()
    return tostring(spellfile)
end

return M
