local Header = require("htl.text.header")

local M = {}
M.headers = Header.headers()

function M.get_header_indexes(lines)
    local header_indexes = List()
    for i, line in ipairs(lines) do
        for header in M.headers:iter() do
            if header:str_is_middle(line) then
                header_indexes:append(i)
            end
        end
    end

    return header_indexes
end

return M
