local Header = require("htl.text.header")
local Divider = require("htl.text.divider")
local Line = require("htl.text.Line")
local metadata_divider = Divider.metadata_divider()

local M = {}
M.headers = Header.headers()
M.dividers = Divider.dividers()
M.barriers = List.from(M.headers, M.dividers)
M.text_foldlevel = math.max(unpack(M.barriers:col('fold_level'))) + 1

function M.get_fold_levels(lines)
    local levels = List(lines):map(M.get_fold_level)
    levels = M.adjust_metadata_frontmatter(lines, levels)
    return M.adjust_blank_line_fold_levels(lines, levels)
end

function M.get_fold_level(str)
    for barrier in M.barriers:iter() do
        if barrier:str_is_a(str) then
            return barrier.fold_level
        end
    end

    return Line.get_indent_level(str) + M.text_foldlevel
end

function M.adjust_metadata_frontmatter(lines, levels)
    for i, line in ipairs(lines) do
        if metadata_divider:str_is_a(line) then
            for j = 1, i do
                levels[j] = metadata_divider.fold_level
            end

            break
        end
    end

    return levels
end

-- blank lines get the fold level of the subsequent element
function M.adjust_blank_line_fold_levels(lines, levels)
    for i, line in ipairs(lines) do
        if #line:strip() == 0 then
            -- levels[i] = -1
            if i < #lines then
                levels[i] = levels[i + 1]
            elseif i > 1 then
                levels[i] = levels[i - 1]
            end
        end
    end

    return levels
end

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
