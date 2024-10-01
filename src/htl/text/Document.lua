local Heading = require("htl.text.Heading")

local M = class()

function M:_init(path)
    self.path = path
    self.lines = self:set_lines()
    self.wordcount = self.lines:map(function(l) return #l:split(" ") end):reduce("+")
end

function M:set_lines()
    local add_newline = false

    local lines = List()
    for line in self:filter_lines(self.path:readlines()):iter() do
        if add_newline and #line:strip() > 0 then
            lines:append("")
        end
        
        add_newline = Heading.str_is_a(line) or line == "---"
        
        if #lines > 0 and add_newline and #lines[#lines]:strip() > 0 then
            lines:append("")
        end
        
        lines:append(line)
    end
    
    return M:remove_consecutive_newlines(lines)
end

function M:remove_consecutive_newlines(lines)
    local _lines = List()
    for i, line in ipairs(lines) do
        local add_line = true

        if i > 1 and #line:strip() == 0 and #lines[i - 1]:strip() == 0 then
            add_line = false
        end
        
        if add_line then
            _lines:append(line)
        end
    end
    
    return _lines
end

function M:filter_lines(lines)
    local exclude
    local level = 1

    local _lines = List()
    for line in lines:iter() do
        if line == Conf.text.end_document then
            return _lines
        end
        
        if Heading.str_is_a(line) then
            local heading = Heading.from_str(line)
            level = heading.level
            
            if heading:exclude_from_document() then
                if not exclude or exclude > level then
                    exclude = level
                end
            elseif exclude and exclude == level then
                exclude = nil
            end
            
            heading.str = heading.text
            line = tostring(heading)
        end

        if not exclude or exclude and exclude > level then
            _lines:append(line)
        end
    end

    return _lines
end

function M:wordcount()
    local count = 0
end

return M
