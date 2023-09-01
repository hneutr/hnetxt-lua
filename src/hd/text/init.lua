local List = require("hl.List")

local M = {}

function M.components_to_lines(components)
    local lines = List()
    local add_to = nil
    components:foreach(function(component)
        if type(component) == "function" then
            if add_to == nil then
                add_to = lines:pop() or ""
            end

            add_to = add_to .. tostring(component())
        elseif type(component) == "string" and component:startswith("INPUT:") then
            if add_to == nil then
                add_to = lines:pop() or ""
            end

            add_to = add_to .. component:removeprefix("INPUT:")
        else
            if add_to ~= nil then
                component = add_to .. component
            end

            lines:append(component)

            add_to = nil
        end
    end)

    return lines
end

return M
