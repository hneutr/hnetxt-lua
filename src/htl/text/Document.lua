local Header = require("htl.text.Header")

local M = class()

function M:_init(path)
    self.path = path
    self.lines = self:set_lines()
    self.wordcount = self.lines:map(function(l) return #l end):reduce("+")
end

function M:set_lines()
    local add_newline = false

    local lines = List()
    for line in self:filter_lines(self.path:readlines()):iter() do
        if add_newline and #line:strip() > 0 then
            lines:append("")
        end
        
        add_newline = Header.str_is_a(line) or line == "---"
        
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
        
        if Header.str_is_a(line) then
            local header = Header.from_str(line)
            level = header.level
            
            if header:exclude_from_document() then
                if not exclude or exclude > level then
                    exclude = level
                end
            elseif exclude and exclude == level then
                exclude = nil
            end
            
            header.str = header.text
            line = tostring(header)
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
