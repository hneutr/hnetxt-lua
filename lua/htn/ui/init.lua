local List = require("hl.List")
local db = require("htl.db")

local M = {}

function M.statusline(current_file, project_root)
    local file = current_file
    if file:is_relative_to(project_root) then
        file = file:relative_to(project_root)
    end

    local statusline = tostring(file)
    
    local mirrors = db.get()['mirrors']

    if mirrors:is_source(current_file) then
        local file_mirrors = mirrors:get_mirrors(current_file)
        local config = mirrors.configs.generic
        local mirror_strs = file_mirrors:filter(function(mirror)
            return not config[mirror.kind].exclude_from_statusline
        end):transform(function(mirror)
            return mirror.kind
        end)
        
        if #mirror_strs > 0 then
            local mirrors_str = "mirrors: " .. mirror_strs:join(" | ")

            statusline = statusline .. "%=" .. mirrors_str
        end
    end
    
    return statusline
end

return M
