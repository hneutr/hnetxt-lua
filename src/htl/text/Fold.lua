local Header = require("htl.text.header")
local Divider = require("htl.text.divider")
local Line = require("htl.text.Line")
local Item = require("htl.text.List.Item")
local TextList = require("htl.text.List")

local M = {}
M.headers = Header.headers()
M.dividers = Divider.dividers()
M.barriers = List.from(M.headers, M.dividers)
M.text_foldlevel = math.max(unpack(M.barriers:col('fold_level'))) + 1

function M.get_fold_levels(lines)
    return List(lines):map(M.get_fold_level)
end

function M.get_fold_level(str)
    for barrier in M.barriers:iter() do
        if barrier:str_is_a(str) then
            return string.format(">%d", barrier.fold_level)
        end
    end
    
    local line = TextList:parse_line(str)
    
    local fold_level = Line.get_indent_level(str) + M.text_foldlevel
    
    if line:is_a(Item) then
        return string.format(">%d", fold_level)
    end

    return fold_level
end

function M.get_lower_distance()
    local l = vim.fn.getline('.')
    for header in M.headers:iter() do
        local lines_from_lower = header:lines_from_lower(l)
        if lines_from_lower then
            return lines_from_lower
        end
    end
end

function M.get_header_indexes(lines)
    local header_indexes = List()
    for i, line in ipairs(lines) do
        local add = false
        for header in M.headers:iter() do
            if not add and header:str_is_middle(line) then
                add = true
            end
        end
        
        add = add or line == "---"
        add = add or line:startswith("# ")
        add = add or line:startswith("## ")
        add = add or line:startswith("### ")
        add = add or line:startswith("#### ")
        add = add or line:startswith("##### ")
        add = add or line:startswith("###### ")
        add = add or line:startswith("####### ")
        
        if add then
            header_indexes:append(i)
        end
    end

    return header_indexes
end

return M
