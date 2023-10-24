local List = require("hl.List")
local Dict = require("hl.Dict")
local class = require("pl.class")

local Header = require("htl.text.neoheader")
local Divider = require("htl.text.divider")
local TextList = require("htl.text.list")

class.Parser()

function Parser:_init()
    self.headers = Header.headers()
    self.dividers = Divider.dividers()
    self.barriers = List.from(self.headers, self.dividers)
    self.text_fold_level = math.max(unpack(self.barriers:map(function(b) return b.fold_level end))) + 1
end

function Parser:get_fold_levels(lines)
    local levels = List(lines):map(function(l) return self:get_fold_level(l) end)
    levels = self:adjust_metadata_frontmatter(lines, levels)
    return self:adjust_blank_line_fold_levels(lines, levels)
end

function Parser:get_fold_level(str)
    for barrier in self.barriers:iter() do
        if barrier:str_is_a(str) then
            return barrier.fold_level
        end
    end

    return TextList.Line.get_if_str_is_a(str):indent_level() + self.text_fold_level
end

function Parser:adjust_metadata_frontmatter(lines, levels)
    local metadata_divider = Divider.metadata_divider()
    local frontmatter_i

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
function Parser:adjust_blank_line_fold_levels(lines, levels)
    for i, line in ipairs(lines) do
        if #line == 0 then
            if i < #lines then
                levels[i] = levels[i + 1]
            elseif i > 1 then
                levels[i] = levels[i - 1]
            end
        end
    end

    return levels
end

function Parser:get_header_indexes(lines)
    local header_indexes = List()
    for i, line in ipairs(lines) do
        for header in self.headers:iter() do
            if header:str_is_middle(line) then
                header_indexes:append(i)
            end
        end
    end

    return header_indexes
end

return Parser
